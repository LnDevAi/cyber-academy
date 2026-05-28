# Changelog

Tous les changements notables apportés à **Cyber Academy E-DEFENCE** sont documentés dans ce fichier.

Le format suit [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
et ce projet adhère au [Versionnage Sémantique](https://semver.org/lang/fr/).

---

## [Non publié]

### À venir
- Module de simulation d'entretien technique IA (TARGUI)
- Support multilingue : français, anglais, mooré, dioula
- Application mobile Flutter (iOS + Android)
- Intégration Wave Money pour les paiements au Sénégal
- Labs Cyber Range pour les certifications CDGSI et CRGPD

---

## [1.0.0] — 2026-05-28

### Ajouté

#### Infrastructure
- `docker-compose.yml` : environnement de développement complet avec 10 services
- `docker-compose.prod.yml` : configuration production avec Gunicorn, healthchecks, logging JSON
- `nginx/nginx.conf` : reverse proxy Nginx avec TLS 1.2/1.3, WebSocket pour Guacamole, rate limiting
- `deploy.sh` : script de déploiement automatisé Ubuntu 22.04 (Docker, k3s, Certbot, migrations)
- `.github/workflows/ci.yml` : pipeline CI parallèle backend (Python 3.11/3.12) + frontend (Flutter)
- `.github/workflows/cd.yml` : déploiement continu SSH sur push main + tags de version

#### Backend (FastAPI)
- Authentification JWT (access + refresh tokens)
- Gestion des utilisateurs et profils apprenants
- Catalogue de 10 certifications UEMOA
- Intégration Moodle via REST API + webhooks
- Paiements CinetPay (Mobile Money UEMOA) + Stripe (international)
- Certificats NFT sur Polygon (ERC-721) avec métadonnées IPFS
- Cyber Range : déploiement dynamique de labs Kubernetes via Helm
- TARGUI AI : assistant cybersécurité RAG (Claude + ChromaDB)
- Tâches Celery : badges, notifications email, monitoring labs

#### Frontend (Flutter Web)
- Interface apprenant responsive (CanvasKit renderer)
- Dashboard de progression par certification
- Lecteur de cours SCORM intégré (iframe Moodle)
- Interface Cyber Range (embed Guacamole)
- Paiement Mobile Money + Stripe en ligne
- Visualisation de certificat NFT

#### Cyber Range (Kubernetes)
- Helm chart `cyber-range-lab` : déploiement isolé de pods Kali Linux
- NetworkPolicy : isolation réseau totale, pas d'accès internet pour les étudiants
- 5 labs initiaux : phishing UEMOA, alertes Wazuh SOC, SQLi bancaire, recon PME, forensique ransomware
- Apache Guacamole : accès RDP/SSH/VNC depuis le navigateur

#### LMS Moodle
- Bitnami Moodle 4.x avec PostgreSQL
- Structure de plugins documentée : thème E-DEFENCE, rapport de notes, webhook FastAPI
- Configuration PHP optimisée (512 MB mémoire, 200 MB upload)

#### Sécurité
- TLS 1.2/1.3 obligatoire sur tous les domaines
- Rate limiting API (30 req/s général, 5 req/min sur /auth)
- Headers de sécurité : HSTS, CSP, X-Frame-Options, X-Content-Type-Options
- Isolation réseau complète des labs Cyber Range
- Secrets gérés via variables d'environnement (`.env.example` fourni)

### Certifications disponibles à la v1.0.0

| Code  | Titre                                        | Heures | Tarif    |
|-------|----------------------------------------------|--------|----------|
| CACP  | Cyber Analyste Certifié Phishing             | 40 h   | 75 000 XOF |
| CSA   | Cyber Security Analyst (SOC)                 | 60 h   | 120 000 XOF |
| WASO  | Web Application Security Offensive          | 50 h   | 95 000 XOF |
| CLEH  | Certified Lead Ethical Hacker UEMOA         | 80 h   | 150 000 XOF |
| CDFIR | Cyber Defence & Forensics Incident Response | 70 h   | 130 000 XOF |
| CDGSI | Chef de projet SMSI / ISO 27001             | 60 h   | 110 000 XOF |
| CRGPD | Correspondant RGPD / Protection des données | 40 h   | 80 000 XOF |
| CTIA  | Cyber Threat Intelligence Analyst           | 50 h   | 100 000 XOF |
| CNSA  | Cyber Network Security Administrator       | 55 h   | 105 000 XOF |
| CCCO  | Cyber Crisis & Communication Officer       | 35 h   | 70 000 XOF |

---

[Non publié]: https://github.com/LnDevAi/cyber-academy/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/LnDevAi/cyber-academy/releases/tag/v1.0.0
