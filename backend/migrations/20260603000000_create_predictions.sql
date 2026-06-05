-- Create predictions table for PostgreSQL (Vision Architecture)
CREATE TABLE IF NOT EXISTS predictions (
    id SERIAL PRIMARY KEY,
    image_url TEXT,
    prediction TEXT NOT NULL,
    confidence REAL NOT NULL,
    bounding_boxes JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
