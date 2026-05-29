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
  if [ -f .env.example ]; then
    cp .env.example .env
    warn ".env créé depuis .env.example"
  else
    touch .env
  fi
  echo ""
  echo "================================================================"
  echo "  CONFIGURATION REQUISE"
  echo "  Editez le fichier $APP_DIR/.env avec vos secrets :"
  echo "    nano $APP_DIR/.env"
  echo ""
  echo "  Variables requises :"
  echo "    DB_PASSWORD           mot de passe PostgreSQL"
  echo "    REDIS_PASSWORD        mot de passe Redis"
  echo "    MINIO_SECRET_KEY      clé secrète MinIO"
  echo "    MOODLE_ADMIN_PASSWORD mot de passe admin Moodle"
  echo "    SECRET_KEY            clé JWT/app (openssl rand -hex 32)"
  echo ""
  echo "  Puis relancez : bash $APP_DIR/deploy.sh"
  echo "================================================================"
  exit 0
fi

# Valider les vars critiques (sans source pour éviter les erreurs de syntaxe .env)
for var in DB_PASSWORD REDIS_PASSWORD MINIO_SECRET_KEY MOODLE_ADMIN_PASSWORD SECRET_KEY; do
  val=$(grep -E "^${var}=" .env | head -1 | cut -d= -f2-)
  [[ -z "$val" ]] && err "Variable $var non définie dans .env — édite $APP_DIR/.env"
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
  psql -U cyberacademy -d guacamole_db < /tmp/guacamole-initdb.sql 2>/dev/null || \
  warn "Schéma Guacamole déjà présent."

# 5. Dossier ChromaDB
CHROMADB_PATH=$(grep -E "^CHROMADB_PERSIST_PATH=" .env | head -1 | cut -d= -f2-)
mkdir -p "${CHROMADB_PATH:-/opt/cyberacademy/chromadb}"

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
