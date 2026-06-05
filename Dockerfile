# Multi-stage Dockerfile for the Iris Classification Rust Backend
# Stage 1: Build the Rust binary
FROM rust:1.82-bookworm AS builder

WORKDIR /app
COPY backend/Cargo.toml backend/Cargo.lock* ./
COPY backend/src ./src
COPY backend/migrations ./migrations
COPY backend/resources ./resources

# Build the release binary
RUN cargo build --release

# Stage 2: Minimal runtime image
FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy binary
COPY --from=builder /app/target/release/iris-backend /app/iris-backend

# Copy ONNX model and metadata
COPY --from=builder /app/resources /app/resources

# Copy migrations
COPY --from=builder /app/migrations /app/migrations

# Create static directory for Flutter Web assets
RUN mkdir -p /app/static

# Copy pre-built Flutter Web assets (built externally)
COPY frontend/build/web /app/static

ENV RUST_LOG=info
ENV DATABASE_URL=sqlite://predictions.db?mode=rwc
ENV MODEL_PATH=resources/model.onnx
ENV METADATA_PATH=resources/model_metadata.json
ENV PORT=8080

EXPOSE 8080

CMD ["/app/iris-backend"]
