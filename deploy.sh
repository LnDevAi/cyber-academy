#!/usr/bin/env bash
# Cyber Academy E-DEFENCE — Déploiement production (proxy centralisé edefence-proxy)
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

APP_DIR="/opt/cyber-academy"
REPO_URL="https://github.com/LnDevAi/cyber-academy.git"

[[ $EUID -ne 0 ]] && err "Lancer en root : sudo bash deploy.sh"

# 1. Clone / pull
if [ -d "$APP_DIR/.git" ]; then
  log "Pull dernière version..."
  git -C "$APP_DIR" pull origin main
else
  log "Clone du dépôt vers $APP_DIR..."
  git clone "$REPO_URL" "$APP_DIR"
fi
cd "$APP_DIR"

# 2. Fichier .env
if [ ! -f .env ]; then
  [ -f .env.example ] && cp .env.example .env || touch .env
  warn "Configurer $APP_DIR/.env avant de continuer."
  echo "Variables requises : DB_PASSWORD, REDIS_PASSWORD, MINIO_SECRET_KEY, MOODLE_ADMIN_PASSWORD, SECRET_KEY"
  read -rp "Appuyer sur Entrée pour ouvrir nano, ou Ctrl+C pour éditer manuellement : "
  nano .env
fi

# Valider les vars critiques
source .env
for var in DB_PASSWORD REDIS_PASSWORD MINIO_SECRET_KEY MOODLE_ADMIN_PASSWORD SECRET_KEY; do
  val="${!var:-}"
  [[ -z "$val" ]] && err "Variable $var non définie dans .env"
done

# 3. Vérifier le réseau proxy
/usr/bin/docker network inspect edefence_net >/dev/null 2>&1 || \
  err "Réseau edefence_net introuvable. Déploie d'abord edefence-proxy."

# 4. Initialiser le schéma Guacamole
log "Démarrage PostgreSQL pour initialisation Guacamole..."
/usr/bin/docker compose -f docker-compose.prod.yml up -d db
sleep 15
/usr/bin/docker compose -f docker-compose.prod.yml exec -T db \
  psql -U cyberacademy -c "CREATE DATABASE guacamole_db OWNER cyberacademy;" 2>/dev/null || \
  warn "guacamole_db existe déjà."

log "Génération du schéma Guacamole..."
/usr/bin/docker run --rm guacamole/guacamole:latest \
  /opt/guacamole/bin/initdb.sh --postgresql > /tmp/guacamole-initdb.sql
/usr/bin/docker compose -f docker-compose.prod.yml exec -T db \
  psql -U cyberacademy -d guacamole_db -f /tmp/guacamole-initdb.sql 2>/dev/null || \
  warn "Schéma Guacamole déjà présent."

# 5. Dossier ChromaDB
mkdir -p "${CHROMADB_PERSIST_PATH:-/opt/cyberacademy/chromadb}"

# 6. Build + démarrage
log "Build et démarrage des services (10-20 min)..."
/usr/bin/docker compose -f docker-compose.prod.yml build
/usr/bin/docker compose -f docker-compose.prod.yml up -d

# 7. Migrations
log "Attente du backend (45s)..."
sleep 45
/usr/bin/docker exec academy_api alembic upgrade head && \
  log "Migrations appliquées." || \
  warn "Migrations échouées — vérifier : docker logs academy_api"

# 8. Seeding
log "Seeding cours et labs..."
/usr/bin/docker exec academy_api python -m app.services.seed_courses 2>/dev/null && \
  log "Cours seedés." || warn "Seeding cours ignoré."
/usr/bin/docker exec academy_api python -m app.services.seed_labs 2>/dev/null && \
  log "Labs seedés." || warn "Seeding labs ignoré."

echo ""
echo -e "${GREEN}=== Cyber Academy démarrée ===${NC}"
echo "  App    : https://academy.edefence.tech"
echo "  API    : https://academy.edefence.tech/api/v1/docs"
echo "  Logs   : docker compose -f $APP_DIR/docker-compose.prod.yml logs -f"
