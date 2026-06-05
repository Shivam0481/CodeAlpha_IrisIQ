use crate::model::{HistoryRecord, PredictionResponse};
use sqlx::{postgres::PgPoolOptions, Pool, Postgres, FromRow};
use std::collections::HashMap;
use serde_json::Value;


pub type DbPool = Pool<Postgres>;

#[derive(FromRow)]
struct SpeciesCount {
    prediction: String,
    count: i64,
}

pub async fn init_db(database_url: &str) -> Result<DbPool, sqlx::Error> {
    log::info!("Connecting to database at: {}", database_url);
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(database_url)
        .await?;

    log::info!("Running database migrations...");
    sqlx::migrate!("./migrations")
        .run(&pool)
        .await?;

    log::info!("Database initialized successfully.");
    Ok(pool)
}

pub async fn save_prediction(
    pool: &DbPool,
    image_url: Option<String>,
    sl: Option<f32>,
    sw: Option<f32>,
    pl: Option<f32>,
    pw: Option<f32>,
    resp: &PredictionResponse,
    bounding_boxes: Value,
) -> Result<HistoryRecord, sqlx::Error> {
    let mut conn = pool.acquire().await?;
    
    let record = sqlx::query_as::<_, HistoryRecord>(
        "INSERT INTO predictions (image_url, sepal_length, sepal_width, petal_length, petal_width, prediction, confidence, bounding_boxes)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING id, image_url, sepal_length, sepal_width, petal_length, petal_width, prediction, confidence, bounding_boxes, created_at"
    )
    .bind(image_url)
    .bind(sl)
    .bind(sw)
    .bind(pl)
    .bind(pw)
    .bind(&resp.species)
    .bind(resp.confidence as f32) // Changed to f32 to match REAL
    .bind(bounding_boxes)
    .fetch_one(&mut *conn)
    .await?;

    Ok(record)
}

pub async fn get_history(
    pool: &DbPool,
    search: Option<String>,
    limit: i64,
    offset: i64,
) -> Result<Vec<HistoryRecord>, sqlx::Error> {
    let query_str = if search.is_some() {
        "SELECT id, image_url, sepal_length, sepal_width, petal_length, petal_width, prediction, confidence, bounding_boxes, created_at
         FROM predictions
         WHERE prediction ILIKE $1
         ORDER BY id DESC
         LIMIT $2 OFFSET $3"
    } else {
        "SELECT id, image_url, sepal_length, sepal_width, petal_length, petal_width, prediction, confidence, bounding_boxes, created_at
         FROM predictions
         ORDER BY id DESC
         LIMIT $1 OFFSET $2"
    };

    let mut query = sqlx::query_as::<_, HistoryRecord>(query_str);

    if let Some(s) = search {
        let pattern = format!("%{}%", s);
        query = query.bind(pattern).bind(limit).bind(offset);
    } else {
        query = query.bind(limit).bind(offset);
    }

    let records = query.fetch_all(pool).await?;
    Ok(records)
}

pub async fn get_total_history_count(
    pool: &DbPool,
    search: Option<String>,
) -> Result<i64, sqlx::Error> {
    let query_str = if search.is_some() {
        "SELECT COUNT(*) FROM predictions WHERE prediction ILIKE $1"
    } else {
        "SELECT COUNT(*) FROM predictions"
    };

    let mut query = sqlx::query_scalar::<_, i64>(query_str);

    if let Some(s) = search {
        let pattern = format!("%{}%", s);
        query = query.bind(pattern);
    }

    let count = query.fetch_one(pool).await?;
    Ok(count)
}

pub async fn delete_prediction(pool: &DbPool, id: i32) -> Result<bool, sqlx::Error> {
    let result = sqlx::query("DELETE FROM predictions WHERE id = $1")
        .bind(id)
        .execute(pool)
        .await?;
    
    Ok(result.rows_affected() > 0)
}

pub async fn clear_history(pool: &DbPool) -> Result<(), sqlx::Error> {
    sqlx::query("DELETE FROM predictions")
        .execute(pool)
        .await?;
    Ok(())
}

pub async fn get_species_distribution(pool: &DbPool) -> Result<HashMap<String, i64>, sqlx::Error> {
    let rows = sqlx::query_as::<_, SpeciesCount>(
        "SELECT prediction, COUNT(*) as count FROM predictions GROUP BY prediction"
    )
    .fetch_all(pool)
    .await?;

    let mut map = HashMap::new();
    for row in rows {
        map.insert(row.prediction, row.count);
    }
    Ok(map)
}

pub async fn get_average_confidence(pool: &DbPool) -> Result<f64, sqlx::Error> {
    let avg: Option<f64> = sqlx::query_scalar("SELECT AVG(confidence) FROM predictions")
        .fetch_one(pool)
        .await?;
    
    Ok(avg.unwrap_or(0.0))
}
