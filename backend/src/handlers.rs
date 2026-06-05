use crate::db::{self, DbPool};
use crate::inference::SharedModelEngine;
use actix_multipart::Multipart;
use actix_web::{delete, get, post, web, HttpResponse, Responder};
use futures_util::TryStreamExt;
use std::io::Write;
use std::time::Instant;
use uuid::Uuid;

pub struct AppState {
    pub startup_time: Instant,
}

#[derive(serde::Deserialize)]
pub struct HistoryQuery {
    pub search: Option<String>,
    pub page: Option<i64>,
    pub limit: Option<i64>,
}

#[derive(serde::Deserialize)]
pub struct ManualPredictionRequest {
    pub sepal_length: f32,
    pub sepal_width: f32,
    pub petal_length: f32,
    pub petal_width: f32,
}

#[post("/predict/vision")]
pub async fn predict_vision_handler(
    mut payload: Multipart,
    engine: web::Data<SharedModelEngine>,
    pool: web::Data<DbPool>,
) -> impl Responder {
    let mut image_bytes = Vec::new();
    let file_id = Uuid::new_v4().to_string();
    let mut filename = format!("{}.jpg", file_id);

    // Iterate over multipart stream
    while let Ok(Some(mut field)) = payload.try_next().await {
        let content_disposition = field.content_disposition();
        
        if let Some(cd) = content_disposition {
            if let Some(name) = cd.get_name() {
                if name == "image" {
                    if let Some(original_filename) = cd.get_filename() {
                        let ext = std::path::Path::new(original_filename)
                            .extension()
                            .and_then(std::ffi::OsStr::to_str)
                            .unwrap_or("jpg");
                        filename = format!("{}.{}", file_id, ext);
                    }

                while let Ok(Some(chunk)) = field.try_next().await {
                    image_bytes.extend_from_slice(&chunk);
                }
                }
            }
        }
    }

    if image_bytes.is_empty() {
        return HttpResponse::BadRequest().json(serde_json::json!({ "error": "No image provided in 'image' field" }));
    }

    // Ensure uploads directory exists
    let _ = std::fs::create_dir_all("./uploads");
    let filepath = format!("./uploads/{}", filename);
    
    let mut f = match std::fs::File::create(&filepath) {
        Ok(file) => file,
        Err(e) => {
            log::error!("Failed to create file on disk: {:?}", e);
            return HttpResponse::InternalServerError().json(serde_json::json!({ "error": "Failed to save image" }));
        }
    };
    if let Err(e) = f.write_all(&image_bytes) {
        log::error!("Failed to write image data: {:?}", e);
        return HttpResponse::InternalServerError().json(serde_json::json!({ "error": "Failed to write image" }));
    }

    let image_url = format!("/uploads/{}", filename);

    match engine.predict_image(&image_bytes, &image_url) {
        Ok(prediction) => {
            let bboxes_json = serde_json::to_value(&prediction.bounding_boxes).unwrap_or(serde_json::json!([]));
            match db::save_prediction(&pool, Some(image_url.clone()), None, None, None, None, &prediction, bboxes_json).await {
                Ok(record) => {
                    HttpResponse::Ok().json(serde_json::json!({
                        "id": record.id,
                        "image_url": record.image_url,
                        "species": prediction.species,
                        "confidence": prediction.confidence,
                        "probabilities": prediction.probabilities,
                        "bounding_boxes": prediction.bounding_boxes,
                        "scientific_name": prediction.scientific_name,
                        "botanical_family": prediction.botanical_family,
                        "native_habitat": prediction.native_habitat,
                        "flowering_season": prediction.flowering_season,
                        "characteristics": prediction.characteristics,
                        "detailed_description": prediction.detailed_description,
                        "species_key": prediction.species_key,
                        "created_at": record.created_at
                    }))
                }
                Err(e) => {
                    log::error!("Database error saving prediction: {:?}", e);
                    // Return prediction anyway even if DB save fails
                    HttpResponse::Ok().json(serde_json::json!({
                        "id": null,
                        "image_url": image_url,
                        "species": prediction.species,
                        "confidence": prediction.confidence,
                        "probabilities": prediction.probabilities,
                        "bounding_boxes": prediction.bounding_boxes,
                        "scientific_name": prediction.scientific_name,
                        "botanical_family": prediction.botanical_family,
                        "native_habitat": prediction.native_habitat,
                        "flowering_season": prediction.flowering_season,
                        "characteristics": prediction.characteristics,
                        "detailed_description": prediction.detailed_description,
                        "species_key": prediction.species_key,
                        "created_at": chrono::Utc::now()
                    }))
                }
            }
        }
        Err(e) => {
            log::error!("Inference error: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({ "error": "Model execution failed" }))
        }
    }
}

#[post("/predict/manual")]
pub async fn predict_manual_handler(
    payload: web::Json<ManualPredictionRequest>,
    engine: web::Data<SharedModelEngine>,
    pool: web::Data<DbPool>,
) -> impl Responder {
    let prediction = engine.predict_manual(
        payload.sepal_length,
        payload.sepal_width,
        payload.petal_length,
        payload.petal_width,
    );

    let bboxes_json = serde_json::json!([]);

    match db::save_prediction(
        &pool,
        None,
        Some(payload.sepal_length),
        Some(payload.sepal_width),
        Some(payload.petal_length),
        Some(payload.petal_width),
        &prediction,
        bboxes_json,
    ).await {
        Ok(record) => {
            HttpResponse::Ok().json(serde_json::json!({
                "id": record.id,
                "image_url": record.image_url,
                "species": prediction.species,
                "confidence": prediction.confidence,
                "probabilities": prediction.probabilities,
                "bounding_boxes": prediction.bounding_boxes,
                "scientific_name": prediction.scientific_name,
                "botanical_family": prediction.botanical_family,
                "native_habitat": prediction.native_habitat,
                "flowering_season": prediction.flowering_season,
                "characteristics": prediction.characteristics,
                "detailed_description": prediction.detailed_description,
                "species_key": prediction.species_key,
                "created_at": record.created_at
            }))
        }
        Err(e) => {
            log::error!("Database error saving manual prediction: {:?}", e);
            // Return prediction anyway even if DB save fails
            HttpResponse::Ok().json(serde_json::json!({
                "id": null,
                "image_url": null,
                "species": prediction.species,
                "confidence": prediction.confidence,
                "probabilities": prediction.probabilities,
                "bounding_boxes": prediction.bounding_boxes,
                "scientific_name": prediction.scientific_name,
                "botanical_family": prediction.botanical_family,
                "native_habitat": prediction.native_habitat,
                "flowering_season": prediction.flowering_season,
                "characteristics": prediction.characteristics,
                "detailed_description": prediction.detailed_description,
                "species_key": prediction.species_key,
                "created_at": chrono::Utc::now()
            }))
        }
    }
}

#[get("/history")]
pub async fn get_history_handler(
    query: web::Query<HistoryQuery>,
    pool: web::Data<DbPool>,
) -> impl Responder {
    let limit = query.limit.unwrap_or(10).max(1).min(100);
    let page = query.page.unwrap_or(1).max(1);
    let offset = (page - 1) * limit;

    let search = query.search.clone().filter(|s| !s.trim().is_empty());

    match db::get_history(&pool, search.clone(), limit, offset).await {
        Ok(records) => {
            let total = db::get_total_history_count(&pool, search).await.unwrap_or(0);
            HttpResponse::Ok().json(serde_json::json!({
                "data": records,
                "total": total,
                "page": page,
                "limit": limit,
            }))
        }
        Err(e) => {
            log::error!("Database error fetching history: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({ "error": "Internal database error" }))
        }
    }
}

#[delete("/history/{id}")]
pub async fn delete_prediction_handler(
    id: web::Path<i32>,
    pool: web::Data<DbPool>,
) -> impl Responder {
    match db::delete_prediction(&pool, *id).await {
        Ok(deleted) => {
            if deleted {
                HttpResponse::Ok().json(serde_json::json!({ "message": "Prediction deleted successfully" }))
            } else {
                HttpResponse::NotFound().json(serde_json::json!({ "error": "Prediction not found" }))
            }
        }
        Err(e) => {
            log::error!("Database error deleting prediction {}: {:?}", id, e);
            HttpResponse::InternalServerError().json(serde_json::json!({ "error": "Internal database error" }))
        }
    }
}

#[delete("/history")]
pub async fn clear_history_handler(
    pool: web::Data<DbPool>,
) -> impl Responder {
    match db::clear_history(&pool).await {
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({ "message": "Prediction history cleared successfully" })),
        Err(e) => {
            log::error!("Database error clearing history: {:?}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({ "error": "Internal database error" }))
        }
    }
}

#[get("/metrics")]
pub async fn get_metrics_handler(
    pool: web::Data<DbPool>,
    engine: web::Data<SharedModelEngine>,
) -> impl Responder {
    let total_predictions = match db::get_total_history_count(&pool, None).await {
        Ok(c) => c,
        Err(e) => {
            log::error!("Database error counting predictions: {:?}", e);
            0
        }
    };

    let species_distribution = db::get_species_distribution(&pool).await.unwrap_or_default();
    let average_confidence = db::get_average_confidence(&pool).await.unwrap_or(0.0);

    let summary = crate::model::MetricsSummary {
        total_predictions,
        species_distribution,
        average_confidence,
        dataset_info: engine.metadata.dataset_info.clone(),
        metrics: engine.metadata.metrics.clone(),
    };

    HttpResponse::Ok().json(summary)
}

#[get("/health")]
pub async fn get_health_handler(
    pool: web::Data<DbPool>,
    state: web::Data<AppState>,
) -> impl Responder {
    let db_status = match sqlx::query("SELECT 1").execute(&**pool).await {
        Ok(_) => "connected".to_string(),
        Err(_) => "disconnected".to_string(),
    };

    let uptime = state.startup_time.elapsed().as_secs();

    let health = crate::model::HealthStatus {
        status: if db_status == "connected" { "ok".to_string() } else { "degraded".to_string() },
        database: db_status,
        model_loaded: true,
        uptime_seconds: uptime,
    };

    HttpResponse::Ok().json(health)
}
