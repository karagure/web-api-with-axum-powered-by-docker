# syntax=docker/dockerfile:1

###############################################################################
# SINGLE-STAGE image: build AND run happen in the same image, which therefore
# keeps the full Rust toolchain and the sources. Larger, but simpler.
#
# Even with one stage we keep the layer-ordering optimization: dependencies are
# compiled in their own cached layer (dummy main) BEFORE the real sources are
# copied, so editing src/ does not recompile the dependency tree.
#
# For the optimized, source-free, multi-stage variant see Dockerfile.multistage.
###############################################################################

# edition = "2024" requires Rust >= 1.85
FROM rust:1.90-slim-bookworm

WORKDIR /app

# 1) Dependency layer: copy only the manifests and build a dummy binary so that
#    Cargo downloads + compiles all deps. This layer is cached and only rebuilt
#    when Cargo.toml / Cargo.lock change.
COPY Cargo.toml Cargo.lock ./
RUN mkdir src \
    && echo "fn main() {}" > src/main.rs \
    && cargo build --release \
    && rm -rf src

# 2) Application layer: copy the real sources last and rebuild just the app.
COPY . .
RUN touch src/main.rs && cargo build --release

# Run as a non-root user.
RUN useradd --create-home --user-group app
USER app

# Configurable via env (see .env). Defaults: PORT=3000, INSTANCE_ID=hostname.
ENV PORT=3000
EXPOSE 3000

CMD ["./target/release/tp-wik-dps-01"]
