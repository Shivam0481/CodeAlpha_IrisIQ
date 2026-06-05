use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use serde_json::Value;
use chrono::{DateTime, Utc};

#[derive(Debug, Serialize, Clone)]
pub struct BoundingBox {
    pub label: String,
    pub confidence: f32,
    pub x: f32,
    pub y: f32,
    pub w: f32,
    pub h: f32,
}

#[derive(Debug, Serialize, Clone)]
pub struct ClassProbability {
    pub class_name: String,
    pub probability: f32,
}

#[derive(Debug, Serialize, Clone)]
pub struct PredictionResponse {
    pub species: String,
    pub confidence: f32,
    pub probabilities: Vec<ClassProbability>,
    pub bounding_boxes: Vec<BoundingBox>,
    pub image_url: Option<String>,
    pub scientific_name: String,
    pub characteristics: Vec<String>,
    pub botanical_family: String,
    pub native_habitat: String,
    pub flowering_season: String,
    pub detailed_description: String,
    pub species_key: String, // e.g., "setosa", "versicolor", "virginica"
}

#[derive(Debug, Serialize, FromRow, Clone)]
pub struct HistoryRecord {
    pub id: i32,
    pub image_url: Option<String>,
    pub sepal_length: Option<f32>,
    pub sepal_width: Option<f32>,
    pub petal_length: Option<f32>,
    pub petal_width: Option<f32>,
    pub prediction: String,
    pub confidence: f32,
    pub bounding_boxes: Value,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct DatasetInfo {
    pub dataset_name: String,
    pub dataset_size: i64,
    pub features_count: i64,
    pub features: Vec<String>,
    pub classes_count: i64,
    pub classes: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ModelMetrics {
    pub train_accuracy: f64,
    pub test_accuracy: f64,
    pub precision: f64,
    pub recall: f64,
    pub f1_score: f64,
    pub precision_per_class: Vec<f64>,
    pub recall_per_class: Vec<f64>,
    pub f1_score_per_class: Vec<f64>,
    pub confusion_matrix: Vec<Vec<i64>>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ModelMetadata {
    pub dataset_info: DatasetInfo,
    pub model_info: serde_json::Value,
    pub metrics: ModelMetrics,
}

#[derive(Debug, Serialize, Clone)]
pub struct MetricsSummary {
    pub total_predictions: i64,
    pub species_distribution: std::collections::HashMap<String, i64>,
    pub average_confidence: f64,
    pub dataset_info: DatasetInfo,
    pub metrics: ModelMetrics,
}

#[derive(Debug, Serialize, Clone)]
pub struct HealthStatus {
    pub status: String,
    pub database: String,
    pub model_loaded: bool,
    pub uptime_seconds: u64,
}

impl PredictionResponse {
    pub fn get_scientific_info(
        species: &str,
        confidence: f32,
        probs: Vec<ClassProbability>,
        bboxes: Vec<BoundingBox>,
        img_url: Option<String>,
    ) -> Self {
        let species_lower = species.to_lowercase();
        let (scientific_name, botanical_family, native_habitat, flowering_season, detailed_description, characteristics, key) = match species_lower.as_str() {
            "setosa" => (
                "Iris setosa".to_string(),
                "Iridaceae".to_string(),
                "Coastal regions and extreme subarctic climates of North America and Asia.".to_string(),
                "Late Spring to Early Summer".to_string(),
                "Iris setosa, the Arctic Iris, is highly prized for its cold tolerance. It stands out due to its very small standards (inner petals) which distinguish it from other members of the genus. Its striking blue-purple blooms have detailed venous patterns near the yellow haft.".to_string(),
                vec![
                    "Distinctively short, narrow inner petals (standards).".to_string(),
                    "Thrives in extreme subarctic and coastal climates.".to_string(),
                    "Petals display a deep blue-purple hue with striking yellow base patterns.".to_string(),
                    "High resistance to cold and damp growing conditions.".to_string(),
                ],
                "setosa".to_string(),
            ),
            "versicolor" => (
                "Iris versicolor".to_string(),
                "Iridaceae".to_string(),
                "Wetlands, marshes, and damp meadows in Eastern North America.".to_string(),
                "Early to Mid Summer".to_string(),
                "Known as the Harlequin Blue Flag, this robust iris is native to Eastern North America. It loves wet feet and can even grow in shallow water. It features intricate, multi-colored blooms ranging from light blue to deep purple, often heavily veined with yellow and white signals.".to_string(),
                vec![
                    "Moderate petal and sepal size with balanced floral proportions.".to_string(),
                    "Commonly referred to as the Harlequin Blue Flag.".to_string(),
                    "Thrives in soggy soil conditions, particularly in marshes and wet meadows.".to_string(),
                    "Gently drooping sepals highlighted by bright white and yellow bases.".to_string(),
                ],
                "versicolor".to_string(),
            ),
            _ => (
                "Iris virginica".to_string(),
                "Iridaceae".to_string(),
                "Swamps, marshes, and rich damp forest soils of the Southeastern US.".to_string(),
                "Mid to Late Summer".to_string(),
                "The Southern Blue Flag, Iris virginica, forms large elegant clumps in wetlands. Its impressive, wide falls (outer sepals) make a bold statement. The flowers often have a distinctive yellow patch and are highly attractive to pollinators in their native habitat.".to_string(),
                vec![
                    "Large, elegant flowers featuring elongated, wide sepals and petals.".to_string(),
                    "Commonly known as the Virginia Blue Flag or Southern Blue Flag.".to_string(),
                    "Prefers dark, rich damp forest soils and wetlands.".to_string(),
                    "Sturdy plant that forms extensive clumps with bright green, sword-like leaves.".to_string(),
                ],
                "virginica".to_string(),
            ),
        };

        Self {
            species: species.to_string(),
            confidence,
            probabilities: probs,
            bounding_boxes: bboxes,
            image_url: img_url,
            scientific_name,
            botanical_family,
            native_habitat,
            flowering_season,
            detailed_description,
            characteristics,
            species_key: key,
        }
    }
}
