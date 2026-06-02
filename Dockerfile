# syntax=docker/dockerfile:1

###############################################################################
# Layer ordering is tuned so that editing src/ only re-runs the final build:
# the expensive dependency compilation is isolated in its own cached layer
# (via cargo-chef) and is only invalidated when Cargo.toml/Cargo.lock change.
###############################################################################

# ---- Base: toolchain + cargo-chef (edition 2024 needs Rust >= 1.85) ----
FROM rust:1.90-slim-bookworm AS chef
RUN cargo install cargo-chef --locked
WORKDIR /app

# ---- Plan: compute a dependency "recipe" from the manifests ----
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# ---- Build: cook deps (cached), THEN copy source and build the app ----
FROM chef AS builder
# This layer only changes when dependencies change, not on every code edit.
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
# Source is copied last so edits don't bust the dependency cache above.
COPY . .
RUN cargo build --release --bin tp-wik-dps-01

# ---- Runtime: minimal image, non-root, just the binary ----
FROM debian:bookworm-slim AS runtime

# System layer (changes rarely) goes before the binary so it stays cached.
# curl is used by the compose healthcheck.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --user-group app
USER app
WORKDIR /home/app

COPY --from=builder /app/target/release/tp-wik-dps-01 /usr/local/bin/tp-wik-dps-01

# Configurable via env (see .env). Defaults: PORT=3000, INSTANCE_ID=hostname.
ENV PORT=3000
EXPOSE 3000

CMD ["tp-wik-dps-01"]
