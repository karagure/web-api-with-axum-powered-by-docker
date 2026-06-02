# syntax=docker/dockerfile:1

###############################################################################
# Fully static (musl) binary shipped on `scratch`: no OS packages at all,
# so there is no attack surface for vulnerability scanners (target: 0 CVE).
#
# Layer ordering is tuned so that editing src/ only re-runs the final build:
# dependency compilation is isolated in its own cached layer (cargo-chef) and
# is only invalidated when Cargo.toml / Cargo.lock change.
###############################################################################

# ---- Base: toolchain + musl target + cargo-chef (edition 2024 => Rust >= 1.85)
FROM rust:1.90-slim-bookworm AS chef
RUN apt-get update \
    && apt-get install -y --no-install-recommends musl-tools \
    && rm -rf /var/lib/apt/lists/* \
    && rustup target add x86_64-unknown-linux-musl \
    && cargo install cargo-chef --locked
WORKDIR /app

# ---- Plan: compute a dependency "recipe" from the manifests ----
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# ---- Build: cook deps (cached), THEN copy source and build the app ----
FROM chef AS builder
# This layer only changes when dependencies change, not on every code edit.
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --target x86_64-unknown-linux-musl --recipe-path recipe.json
# Source is copied last so edits don't bust the dependency cache above.
COPY . .
RUN cargo build --release --target x86_64-unknown-linux-musl --bin tp-wik-dps-01

# ---- Runtime: empty image, just the static binary, non-root ----
FROM scratch AS runtime

# Static binary => no dynamic loader, no libc, no shell, nothing to scan.
COPY --from=builder \
    /app/target/x86_64-unknown-linux-musl/release/tp-wik-dps-01 \
    /tp-wik-dps-01

# Run as a non-root numeric UID (scratch has no /etc/passwd, that's fine).
USER 10001

# Configurable via env (see .env). Defaults: PORT=3000, INSTANCE_ID=hostname.
ENV PORT=3000
EXPOSE 3000

ENTRYPOINT ["/tp-wik-dps-01"]
