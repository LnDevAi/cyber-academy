#!/usr/bin/env bash
# =============================================================================
# Cyber Academy E-DEFENCE — Deployment Script
# Ubuntu 22.04 LTS
#
# Usage:
#   sudo bash deploy.sh
#
# What this script does:
#   1. Install Docker, Nginx, Certbot, Git, kubectl, Helm
#   2. Clone the repository
#   3. Configure .env
#   4. Setup k3s for Cyber Range (Kubernetes)
#   5. Initialize Guacamole DB schema
#   6. Obtain Let's Encrypt TLS certificates
#   7. Build + start Docker Compose (production)
#   8. Run Alembic database migrations
#   9. Seed courses + labs
#  10. Health check
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log()  { echo -e "${GREEN}[$(date '+%H:%M:%S')] $*${NC}"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARN: $*${NC}"; }
err()  { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR: $*${NC}" >&2; }
info() { echo -e "${BLUE}[$(date '+%H:%M:%S')] INFO: $*${NC}"; }

REPO_URL="https://github.com/LnDevAi/cyber-academy.git"
DEPLOY_DIR="/opt/cyberacademy"
DOMAINS="academy.edefence.tech academy-api.edefence.tech range.edefence.tech lms.edefence.tech"
EMAIL="admin@edefence.tech"

# =============================================================================
# 0. Pre-flight checks
# =============================================================================
log "Starting Cyber Academy E-DEFENCE deployment..."

if [[ $EUID -ne 0 ]]; then
   err "This script must be run as root (use sudo)"
   exit 1
fi

OS=$(lsb_release -si 2>/dev/null || echo "Unknown")
if [[ "$OS" != "Ubuntu" ]]; then
    warn "This script is designed for Ubuntu 22.04. Detected: $OS. Proceeding anyway..."
fi

log "Pre-flight checks passed."

# =============================================================================
# 1. Install dependencies
# =============================================================================
log "Step 1/10: Installing dependencies..."

apt-get update -qq
apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    nginx \
    certbot \
    python3-certbot-nginx \
    netcat-openbsd \
    jq \
    unzip \
    wget

# Docker
if ! command -v docker &>/dev/null; then
    log "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    log "Docker installed: $(docker --version)"
else
    log "Docker already installed: $(docker --version)"
fi

# Docker Compose v2
if ! docker compose version &>/dev/null 2>&1; then
    log "Installing Docker Compose v2..."
    apt-get install -y docker-compose-plugin
fi
log "Docker Compose: $(docker compose version)"

# kubectl
if ! command -v kubectl &>/dev/null; then
    log "Installing kubectl via snap..."
    snap install kubectl --classic
    log "kubectl installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    log "kubectl already installed."
fi

# Helm
if ! command -v helm &>/dev/null; then
    log "Installing Helm via snap..."
    snap install helm --classic
    log "Helm installed: $(helm version --short)"
else
    log "Helm already installed."
fi

log "Step 1/10 complete: All dependencies installed."

# =============================================================================
# 2. Clone repository
# =============================================================================
log "Step 2/10: Cloning repository to $DEPLOY_DIR..."

if [[ -d "$DEPLOY_DIR/.git" ]]; then
    warn "Repository already exists at $DEPLOY_DIR. Pulling latest changes..."
    cd "$DEPLOY_DIR"
    git pull origin main
else
    git clone "$REPO_URL" "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
fi

log "Step 2/10 complete: Repository ready at $DEPLOY_DIR."

# =============================================================================
# 3. Configure .env
# =============================================================================
log "Step 3/10: Configuring environment variables..."

cd "$DEPLOY_DIR"

if [[ ! -f .env ]]; then
    if [[ -f .env.example ]]; then
        cp .env.example .env
        warn ".env created from .env.example"
        warn "IMPORTANT: Please edit $DEPLOY_DIR/.env with your actual secrets before continuing."
        echo ""
        echo "Required variables to configure:"
        grep "CHANGE_ME" .env | cut -d= -f1 | while read -r var; do
            echo "  - $var"
        done
        echo ""
        read -rp "Press Enter to open .env in nano (or Ctrl+C to abort and edit manually): "
        nano .env
    else
        err ".env.example not found. Cannot create .env."
        exit 1
    fi
else
    log ".env already exists. Skipping configuration prompt."
fi

# Validate critical env vars
source .env
REQUIRED_VARS=(DB_PASSWORD REDIS_PASSWORD MINIO_SECRET_KEY MOODLE_ADMIN_PASSWORD SECRET_KEY)
for var in "${REQUIRED_VARS[@]}"; do
    val="${!var:-}"
    if [[ -z "$val" ]] || [[ "$val" == *"CHANGE_ME"* ]]; then
        err "Variable $var is not set or still has placeholder value in .env"
        exit 1
    fi
done

log "Step 3/10 complete: Environment configured."

# =============================================================================
# 4. Setup k3s for Cyber Range
# =============================================================================
log "Step 4/10: Setting up k3s (Kubernetes) for Cyber Range..."

if ! command -v k3s &>/dev/null; then
    log "Installing k3s..."
    curl -sfL https://get.k3s.io | sh -

    # Wait for k3s to be ready
    log "Waiting for k3s to start..."
    sleep 15
    until kubectl get nodes --kubeconfig /etc/rancher/k3s/k3s.yaml &>/dev/null; do
        sleep 5
        info "Waiting for k3s API server..."
    done

    log "k3s installed and running."
else
    log "k3s already installed."
fi

# Setup kubeconfig for the deploy user
KUBECONFIG_DIR="/root/.kube"
mkdir -p "$KUBECONFIG_DIR"
if [[ -f /etc/rancher/k3s/k3s.yaml ]]; then
    cp /etc/rancher/k3s/k3s.yaml "$KUBECONFIG_DIR/config"
    chmod 600 "$KUBECONFIG_DIR/config"
    export KUBECONFIG="$KUBECONFIG_DIR/config"
    log "kubeconfig configured at $KUBECONFIG_DIR/config"
fi

# Create Cyber Range namespace
kubectl create namespace cyber-range-labs --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace cyber-range-labs edefence.tech/type=cyber-range --overwrite

log "Step 4/10 complete: k3s ready, cyber-range-labs namespace created."

# =============================================================================
# 5. Initialize Guacamole DB schema
# =============================================================================
log "Step 5/10: Initializing Guacamole PostgreSQL schema..."

# Start just the DB service first
docker compose -f docker-compose.prod.yml up -d db
log "Waiting for PostgreSQL to be ready..."
until docker compose -f docker-compose.prod.yml exec -T db pg_isready -U cyberacademy -q; do
    sleep 3
    info "Waiting for PostgreSQL..."
done

# Create guacamole_db if not exists
docker compose -f docker-compose.prod.yml exec -T db psql -U cyberacademy -c \
    "CREATE DATABASE guacamole_db OWNER cyberacademy;" 2>/dev/null || \
    warn "guacamole_db already exists or error creating — continuing."

# Pull Guacamole image and extract initdb.sql schema
log "Generating Guacamole DB schema..."
docker run --rm guacamole/guacamole:latest /opt/guacamole/bin/initdb.sh --postgresql > /tmp/guacamole-initdb.sql

# Apply schema to guacamole_db
docker compose -f docker-compose.prod.yml exec -T db psql \
    -U cyberacademy \
    -d guacamole_db \
    -f /tmp/guacamole-initdb.sql 2>/dev/null || \
    warn "Guacamole schema may already exist — continuing."

log "Step 5/10 complete: Guacamole DB schema initialized."

# =============================================================================
# 6. Setup Nginx + Let's Encrypt TLS
# =============================================================================
log "Step 6/10: Configuring Nginx and Let's Encrypt TLS certificates..."

# Stop nginx if running (certbot needs port 80)
systemctl stop nginx 2>/dev/null || true

# Obtain certificates for all domains
log "Requesting Let's Encrypt certificates..."
for domain in $DOMAINS; do
    if [[ ! -d "/etc/letsencrypt/live/$domain" ]]; then
        log "Requesting certificate for $domain..."
        certbot certonly \
            --standalone \
            --non-interactive \
            --agree-tos \
            --email "$EMAIL" \
            -d "$domain" || warn "Failed to obtain cert for $domain — check DNS and try again."
    else
        log "Certificate for $domain already exists."
    fi
done

# Copy nginx config
cp "$DEPLOY_DIR/nginx/nginx.conf" /etc/nginx/nginx.conf

# Test nginx config
nginx -t && log "Nginx configuration is valid." || {
    err "Nginx configuration test failed. Check /etc/nginx/nginx.conf"
    exit 1
}

# Setup certbot renewal cron
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && nginx -s reload") | crontab -

log "Step 6/10 complete: Nginx and TLS configured."

# =============================================================================
# 7. Build + start Docker Compose (production)
# =============================================================================
log "Step 7/10: Building and starting all services (this may take 10-20 minutes)..."

cd "$DEPLOY_DIR"
docker compose -f docker-compose.prod.yml up -d --build

log "Waiting 30 seconds for services to initialize..."
sleep 30

# Verify key services
log "Checking service health..."
docker compose -f docker-compose.prod.yml ps

log "Step 7/10 complete: All services started."

# =============================================================================
# 8. Run Alembic migrations
# =============================================================================
log "Step 8/10: Running Alembic database migrations..."

# Wait for backend to be healthy
RETRY=0
MAX_RETRY=20
until docker compose -f docker-compose.prod.yml exec -T backend curl -sf http://localhost:8000/api/health &>/dev/null; do
    RETRY=$((RETRY + 1))
    if [[ $RETRY -ge $MAX_RETRY ]]; then
        err "Backend did not become healthy after ${MAX_RETRY} retries."
        docker compose -f docker-compose.prod.yml logs backend | tail -30
        exit 1
    fi
    info "Waiting for backend to be healthy (attempt $RETRY/$MAX_RETRY)..."
    sleep 15
done

docker compose -f docker-compose.prod.yml exec -T backend alembic upgrade head
log "Alembic migrations completed."

log "Step 8/10 complete: Database migrations applied."

# =============================================================================
# 9. Seed courses and labs
# =============================================================================
log "Step 9/10: Seeding courses and lab definitions..."

docker compose -f docker-compose.prod.yml exec -T backend \
    python -m app.services.seed_courses && \
    log "Courses seeded successfully." || \
    warn "Course seeding failed — check backend logs."

docker compose -f docker-compose.prod.yml exec -T backend \
    python -m app.services.seed_labs && \
    log "Labs seeded successfully." || \
    warn "Lab seeding failed — check backend logs."

log "Step 9/10 complete: Courses and labs seeded."

# =============================================================================
# 10. Health check
# =============================================================================
log "Step 10/10: Running final health checks..."

log "Checking API health endpoint..."
if curl -sf https://academy-api.edefence.tech/api/health; then
    log "API health check PASSED."
else
    err "API health check FAILED. Checking logs..."
    docker compose -f docker-compose.prod.yml logs --tail=50 backend
    exit 1
fi

# Summary
echo ""
echo "============================================================"
echo -e "${GREEN}  Cyber Academy E-DEFENCE — Deployment Complete!${NC}"
echo "============================================================"
echo ""
echo "  Services:"
echo "    Frontend (Flutter) : https://academy.edefence.tech"
echo "    API (FastAPI)      : https://academy-api.edefence.tech"
echo "    Cyber Range        : https://range.edefence.tech/guacamole"
echo "    LMS (Moodle)       : https://lms.edefence.tech"
echo "    MinIO Console      : http://$(hostname -I | awk '{print $1}'):9001"
echo ""
echo "  Management:"
echo "    Logs     : docker compose -f $DEPLOY_DIR/docker-compose.prod.yml logs -f"
echo "    Status   : docker compose -f $DEPLOY_DIR/docker-compose.prod.yml ps"
echo "    k3s      : kubectl get pods -n cyber-range-labs"
echo ""
echo -e "${YELLOW}  NEXT STEPS:"
echo "    1. Login to Moodle at https://lms.edefence.tech (admin / from .env)"
echo "    2. Install Moodle plugins from moodle/plugins/"
echo "    3. Configure Guacamole admin at https://range.edefence.tech/guacamole"
echo "    4. Set up Stripe + CinetPay webhooks in respective dashboards"
echo -e "    5. Review .env and rotate CHANGE_ME secrets${NC}"
echo ""
log "Deployment finished successfully!"
