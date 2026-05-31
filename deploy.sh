#!/usr/bin/env bash
# =============================================================================
# Cyber Academy E-DEFENCE — Déploiement production
# Serveur : root@178.105.117.241
# Réseau  : edefence_net (partagé portail + e-audit-360 + cyber-academy)
# Ports   : API→8002, Frontend→3002, MinIO→9002
# =============================================================================
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

APP_DIR="/opt/cyber-academy"
REPO_URL="https://github.com/LnDevAi/cyber-academy.git"
COMPOSE="docker compose -f ${APP_DIR}/docker-compose.prod.yml"

[[ $EUID -ne 0 ]] && err "Lancer en root : sudo bash deploy.sh"

# ===========================================================================
# 1. Clone / pull
# ===========================================================================
if [ -d "${APP_DIR}/.git" ]; then
  log "Pull dernière version..."
  git -C "${APP_DIR}" pull origin main
else
  log "Clone du dépôt vers ${APP_DIR}..."
  git clone "${REPO_URL}" "${APP_DIR}"
fi
cd "${APP_DIR}"

# ===========================================================================
# 2. Vérifier le réseau edefence_net
# ===========================================================================
docker network inspect edefence_net >/dev/null 2>&1 || {
  log "Création du réseau edefence_net..."
  docker network create edefence_net
}

# ===========================================================================
# 3. Fichier .env backend
# ===========================================================================
if [ ! -f backend/.env ]; then
  if [ -f backend/.env.example ]; then
    cp backend/.env.example backend/.env
    warn "backend/.env créé depuis .env.example — vérifiez les secrets !"
  else
    err "backend/.env manquant. Créez-le depuis le template."
  fi
fi

# Générer SECRET_KEY si placeholder
if grep -qE "^SECRET_KEY=(CHANGE_ME|changeme|$)" backend/.env 2>/dev/null; then
  SECRET=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
  sed -i "s|^SECRET_KEY=.*|SECRET_KEY=${SECRET}|" backend/.env
  log "SECRET_KEY généré automatiquement."
fi

# ===========================================================================
# 4. Créer les répertoires nécessaires
# ===========================================================================
mkdir -p /opt/cyberacademy/chromadb
log "Répertoire ChromaDB : /opt/cyberacademy/chromadb"

# ===========================================================================
# 5. Démarrage des services de base (DB + Redis + MinIO)
# ===========================================================================
log "Build de l'image API..."
${COMPOSE} build backend

log "Démarrage PostgreSQL, Redis, MinIO..."
${COMPOSE} up -d db redis minio

log "Attente de la santé des services de base (30s)..."
sleep 30

# ===========================================================================
# 6. Migrations Alembic
# ===========================================================================
log "Exécution des migrations Alembic..."
${COMPOSE} run --rm --no-deps \
  -e DATABASE_URL="$(grep '^DATABASE_URL=' backend/.env | cut -d= -f2-)" \
  backend alembic upgrade head && \
  log "Migrations appliquées." || \
  warn "Migrations échouées — vérifier les logs."

# ===========================================================================
# 7. Démarrage API + Celery
# ===========================================================================
log "Démarrage de l'API backend..."
${COMPOSE} up -d backend

log "Attente de l'API (20s)..."
sleep 20

log "Démarrage des workers Celery..."
${COMPOSE} up -d celery_worker celery_beat

# ===========================================================================
# 8. Frontend Flutter (si image disponible)
# ===========================================================================
log "Build et démarrage du frontend Flutter..."
${COMPOSE} build frontend && \
  ${COMPOSE} up -d frontend && \
  log "Frontend démarré sur port 3002." || \
  warn "Frontend non démarré — build Flutter peut nécessiter plus de RAM. Relancer manuellement."

# ===========================================================================
# 9. Seeding initial (optionnel)
# ===========================================================================
log "Seeding cours et labs (optionnel)..."
docker exec academy_api python -m app.services.seed_courses 2>/dev/null && \
  log "Cours seedés." || warn "Seeding cours ignoré (normal si déjà fait)."
docker exec academy_api python -m app.services.seed_labs 2>/dev/null && \
  log "Labs seedés." || warn "Seeding labs ignoré (normal si déjà fait)."

# ===========================================================================
# 10. Status final
# ===========================================================================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Cyber Academy E-DEFENCE — Déployée       ${NC}"
echo -e "${GREEN}============================================${NC}"
echo "  API       : http://localhost:8002/api/health"
echo "  Docs      : http://localhost:8002/api/v1/docs"
echo "  Frontend  : http://localhost:3002"
echo "  MinIO     : http://localhost:9002"
echo ""
echo "  Prod      : https://academy.edefence.tech"
echo "  API Prod  : https://academy-api.edefence.tech"
echo ""
echo "  Logs API  : docker logs -f academy_api"
echo "  Status    : docker compose -f ${APP_DIR}/docker-compose.prod.yml ps"
echo -e "${GREEN}============================================${NC}"

${COMPOSE} ps
