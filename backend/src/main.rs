use actix_cors::Cors;
use actix_web::{web, App, HttpServer};
use std::sync::Arc;
use std::time::Instant;

mod db;
mod handlers;
mod inference;
mod model;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Load .env file if it exists
    dotenvy::dotenv().ok();

    // Initialize env logger
    env_logger::init_from_env(env_logger::Env::default().default_filter_or("info"));
    
    log::info!("Starting Iris Flower Classification Backend...");

    // Find database URL or use default
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "sqlite://predictions.db?mode=rwc".to_string());

    // Initialize database pool
    let pool = db::init_db(&database_url).await.map_err(|e| {
        log::error!("Failed to initialize database: {:?}", e);
        std::io::Error::new(std::io::ErrorKind::Other, e)
    })?;

    // Load ONNX model and metadata
    let model_path = std::env::var("MODEL_PATH")
        .unwrap_or_else(|_| "resources/model.onnx".to_string());
    let metadata_path = std::env::var("METADATA_PATH")
        .unwrap_or_else(|_| "resources/model_metadata.json".to_string());

    let engine = inference::ModelEngine::new(&model_path, &metadata_path).map_err(|e| {
        log::error!("Failed to load model or metadata: {:?}", e);
        std::io::Error::new(std::io::ErrorKind::Other, e.to_string())
    })?;
    let engine = Arc::new(engine);

    // Track uptime
    let app_state = web::Data::new(handlers::AppState {
        startup_time: Instant::now(),
    });

    let port = std::env::var("PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .unwrap_or(8080);

    // Create the static and uploads folders if they don't exist yet
    if let Err(e) = std::fs::create_dir_all("./static") {
        log::warn!("Could not create ./static directory: {:?}", e);
    }
    if let Err(e) = std::fs::create_dir_all("./uploads") {
        log::warn!("Could not create ./uploads directory: {:?}", e);
    }

    log::info!("Starting HTTP server on 0.0.0.0:{}", port);

    HttpServer::new(move || {
        let cors = Cors::permissive();

        App::new()
            .wrap(cors)
            .app_data(web::Data::new(pool.clone()))
            .app_data(web::Data::new(engine.clone()))
            .app_data(app_state.clone())
            // Register API endpoints under /api
            .service(
                web::scope("/api")
                    .service(handlers::predict_vision_handler)
                    .service(handlers::predict_manual_handler)
                    .service(handlers::get_history_handler)
                    .service(handlers::delete_prediction_handler)
                    .service(handlers::clear_history_handler)
                    .service(handlers::get_metrics_handler)
                    .service(handlers::get_health_handler)
                    // Serve uploaded images statically at /api/uploads
                    .service(
                        actix_files::Files::new("/uploads", "./uploads")
                            .show_files_listing()
                    )
            )
            // Serve static files for Flutter Web (SPA-friendly)
            .service(
                actix_files::Files::new("/", "./static")
                    .index_file("index.html")
                    .default_handler(actix_files::Files::new("/", "./static").index_file("index.html"))
            )
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
}
