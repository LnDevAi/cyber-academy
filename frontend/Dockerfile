# =============================================================================
# Cyber Academy E-DEFENCE — Flutter Web Dockerfile
# Multi-stage build: Flutter builder → Nginx static server
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Builder — Compile Flutter Web
# -----------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy dependency manifest first for layer caching
COPY pubspec.yaml pubspec.lock* ./

# Fetch dependencies
RUN flutter pub get

# Copy full source
COPY . .

# Build Flutter Web with CanvasKit renderer (production-quality graphics)
RUN flutter build web --release --no-tree-shake-icons

# -----------------------------------------------------------------------------
# Stage 2: Final — Serve with Nginx Alpine
# -----------------------------------------------------------------------------
FROM nginx:alpine AS final

LABEL maintainer="E-DEFENCE <tech@edefence.tech>"
LABEL org.opencontainers.image.title="Cyber Academy Frontend"
LABEL org.opencontainers.image.description="Flutter Web frontend for E-DEFENCE Cyber Academy"
LABEL org.opencontainers.image.vendor="E-DEFENCE"

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy compiled Flutter web build
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy Flutter-specific Nginx configuration
COPY nginx_flutter.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:80 || exit 1

CMD ["nginx", "-g", "daemon off;"]
