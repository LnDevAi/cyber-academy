# Cyber Academy E-DEFENCE

**Plateforme certifiante phygitale en cybersécurité pour la zone UEMOA**

Cyber Academy E-DEFENCE est une plateforme de formation et de certification en cybersécurité conçue spécifiquement pour la zone UEMOA (Union Économique et Monétaire Ouest-Africaine). Elle combine un LMS Moodle, un backend FastAPI, un frontend Flutter Web, un Cyber Range isolé basé sur Kubernetes, et des certificats NFT sur la blockchain Polygon.

---

## Certifications disponibles

| Code    | Titre                                            | Heures | Tarif UEMOA |
|---------|--------------------------------------------------|--------|-------------|
| CACP    | Cyber Analyste Certifié Phishing                 | 40 h   | 75 000 XOF  |
| CSA     | Cyber Security Analyst (SOC)                     | 60 h   | 120 000 XOF |
| WASO    | Web Application Security Offensive              | 50 h   | 95 000 XOF  |
| CLEH    | Certified Lead Ethical Hacker UEMOA             | 80 h   | 150 000 XOF |
| CDFIR   | Cyber Defence & Forensics Incident Response     | 70 h   | 130 000 XOF |
| CDGSI   | Chef de projet SMSI / ISO 27001                 | 60 h   | 110 000 XOF |
| CRGPD   | Correspondant RGPD / Protection des données     | 40 h   | 80 000 XOF  |
| CTIA    | Cyber Threat Intelligence Analyst               | 50 h   | 100 000 XOF |
| CNSA    | Cyber Network Security Administrator           | 55 h   | 105 000 XOF |
| CCCO    | Cyber Crisis & Communication Officer           | 35 h   | 70 000 XOF  |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     academy.edefence.tech                           │
│                   Flutter Web (CanvasKit)                           │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ HTTPS / REST / WebSocket
┌──────────────────────────▼──────────────────────────────────────────┐
│               academy-api.edefence.tech                             │
│          FastAPI (Python 3.11) + Gunicorn + Uvicorn                 │
│   ┌─────────────┐  ┌─────────────┐  ┌──────────────────────────┐   │
│   │  PostgreSQL  │  │  Redis 7   │  │  Celery Workers          │   │
│   │  16 Alpine   │  │  (cache +  │  │  (payments, badges,      │   │
│   │             │  │   broker)  │  │   range, notifications)  │   │
│   └─────────────┘  └─────────────┘  └──────────────────────────┘   │
│   ┌─────────────┐  ┌─────────────────────────────────────────────┐  │
│   │  MinIO S3   │  │  TARGUI AI (Claude + ChromaDB RAG)          │  │
│   │  (uploads)  │  │  Assistant cybersécurité UEMOA              │  │
│   └─────────────┘  └─────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                           │
         ┌─────────────────┼─────────────────────┐
         │                 │                     │
┌────────▼───────┐ ┌───────▼────────┐ ┌─────────▼──────────┐
│  lms.edefence  │ │range.edefence  │ │  Polygon Blockchain │
│  Moodle 4.x    │ │Apache Guacamole│ │  NFT Certificates   │
│  (LMS + SCORM) │ │+ k3s Cyber Range│ │  ERC-721 (IPFS)    │
└────────────────┘ └────────────────┘ └────────────────────┘
```

---

## Démarrage rapide (Développement)

### Prérequis

- Docker 24+ et Docker Compose v2
- Git
- Flutter SDK (pour développement frontend)
- Python 3.11+ (pour développement backend)

### Installation

```bash
# 1. Cloner le dépôt
git clone https://github.com/LnDevAi/cyber-academy.git
cd cyber-academy

# 2. Configurer l'environnement
cp .env.example .env
# Éditer .env avec vos valeurs

# 3. Démarrer tous les services
docker compose up -d --build

# 4. Appliquer les migrations
docker compose exec backend alembic upgrade head

# 5. Seed des données initiales
docker compose exec backend python -m app.services.seed_courses
docker compose exec backend python -m app.services.seed_labs

# 6. Vérifier
curl http://localhost:8000/api/health
```

### Accès locaux

| Service         | URL                                |
|-----------------|------------------------------------|
| Frontend        | http://localhost:3000              |
| API (FastAPI)   | http://localhost:8000              |
| API Docs        | http://localhost:8000/docs         |
| Moodle LMS      | http://localhost:8080              |
| Guacamole       | http://localhost:8081/guacamole    |
| MinIO Console   | http://localhost:9001              |

---

## Déploiement en production (Ubuntu 22.04)

```bash
# Sur le serveur de production
wget https://raw.githubusercontent.com/LnDevAi/cyber-academy/main/deploy.sh
sudo bash deploy.sh
```

Le script `deploy.sh` effectue automatiquement :
- Installation de Docker, Nginx, Certbot, kubectl, Helm
- Clonage du dépôt dans `/opt/cyberacademy`
- Configuration Let's Encrypt pour les 4 domaines
- Déploiement k3s pour le Cyber Range
- Démarrage de tous les services Docker Compose
- Migrations Alembic + seed des cours et labs

---

## Structure du projet

```
cyber-academy/
├── backend/                 # FastAPI (Python 3.11)
│   ├── app/
│   │   ├── api/             # Routes API REST
│   │   ├── models/          # Modèles SQLAlchemy
│   │   ├── services/        # Logique métier
│   │   ├── tasks/           # Tâches Celery
│   │   └── main.py
│   ├── alembic/             # Migrations DB
│   ├── tests/               # Tests pytest
│   └── Dockerfile
├── frontend/                # Flutter Web
│   ├── lib/
│   ├── Dockerfile
│   └── nginx_flutter.conf
├── nginx/
│   └── nginx.conf           # Reverse proxy config
├── cyber-range/
│   ├── helm/                # Helm chart (Kubernetes)
│   │   └── cyber-range-lab/
│   └── labs/                # Définitions des labs YAML
├── moodle/
│   └── plugins/             # Plugins Moodle personnalisés
├── .github/workflows/
│   ├── ci.yml               # CI (backend + frontend)
│   └── cd.yml               # CD (deploy production)
├── docker-compose.yml       # Développement
├── docker-compose.prod.yml  # Production
├── deploy.sh                # Script de déploiement Ubuntu
├── .env.example             # Variables d'environnement
└── README.md
```

---

## CI/CD

Le pipeline GitHub Actions comprend :

- **CI** (`ci.yml`) : Lint (Ruff), type checking (mypy), tests (pytest) pour Python 3.11 + 3.12, et flutter analyze + flutter test + flutter build web pour le frontend.
- **CD** (`cd.yml`) : Déploiement automatique sur le serveur de production via SSH sur push vers `main` ou création de tag `v*`.

---

## Contribution

Les contributions sont les bienvenues. Veuillez consulter [CONTRIBUTING.md](CONTRIBUTING.md) pour les directives de contribution.

1. Fork le dépôt
2. Créer une branche feature (`git checkout -b feature/ma-fonctionnalite`)
3. Committer les changements (`git commit -m 'feat: ajouter ma fonctionnalité'`)
4. Pousser la branche (`git push origin feature/ma-fonctionnalite`)
5. Ouvrir une Pull Request vers `dev`

---

## Licence

MIT — E-DEFENCE / Lassané NACOULMA — 2026

Voir [LICENSE](LICENSE) pour les détails complets.
