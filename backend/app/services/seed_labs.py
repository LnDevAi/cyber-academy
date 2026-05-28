"""Seed data — 50+ Cyber Range labs (5 per course)."""
from typing import Dict, List

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.lab import Lab

logger = structlog.get_logger(__name__)


def _k8s_manifest(image: str, port: int = 22, protocol: str = "ssh") -> Dict:
    """Generate a basic k8s Pod + Service manifest stub."""
    return {
        "apiVersion": "v1",
        "kind": "Pod",
        "metadata": {
            "labels": {"app": "cyber-lab", "protocol": protocol}
        },
        "spec": {
            "containers": [
                {
                    "name": "lab",
                    "image": image,
                    "ports": [{"containerPort": port, "protocol": "TCP"}],
                    "resources": {
                        "requests": {"cpu": "500m", "memory": "512Mi"},
                        "limits": {"cpu": "1", "memory": "1Gi"}
                    },
                    "securityContext": {
                        "runAsNonRoot": True,
                        "allowPrivilegeEscalation": False
                    }
                }
            ],
            "restartPolicy": "Never"
        },
        "service": {
            "apiVersion": "v1",
            "kind": "Service",
            "spec": {
                "ports": [{"port": port, "targetPort": port, "name": protocol}],
                "type": "ClusterIP"
            }
        }
    }


LABS_DATA: List[Dict] = [
    # ── CACP Labs (Beginner) ──────────────────────────────────────────────────
    {
        "id": "cacp-lab-01",
        "course_code": "CACP",
        "title": "Phishing UEMOA Simulator",
        "description": (
            "Analysez 10 exemples réels de tentatives de phishing ciblant des utilisateurs "
            "en Afrique de l'Ouest (emails en français, mooré, bambara). Identifiez les "
            "indicateurs de compromission, les domaines suspects, et rédigez une fiche "
            "de sensibilisation pour votre équipe."
        ),
        "difficulty": 1,
        "duration_minutes": 60,
        "docker_image": "edefence/phishing-lab:1.0",
        "objectives": [
            "Identifier les 5 indicateurs visuels d'un email de phishing",
            "Analyser un URL suspecte avec VirusTotal et URLScan.io",
            "Distinguer un SMS frauduleux Mobile Money d'un SMS légitime",
            "Rédiger une fiche de sensibilisation en français pour PME UEMOA",
        ],
        "auto_grading_script": "python /grading/check_phishing_analysis.py",
        "order_in_course": 1,
        "k8s_manifest": _k8s_manifest("edefence/phishing-lab:1.0", 8080, "http"),
    },
    {
        "id": "cacp-lab-02",
        "course_code": "CACP",
        "title": "Sécurisation poste de travail Windows",
        "description": (
            "Sur un poste Windows 10 non sécurisé, appliquez les recommandations ANSSI: "
            "désactivation des protocoles obsolètes, mise à jour, configuration du pare-feu, "
            "chiffrement BitLocker, et gestion des comptes locaux. "
            "Utilisez l'outil d'audit CIS-CAT Lite pour valider votre configuration."
        ),
        "difficulty": 1,
        "duration_minutes": 90,
        "docker_image": "edefence/windows-lab:1.0",
        "objectives": [
            "Désactiver SMBv1 et Telnet sur Windows 10",
            "Configurer Windows Defender Firewall avec règles restrictives",
            "Activer BitLocker sur le disque système",
            "Créer une stratégie de mots de passe conforme aux recommandations",
            "Obtenir un score CIS-CAT supérieur à 70%",
        ],
        "auto_grading_script": "python /grading/check_windows_hardening.py",
        "order_in_course": 2,
        "k8s_manifest": _k8s_manifest("edefence/windows-lab:1.0", 3389, "rdp"),
    },
    {
        "id": "cacp-lab-03",
        "course_code": "CACP",
        "title": "Gestion des mots de passe avec KeePass",
        "description": (
            "Installez et configurez KeePass pour une PME de 10 employés. "
            "Créez une politique de mots de passe, migrez les mots de passe existants, "
            "et configurez l'authentification à deux facteurs pour les comptes critiques. "
            "Lab en environnement Ubuntu Desktop."
        ),
        "difficulty": 1,
        "duration_minutes": 45,
        "docker_image": "edefence/desktop-lab:ubuntu22",
        "objectives": [
            "Installer et configurer KeePass 2 ou KeePassXC",
            "Créer une base de données chiffrée AES-256",
            "Importer des mots de passe depuis un CSV",
            "Configurer la politique: 16 chars min, complexité, rotation 90 jours",
            "Activer TOTP pour les comptes administrateurs",
        ],
        "auto_grading_script": None,
        "order_in_course": 3,
        "k8s_manifest": _k8s_manifest("edefence/desktop-lab:ubuntu22", 5900, "vnc"),
    },
    {
        "id": "cacp-lab-04",
        "course_code": "CACP",
        "title": "Analyse de fraude Mobile Money",
        "description": (
            "Examinez 5 scénarios de fraude Mobile Money réels en Afrique de l'Ouest: "
            "SIM swap, fraude OTP, faux opérateurs, ingénierie sociale Wave. "
            "Documentez chaque attaque et proposez des contre-mesures adaptées au contexte UEMOA."
        ),
        "difficulty": 1,
        "duration_minutes": 60,
        "docker_image": "edefence/fraud-analysis-lab:1.0",
        "objectives": [
            "Analyser un scénario de SIM swap et ses impacts",
            "Identifier les mécanismes d'une fraude OTP Wave",
            "Documenter les vecteurs d'ingénierie sociale Mobile Money",
            "Proposer 3 contre-mesures techniques et 3 mesures organisationnelles",
        ],
        "auto_grading_script": "python /grading/check_fraud_analysis.py",
        "order_in_course": 4,
        "k8s_manifest": _k8s_manifest("edefence/fraud-analysis-lab:1.0", 8080, "http"),
    },
    {
        "id": "cacp-lab-05",
        "course_code": "CACP",
        "title": "Sensibilisation — Présentation UEMOA",
        "description": (
            "Préparez et présentez une session de sensibilisation à la cybersécurité "
            "de 30 minutes pour une PME fictive de Ouagadougou. "
            "Utilisez le template E-DEFENCE fourni, adaptez au contexte local, "
            "et enregistrez votre présentation. Évaluation par les pairs."
        ),
        "difficulty": 1,
        "duration_minutes": 90,
        "docker_image": "edefence/presentation-lab:1.0",
        "objectives": [
            "Créer une présentation adaptée au public UEMOA (non-techniciens)",
            "Intégrer des exemples de menaces locales réelles",
            "Couvrir: phishing, Mobile Money, mots de passe, mises à jour",
            "Durée de 25-35 minutes, en français clair",
            "Inclure un quiz final de 5 questions",
        ],
        "auto_grading_script": None,
        "order_in_course": 5,
        "k8s_manifest": _k8s_manifest("edefence/presentation-lab:1.0", 8080, "http"),
    },

    # ── CSA Labs (Intermediate) ───────────────────────────────────────────────
    {
        "id": "csa-lab-01",
        "course_code": "CSA",
        "title": "Qualification d'alertes Wazuh",
        "description": (
            "Sur un environnement Wazuh 4.x préconfiguré avec 20 alertes réelles (mix de "
            "vraies menaces et de faux positifs), qualifiez chaque alerte: triez par sévérité, "
            "identifiez les faux positifs, documentez les IOCs, et rédigez un résumé exécutif."
        ),
        "difficulty": 2,
        "duration_minutes": 120,
        "docker_image": "edefence/wazuh-lab:4.7",
        "objectives": [
            "Se connecter à l'interface Wazuh Dashboard",
            "Qualifier 20 alertes: vrai/faux positif, sévérité, type",
            "Identifier les IOCs (IPs, hashes, domaines) pour 5 alertes critiques",
            "Rédiger un ticket d'incident Jira/ServiceNow pour l'alerte la plus critique",
            "Produire un résumé exécutif de 2 pages",
        ],
        "auto_grading_script": "python /grading/check_alert_qualification.py",
        "order_in_course": 1,
        "k8s_manifest": _k8s_manifest("edefence/wazuh-lab:4.7", 5601, "http"),
    },
    {
        "id": "csa-lab-02",
        "course_code": "CSA",
        "title": "Threat Hunting avec ELK Stack",
        "description": (
            "Dans un environnement ELK Stack avec 10 jours de logs réseau d'une banque "
            "fictive UEMOA, conduisez une chasse aux menaces. Identifiez: "
            "un mouvement latéral, une exfiltration de données, et un C2 actif. "
            "Rédigez votre rapport de hunt en français."
        ),
        "difficulty": 3,
        "duration_minutes": 180,
        "docker_image": "edefence/elk-hunt-lab:8.10",
        "objectives": [
            "Construire des requêtes Kibana/KQL pour le threat hunting",
            "Identifier un mouvement latéral via analyse des connexions SMB",
            "Détecter une exfiltration de données via analyse DNS et HTTP",
            "Identifier un beacon C2 via l'analyse des intervalles de connexion",
            "Rédiger un rapport de threat hunting avec timeline d'attaque",
        ],
        "auto_grading_script": "python /grading/check_threat_hunt.py",
        "order_in_course": 2,
        "k8s_manifest": _k8s_manifest("edefence/elk-hunt-lab:8.10", 5601, "http"),
    },
    {
        "id": "csa-lab-03",
        "course_code": "CSA",
        "title": "Déploiement Wazuh — Infrastructure PME",
        "description": (
            "Déployez un environnement Wazuh complet pour une PME fictive de 20 postes: "
            "Wazuh Manager, Wazuh Agent sur Ubuntu et Windows, intégration avec l'Active Directory, "
            "et création de règles custom pour détecter les attaques locales."
        ),
        "difficulty": 3,
        "duration_minutes": 240,
        "docker_image": "edefence/wazuh-deploy-lab:4.7",
        "objectives": [
            "Installer Wazuh Manager 4.7 sur Ubuntu 22.04",
            "Déployer Wazuh Agent sur 3 serveurs (2 Ubuntu, 1 Windows)",
            "Intégrer Wazuh avec Active Directory pour l'authentification",
            "Créer 2 règles custom: détection brute force SSH et sudo abuse",
            "Configurer des alertes email pour les événements critiques (level >= 10)",
        ],
        "auto_grading_script": "python /grading/check_wazuh_deployment.py",
        "order_in_course": 3,
        "k8s_manifest": _k8s_manifest("edefence/wazuh-deploy-lab:4.7", 55000, "tcp"),
    },
    {
        "id": "csa-lab-04",
        "course_code": "CSA",
        "title": "Réponse à incident — Ransomware PME",
        "description": (
            "Gérez un incident de ransomware simulé frappant une PME comptable de Ouagadougou. "
            "Vous recevez l'alerte à T+0. Suivez le PARI (Plan d'Action et de Réponse aux Incidents): "
            "isolation, analyse, remédiation, retour à la normale, rapport post-incident."
        ),
        "difficulty": 3,
        "duration_minutes": 180,
        "docker_image": "edefence/incident-response-lab:1.0",
        "objectives": [
            "Exécuter la procédure d'isolation du réseau en moins de 5 minutes",
            "Identifier le vecteur d'infection initial (analyse des logs)",
            "Déterminer l'étendue du chiffrement (machines touchées, données)",
            "Exécuter la procédure de restauration depuis les sauvegardes",
            "Rédiger un rapport post-incident conforme au template E-DEFENCE",
        ],
        "auto_grading_script": "python /grading/check_incident_response.py",
        "order_in_course": 4,
        "k8s_manifest": _k8s_manifest("edefence/incident-response-lab:1.0", 22, "ssh"),
    },
    {
        "id": "csa-lab-05",
        "course_code": "CSA",
        "title": "Threat Intelligence UEMOA",
        "description": (
            "Construisez un rapport de threat intelligence sur les menaces ciblant "
            "les institutions financières UEMOA au cours des 6 derniers mois. "
            "Sources: MISP, AlienVault OTX, rapports CERTs africains. "
            "Produisez des IOCs exploitables en format STIX 2.1."
        ),
        "difficulty": 2,
        "duration_minutes": 120,
        "docker_image": "edefence/threat-intel-lab:1.0",
        "objectives": [
            "Se connecter à la plateforme MISP E-DEFENCE",
            "Collecter des IOCs depuis 3 sources différentes",
            "Enrichir les IOCs avec VirusTotal et Shodan",
            "Corréler avec le framework MITRE ATT&CK",
            "Exporter un rapport STIX 2.1 consommable par un SIEM",
        ],
        "auto_grading_script": "python /grading/check_threat_intel.py",
        "order_in_course": 5,
        "k8s_manifest": _k8s_manifest("edefence/threat-intel-lab:1.0", 443, "https"),
    },

    # ── WASO Labs (Intermediate) ──────────────────────────────────────────────
    {
        "id": "waso-lab-01",
        "course_code": "WASO",
        "title": "Injection SQL sur E-COMPTA Vuln Edition",
        "description": (
            "Exploitez une application bancaire volontairement vulnérable (E-COMPTA Vuln Edition), "
            "reproduction fidèle d'un logiciel de comptabilité populaire en Afrique de l'Ouest. "
            "Découvrez et exploitez des injections SQL classiques et aveugle, "
            "extrayez la base de données clients, puis documentez et corrigez les vulnérabilités."
        ),
        "difficulty": 2,
        "duration_minutes": 120,
        "docker_image": "edefence/ecompta-vuln:1.0",
        "objectives": [
            "Identifier les points d'injection SQL via fuzzing manuel",
            "Exploiter une injection SQL classique pour extraire les données",
            "Exploiter une injection SQL aveugle (time-based) avec sqlmap",
            "Identifier l'impact métier: données clients, mots de passe, transactions",
            "Proposer la correction SQL avec requêtes paramétrées (PHP/Python)",
        ],
        "auto_grading_script": "python /grading/check_sqli_exploitation.py",
        "order_in_course": 1,
        "k8s_manifest": _k8s_manifest("edefence/ecompta-vuln:1.0", 80, "http"),
    },
    {
        "id": "waso-lab-02",
        "course_code": "WASO",
        "title": "Test API Mobile Money — CinetPay Vuln",
        "description": (
            "Testez la sécurité d'une API Mobile Money fictive (inspirée de CinetPay/Orange API). "
            "Identifiez: IDOR sur les transactions, authentification JWT faible, "
            "absence de rate limiting, et injection dans les paramètres de paiement. "
            "Rédigez un rapport de pentest API."
        ),
        "difficulty": 3,
        "duration_minutes": 150,
        "docker_image": "edefence/mobile-money-api-vuln:1.0",
        "objectives": [
            "Analyser la documentation API et identifier la surface d'attaque",
            "Exploiter un IDOR pour accéder aux transactions d'autres utilisateurs",
            "Forger un token JWT (algo=none) pour élévation de privilèges",
            "Démontrer l'absence de rate limiting sur l'endpoint de paiement",
            "Rédiger un rapport de pentest API au format OWASP API Security Top 10",
        ],
        "auto_grading_script": "python /grading/check_api_pentest.py",
        "order_in_course": 2,
        "k8s_manifest": _k8s_manifest("edefence/mobile-money-api-vuln:1.0", 8080, "http"),
    },
    {
        "id": "waso-lab-03",
        "course_code": "WASO",
        "title": "XSS et CSRF sur portail bancaire",
        "description": (
            "Exploitez des vulnérabilités XSS stocké et CSRF sur un portail bancaire "
            "fictif (style banques locales UEMOA). Démontrez le vol de cookies de session, "
            "l'injection de code malveillant persistant, et une attaque CSRF de virement. "
            "Puis corrigez les vulnérabilités dans le code PHP fourni."
        ),
        "difficulty": 2,
        "duration_minutes": 120,
        "docker_image": "edefence/bank-portal-vuln:1.0",
        "objectives": [
            "Identifier et exploiter un XSS réfléchi dans le formulaire de recherche",
            "Exploiter un XSS stocké dans le système de messagerie interne",
            "Voler un cookie de session et usurper l'identité d'un client",
            "Monter une attaque CSRF pour initier un virement frauduleux",
            "Implémenter les corrections: CSP, SameSite cookies, tokens CSRF",
        ],
        "auto_grading_script": "python /grading/check_xss_csrf.py",
        "order_in_course": 3,
        "k8s_manifest": _k8s_manifest("edefence/bank-portal-vuln:1.0", 443, "https"),
    },
    {
        "id": "waso-lab-04",
        "course_code": "WASO",
        "title": "Burp Suite — Pentest Web complet",
        "description": (
            "Conduisez un pentest web complet d'une application e-commerce UEMOA avec Burp Suite Pro. "
            "Découverte automatique, test manuel des fonctionnalités, exploitation des vulnérabilités "
            "identifiées, et génération d'un rapport Burp. "
            "Temps limité: 2h pour simuler les contraintes réelles."
        ),
        "difficulty": 3,
        "duration_minutes": 120,
        "docker_image": "edefence/ecommerce-vuln:1.0",
        "objectives": [
            "Configurer Burp Suite avec le proxy et le scanner actif",
            "Cartographier l'application avec le Spider/Crawler",
            "Identifier et exploiter au moins 3 vulnérabilités OWASP Top 10",
            "Utiliser Intruder pour un test de brute force sur le formulaire de connexion",
            "Générer et interpréter le rapport de scan Burp",
        ],
        "auto_grading_script": "python /grading/check_burpsuite_pentest.py",
        "order_in_course": 4,
        "k8s_manifest": _k8s_manifest("edefence/ecommerce-vuln:1.0", 443, "https"),
    },
    {
        "id": "waso-lab-05",
        "course_code": "WASO",
        "title": "DevSecOps — Intégration SAST dans CI/CD",
        "description": (
            "Intégrez les outils SAST (Semgrep, Bandit) et DAST (OWASP ZAP) dans un pipeline "
            "GitHub Actions pour une application FastAPI. Configurez les gates de qualité, "
            "corrigez les vulnérabilités identifiées, et documentez la stratégie DevSecOps."
        ),
        "difficulty": 3,
        "duration_minutes": 150,
        "docker_image": "edefence/devsecops-lab:1.0",
        "objectives": [
            "Configurer Semgrep dans un workflow GitHub Actions",
            "Intégrer Bandit pour l'analyse statique Python",
            "Ajouter OWASP ZAP en mode automatisé pour le DAST",
            "Définir des quality gates: blocage si CVE critique ou HIGH",
            "Corriger les 5 vulnérabilités identifiées dans le code fourni",
        ],
        "auto_grading_script": "python /grading/check_devsecops.py",
        "order_in_course": 5,
        "k8s_manifest": _k8s_manifest("edefence/devsecops-lab:1.0", 8080, "http"),
    },

    # ── CLEH_SAHEL Labs (Advanced) ────────────────────────────────────────────
    {
        "id": "cleh-lab-01",
        "course_code": "CLEH_SAHEL",
        "title": "Reconnaissance réseau PME UEMOA",
        "description": (
            "Phase de reconnaissance complète sur un réseau cible fictif représentant "
            "une PME télécoms UEMOA. Utilisez Nmap, Shodan, theHarvester, Maltego CE "
            "pour cartographier la surface d'attaque. Rédigez le rapport de reconnaissance."
        ),
        "difficulty": 3,
        "duration_minutes": 180,
        "docker_image": "edefence/recon-lab:1.0",
        "objectives": [
            "Conduire une reconnaissance passive (OSINT) sur la cible",
            "Effectuer un scan Nmap complet: ports, services, versions, OS",
            "Identifier les technologies web avec Wappalyzer/WhatWeb",
            "Collecter des informations DNS, WHOIS, certificats SSL",
            "Produire une cartographie complète de la surface d'attaque",
        ],
        "auto_grading_script": "python /grading/check_recon.py",
        "order_in_course": 1,
        "k8s_manifest": _k8s_manifest("edefence/recon-lab:1.0", 22, "ssh"),
    },
    {
        "id": "cleh-lab-02",
        "course_code": "CLEH_SAHEL",
        "title": "Exploitation Metasploit — Windows Server",
        "description": (
            "Exploitez des vulnérabilités dans un Windows Server 2019 non patché "
            "représentant un serveur PME UEMOA typique. Utilisez Metasploit Framework: "
            "exploitation EternalBlue (MS17-010), post-exploitation (Mimikatz), "
            "persistance, et couverture des traces."
        ),
        "difficulty": 4,
        "duration_minutes": 240,
        "docker_image": "edefence/metasploit-lab:6.3",
        "objectives": [
            "Scanner et identifier MS17-010 (EternalBlue) avec Nessus/Nmap",
            "Exploiter MS17-010 avec Metasploit pour obtenir un Meterpreter",
            "Extraire les hashes NTLM avec Mimikatz (hashdump)",
            "Réaliser un mouvement latéral (pass-the-hash)",
            "Établir une persistance via scheduled task",
            "Nettoyer les traces: logs Windows, PowerShell history",
        ],
        "auto_grading_script": "python /grading/check_metasploit_exploitation.py",
        "order_in_course": 2,
        "k8s_manifest": _k8s_manifest("edefence/metasploit-lab:6.3", 4444, "tcp"),
    },
    {
        "id": "cleh-lab-03",
        "course_code": "CLEH_SAHEL",
        "title": "Attaque Wi-Fi — Réseaux Orange/Moov",
        "description": (
            "Dans un environnement simulé, analysez la sécurité des réseaux Wi-Fi "
            "représentant des hotspots Orange Money et Moov Money. "
            "Conduisez des attaques WPA2: capture de handshake, dictionnaire local (mots "
            "courants en mooré/bambara/dioula), evil twin, et déauthentification."
        ),
        "difficulty": 4,
        "duration_minutes": 180,
        "docker_image": "edefence/wifi-lab:1.0",
        "objectives": [
            "Mettre une carte Wi-Fi en mode monitor avec airmon-ng",
            "Capturer un handshake WPA2 avec airodump-ng et aireplay-ng",
            "Lancer un dictionnaire local (mots africains + variantes) avec hashcat",
            "Créer un Evil Twin et capturer des credentials",
            "Rédiger les contre-mesures adaptées au contexte UEMOA",
        ],
        "auto_grading_script": "python /grading/check_wifi_attack.py",
        "order_in_course": 3,
        "k8s_manifest": _k8s_manifest("edefence/wifi-lab:1.0", 22, "ssh"),
    },
    {
        "id": "cleh-lab-04",
        "course_code": "CLEH_SAHEL",
        "title": "Social Engineering — Contexte UEMOA",
        "description": (
            "Concevez et simulez (par écrit) 3 scénarios d'ingénierie sociale adaptés "
            "au contexte UEMOA: vishing (faux support Orange Money), prétexting "
            "(faux audit DGI), et baiting (clé USB abandonnée). "
            "Documentez les contre-mesures organisationnelles."
        ),
        "difficulty": 3,
        "duration_minutes": 120,
        "docker_image": "edefence/social-eng-lab:1.0",
        "objectives": [
            "Rédiger un script de vishing (appel téléphonique) en français/dioula",
            "Concevoir un email de prétexting ciblant un comptable PME",
            "Analyser les mécanismes psychologiques exploités (urgence, autorité, peur)",
            "Proposer un programme de sensibilisation contre chaque attaque",
            "Créer un formulaire de test de sensibilisation interne",
        ],
        "auto_grading_script": None,
        "order_in_course": 4,
        "k8s_manifest": _k8s_manifest("edefence/social-eng-lab:1.0", 8080, "http"),
    },
    {
        "id": "cleh-lab-05",
        "course_code": "CLEH_SAHEL",
        "title": "Rapport de pentest professionnel",
        "description": (
            "À partir des résultats des labs précédents, rédigez un rapport de pentest "
            "complet et professionnel pour la PME fictive cible. "
            "Le rapport doit respecter le format E-DEFENCE/PECB: résumé exécutif, "
            "méthodologie, findings classés par risque, recommandations priorisées, "
            "annexes techniques. En français."
        ),
        "difficulty": 3,
        "duration_minutes": 180,
        "docker_image": "edefence/report-lab:1.0",
        "objectives": [
            "Rédiger un résumé exécutif compréhensible pour un dirigeant non-technicien",
            "Classer les vulnérabilités par score CVSS et risque métier",
            "Formuler des recommandations priorisées avec roadmap de remédiation",
            "Inclure les preuves techniques (captures d'écran, logs annotés)",
            "Respecter les considérations légales burkinabè/ivoiriennes",
        ],
        "auto_grading_script": None,
        "order_in_course": 5,
        "k8s_manifest": _k8s_manifest("edefence/report-lab:1.0", 8080, "http"),
    },

    # ── CDFIR Labs (Advanced) ─────────────────────────────────────────────────
    {
        "id": "cdfir-lab-01",
        "course_code": "CDFIR",
        "title": "Investigation ransomware — cas PME burkinabè",
        "description": (
            "Analysez le dump forensic complet (disque + mémoire) d'un serveur Windows "
            "d'une PME comptable de Ouagadougou victime d'un ransomware Lockbit 3.0. "
            "Identifiez le patient zéro, le vecteur d'infection, le mouvement latéral, "
            "et estimez l'étendue des dommages."
        ),
        "difficulty": 4,
        "duration_minutes": 240,
        "docker_image": "edefence/forensic-lab:autopsy",
        "objectives": [
            "Monter l'image disque de manière forensiquement valide (write-blocker)",
            "Analyser les logs Windows Event Viewer pour identifier le patient zéro",
            "Reconstruire la timeline d'attaque avec Autopsy",
            "Identifier le mécanisme de persistance et les fichiers chiffrés",
            "Rédiger un rapport d'investigation forensique au format judiciaire",
        ],
        "auto_grading_script": "python /grading/check_forensic_investigation.py",
        "order_in_course": 1,
        "k8s_manifest": _k8s_manifest("edefence/forensic-lab:autopsy", 5900, "vnc"),
    },
    {
        "id": "cdfir-lab-02",
        "course_code": "CDFIR",
        "title": "Forensic mémoire avec Volatility",
        "description": (
            "Analysez un dump mémoire (RAM) de 4 Go d'un système Windows 10 infecté "
            "par un RAT (Remote Access Trojan) utilisé dans une affaire d'espionnage économique. "
            "Utilisez Volatility 3 pour extraire les processus cachés, connexions réseau, "
            "et artifacts malveillants."
        ),
        "difficulty": 4,
        "duration_minutes": 180,
        "docker_image": "edefence/volatility-lab:3.0",
        "objectives": [
            "Identifier l'OS et le profil avec imageinfo/bannerinfo",
            "Lister les processus et détecter les processus cachés (psxview)",
            "Analyser les connexions réseau actives et historiques (netscan)",
            "Extraire le malware depuis la mémoire (malfind + dlllist)",
            "Récupérer les credentials depuis LSASS (hashdump)",
        ],
        "auto_grading_script": "python /grading/check_volatility_analysis.py",
        "order_in_course": 2,
        "k8s_manifest": _k8s_manifest("edefence/volatility-lab:3.0", 22, "ssh"),
    },
    {
        "id": "cdfir-lab-03",
        "course_code": "CDFIR",
        "title": "Forensic mobile Android — fraude Mobile Money",
        "description": (
            "Analysez l'image d'un téléphone Android saisi dans le cadre d'une affaire "
            "de fraude Mobile Money au Burkina Faso. Utilisez Autopsy Mobile + ADB "
            "pour extraire: SMS, contacts, historique d'appels, données des applications "
            "Orange Money et Moov Money, localisation GPS, et comptes liés."
        ),
        "difficulty": 4,
        "duration_minutes": 180,
        "docker_image": "edefence/mobile-forensic-lab:1.0",
        "objectives": [
            "Acquérir une image forensique d'un Android via ADB (mode test activé)",
            "Analyser les données SMS liées aux transactions Mobile Money",
            "Extraire les données de l'application Orange Money (.db SQLite)",
            "Reconstituer les transactions frauduleuses avec timestamps",
            "Rédiger un rapport forensique mobile conforme au droit burkinabè",
        ],
        "auto_grading_script": "python /grading/check_mobile_forensic.py",
        "order_in_course": 3,
        "k8s_manifest": _k8s_manifest("edefence/mobile-forensic-lab:1.0", 5555, "tcp"),
    },
    {
        "id": "cdfir-lab-04",
        "course_code": "CDFIR",
        "title": "Analyse PCAP — exfiltration de données",
        "description": (
            "Analysez une capture réseau de 2 Go (Wireshark PCAP) d'une banque ivoirienne "
            "suspectée d'avoir été compromise. Identifiez l'exfiltration de données clients "
            "vers un serveur externe, le protocole utilisé (DNS tunneling), "
            "et estimez le volume de données volées."
        ),
        "difficulty": 4,
        "duration_minutes": 150,
        "docker_image": "edefence/pcap-analysis-lab:1.0",
        "objectives": [
            "Filtrer le trafic pertinent dans Wireshark (DNS, HTTP, TLS)",
            "Identifier des patterns de DNS tunneling (requêtes anormalement longues)",
            "Extraire et décoder les données exfiltrées depuis le tunnel DNS",
            "Identifier l'IP de command & control et rechercher son attribution",
            "Estimer le volume de données clients exfiltrées",
        ],
        "auto_grading_script": "python /grading/check_pcap_analysis.py",
        "order_in_course": 4,
        "k8s_manifest": _k8s_manifest("edefence/pcap-analysis-lab:1.0", 22, "ssh"),
    },
    {
        "id": "cdfir-lab-05",
        "course_code": "CDFIR",
        "title": "Rapport forensique légal — affaire judiciaire",
        "description": (
            "Rédigez un rapport d'expertise forensique complet pour une affaire judiciaire "
            "fictive au tribunal de Ouagadougou. Le rapport doit être admissible comme preuve, "
            "respecter la chaîne de garde des preuves, et être compréhensible pour un juge "
            "non-technicien. Incluez toutes les annexes techniques requises."
        ),
        "difficulty": 3,
        "duration_minutes": 180,
        "docker_image": "edefence/legal-report-lab:1.0",
        "objectives": [
            "Structurer le rapport selon les normes légales burkinabè",
            "Documenter la chaîne de custody des preuves numériques",
            "Rédiger les conclusions techniques en langage accessible",
            "Inclure les hashes MD5/SHA256 de toutes les pièces à conviction",
            "Préparer un témoignage expert de 10 minutes (oral ou écrit)",
        ],
        "auto_grading_script": None,
        "order_in_course": 5,
        "k8s_manifest": _k8s_manifest("edefence/legal-report-lab:1.0", 8080, "http"),
    },

    # ── CMSP Labs (Intermediate) ──────────────────────────────────────────────
    {
        "id": "cmsp-lab-01",
        "course_code": "CMSP",
        "title": "Analyse Banking Trojan — Faux Orange Money",
        "description": (
            "Analysez un APK Android malveillant se faisant passer pour Orange Money Burkina. "
            "Utilisez MobSF (analyse statique) et Cuckoo Mobile (dynamique) pour identifier: "
            "permissions abusives, C2, mécanisme de fraude, et IOCs. "
            "Créez des règles YARA pour la détection."
        ),
        "difficulty": 3,
        "duration_minutes": 180,
        "docker_image": "edefence/malware-lab:mobsf",
        "objectives": [
            "Décompiler l'APK avec jadx et analyser le manifeste Android",
            "Identifier les permissions dangereuses et les classes malveillantes",
            "Analyser le comportement dynamique dans Cuckoo Mobile",
            "Extraire les URLs de C2 et les clés de chiffrement hardcodées",
            "Rédiger une règle YARA pour détecter la famille malware",
        ],
        "auto_grading_script": "python /grading/check_malware_analysis.py",
        "order_in_course": 1,
        "k8s_manifest": _k8s_manifest("edefence/malware-lab:mobsf", 8000, "http"),
    },
    {
        "id": "cmsp-lab-02",
        "course_code": "CMSP",
        "title": "Analyse statique avec Ghidra",
        "description": (
            "Reverse-engineerez un ransomware Windows EXE ciblant des PME africaines. "
            "Utilisez Ghidra pour identifier: l'algorithme de chiffrement (AES-256), "
            "la génération de clé, les cibles de chiffrement, "
            "et la mécanique de la demande de rançon. "
            "Cherchez une faille dans l'implémentation crypto pour un décrypteur."
        ),
        "difficulty": 4,
        "duration_minutes": 240,
        "docker_image": "edefence/ghidra-lab:11.0",
        "objectives": [
            "Importer et analyser le binaire dans Ghidra",
            "Identifier les fonctions de chiffrement avec les références croisées",
            "Comprendre le mécanisme de génération de clé AES",
            "Trouver la faille: clé codée en dur ou générateur prévisible",
            "Écrire un proof-of-concept de décrypteur en Python",
        ],
        "auto_grading_script": "python /grading/check_ghidra_analysis.py",
        "order_in_course": 2,
        "k8s_manifest": _k8s_manifest("edefence/ghidra-lab:11.0", 5900, "vnc"),
    },
    {
        "id": "cmsp-lab-03",
        "course_code": "CMSP",
        "title": "Analyse document malveillant — PDF/Office",
        "description": (
            "Analysez 3 documents malveillants reçus dans le cadre d'une campagne "
            "de spear phishing ciblant des administrations UEMOA: "
            "un PDF avec shellcode, un document Word avec macro VBA, "
            "et un fichier Excel avec formule DDE. "
            "Utilisez: pdfid, pdf-parser, oledump, olevba."
        ),
        "difficulty": 3,
        "duration_minutes": 120,
        "docker_image": "edefence/doc-malware-lab:1.0",
        "objectives": [
            "Analyser le PDF malveillant avec pdfid et pdf-parser",
            "Extraire et déobfusquer le shellcode PDF",
            "Analyser la macro VBA Word avec olevba",
            "Identifier le payload téléchargé par la macro",
            "Analyser les formules DDE Excel et leur comportement",
        ],
        "auto_grading_script": "python /grading/check_doc_malware.py",
        "order_in_course": 3,
        "k8s_manifest": _k8s_manifest("edefence/doc-malware-lab:1.0", 22, "ssh"),
    },
    {
        "id": "cmsp-lab-04",
        "course_code": "CMSP",
        "title": "Sandbox Cuckoo — Analyse dynamique",
        "description": (
            "Configurez un sandbox Cuckoo 3.0 dans un environnement isolé, "
            "analysez 3 échantillons malveillants (RAT, dropper, stealer), "
            "et interprétez les rapports comportementaux. "
            "Extrayez les IOCs réseau et créez des règles Snort/Suricata."
        ),
        "difficulty": 3,
        "duration_minutes": 180,
        "docker_image": "edefence/cuckoo-lab:3.0",
        "objectives": [
            "Déployer Cuckoo 3.0 avec une machine virtuelle Windows 10 invitée",
            "Soumettre et analyser 3 échantillons malveillants",
            "Identifier les behaviours: registre, système de fichiers, réseau",
            "Extraire les IOCs réseau: IPs, domaines, User-Agents",
            "Créer 3 règles Snort/Suricata pour détecter les connexions C2",
        ],
        "auto_grading_script": "python /grading/check_cuckoo_setup.py",
        "order_in_course": 4,
        "k8s_manifest": _k8s_manifest("edefence/cuckoo-lab:3.0", 8090, "http"),
    },
    {
        "id": "cmsp-lab-05",
        "course_code": "CMSP",
        "title": "Création règles YARA — menaces UEMOA",
        "description": (
            "Créez un jeu de règles YARA pour détecter les familles de malwares "
            "ciblant spécifiquement l'Afrique de l'Ouest: faux apps Mobile Money, "
            "banking trojans locaux, ransomwares ciblant les PME UEMOA. "
            "Testez vos règles sur un ensemble d'échantillons bénins et malveillants."
        ),
        "difficulty": 3,
        "duration_minutes": 150,
        "docker_image": "edefence/yara-lab:4.5",
        "objectives": [
            "Écrire 5 règles YARA basées sur des strings et patterns",
            "Utiliser des conditions complexes (filesize, pe.imports, etc.)",
            "Tester les règles: 0 faux positifs sur 100 échantillons bénins",
            "Atteindre un taux de détection de 90%+ sur les malwares fournis",
            "Documenter chaque règle avec metadata MITRE ATT&CK",
        ],
        "auto_grading_script": "python /grading/check_yara_rules.py",
        "order_in_course": 5,
        "k8s_manifest": _k8s_manifest("edefence/yara-lab:4.5", 22, "ssh"),
    },

    # ── NSE4 Labs (Intermediate) ──────────────────────────────────────────────
    {
        "id": "nse4-lab-01",
        "course_code": "NSE4",
        "title": "Administration FortiGate — Configuration initiale",
        "description": (
            "Configurez un FortiGate 60F depuis zéro pour une PME UEMOA: "
            "interfaces, zones (LAN, WAN, DMZ), routage statique, "
            "politiques de pare-feu de base, et accès administrateur HTTPS/SSH sécurisé."
        ),
        "difficulty": 2,
        "duration_minutes": 120,
        "docker_image": "edefence/fortigate-lab:7.4",
        "objectives": [
            "Configurer les interfaces LAN (192.168.1.1/24) et WAN (DHCP)",
            "Créer les zones de sécurité: LAN, WAN, DMZ",
            "Configurer les politiques de base: LAN vers WAN, DMZ vers WAN",
            "Activer le NAT et vérifier la connectivité Internet",
            "Sécuriser l'accès admin: désactiver HTTP, configurer admin profiles",
        ],
        "auto_grading_script": "python /grading/check_fortigate_config.py",
        "order_in_course": 1,
        "k8s_manifest": _k8s_manifest("edefence/fortigate-lab:7.4", 443, "https"),
    },
    {
        "id": "nse4-lab-02",
        "course_code": "NSE4",
        "title": "VPN IPsec site-à-site — Deux agences UEMOA",
        "description": (
            "Configurez un VPN IPsec site-à-site entre deux FortiGate représentant "
            "les sièges de Ouagadougou et Abidjan d'une entreprise UEMOA. "
            "Tunnel IKEv2, chiffrement AES-256, authentification par certificat."
        ),
        "difficulty": 3,
        "duration_minutes": 150,
        "docker_image": "edefence/fortigate-vpn-lab:7.4",
        "objectives": [
            "Configurer le tunnel IPsec IKEv2 sur les deux FortiGate",
            "Paramétrer Phase 1 (IKE): AES-256, SHA-256, DH Group 14",
            "Paramétrer Phase 2 (IPsec): AES-256, SHA-256, PFS activé",
            "Créer les politiques de routage et de pare-feu pour le trafic VPN",
            "Vérifier la connectivité et analyser les logs VPN",
        ],
        "auto_grading_script": "python /grading/check_ipsec_vpn.py",
        "order_in_course": 2,
        "k8s_manifest": _k8s_manifest("edefence/fortigate-vpn-lab:7.4", 500, "udp"),
    },
    {
        "id": "nse4-lab-03",
        "course_code": "NSE4",
        "title": "FortiGuard — Antivirus, IPS, Filtrage Web",
        "description": (
            "Activez et configurez les fonctionnalités UTM du FortiGate: "
            "antivirus FortiGuard avec scanning HTTPS, IPS avec signatures personnalisées, "
            "filtrage web par catégorie avec whitelist/blacklist locale. "
            "Testez avec du trafic malveillant simulé."
        ),
        "difficulty": 2,
        "duration_minutes": 120,
        "docker_image": "edefence/fortigate-utm-lab:7.4",
        "objectives": [
            "Activer l'inspection SSL/TLS pour le trafic HTTPS",
            "Configurer le profil antivirus avec FortiGuard",
            "Activer l'IPS avec un profil protégeant les serveurs Windows",
            "Configurer le filtrage web: bloquer Adult, Gambling, P2P",
            "Créer une whitelist pour les domaines métier locaux",
        ],
        "auto_grading_script": "python /grading/check_fortigate_utm.py",
        "order_in_course": 3,
        "k8s_manifest": _k8s_manifest("edefence/fortigate-utm-lab:7.4", 443, "https"),
    },
    {
        "id": "nse4-lab-04",
        "course_code": "NSE4",
        "title": "FortiAnalyzer — Analyse des logs",
        "description": (
            "Configurez FortiAnalyzer pour collecter et analyser les logs de 3 FortiGate. "
            "Créez des rapports personnalisés: Top menaces, trafic web, incidents VPN, "
            "activité utilisateur. Configurez des alertes par email pour les incidents critiques."
        ),
        "difficulty": 3,
        "duration_minutes": 120,
        "docker_image": "edefence/fortianalyzer-lab:7.4",
        "objectives": [
            "Configurer FortiAnalyzer et enregistrer 3 FortiGate",
            "Analyser les logs de menaces: identifier les 5 Top Threats",
            "Créer un rapport personnalisé hebdomadaire",
            "Configurer des alertes email pour severity Critical/High",
            "Utiliser FortiView pour l'analyse forensique d'un incident",
        ],
        "auto_grading_script": "python /grading/check_fortianalyzer.py",
        "order_in_course": 4,
        "k8s_manifest": _k8s_manifest("edefence/fortianalyzer-lab:7.4", 443, "https"),
    },
    {
        "id": "nse4-lab-05",
        "course_code": "NSE4",
        "title": "Haute disponibilité FortiGate Active-Passive",
        "description": (
            "Configurez un cluster HA Active-Passive entre deux FortiGate pour assurer "
            "la continuité de service pour une banque UEMOA. "
            "Testez le basculement automatique, la synchronisation de configuration, "
            "et documentez la procédure de reprise."
        ),
        "difficulty": 4,
        "duration_minutes": 180,
        "docker_image": "edefence/fortigate-ha-lab:7.4",
        "objectives": [
            "Configurer le cluster HA: Primary et Secondary FortiGate",
            "Paramétrer les interfaces de heartbeat et de synchronisation",
            "Vérifier la synchronisation complète de la configuration",
            "Simuler une panne du Primary et vérifier le basculement",
            "Documenter la procédure de failback vers le Primary",
        ],
        "auto_grading_script": "python /grading/check_fortigate_ha.py",
        "order_in_course": 5,
        "k8s_manifest": _k8s_manifest("edefence/fortigate-ha-lab:7.4", 443, "https"),
    },

    # ── CCNA_CYBEROPS Labs ────────────────────────────────────────────────────
    {
        "id": "ccna-lab-01",
        "course_code": "CCNA_CYBEROPS",
        "title": "Analyse trafic réseau avec Wireshark",
        "description": (
            "Analysez des captures réseau représentant le trafic d'une entreprise UEMOA. "
            "Identifiez: protocoles utilisés, communications suspectes, tentatives de reconnaissance, "
            "et un incident de sécurité réel dissimulé dans la capture."
        ),
        "difficulty": 2,
        "duration_minutes": 120,
        "docker_image": "edefence/cisco-lab:wireshark",
        "objectives": [
            "Filtrer et analyser le trafic HTTP/HTTPS/DNS dans Wireshark",
            "Identifier un scan Nmap dans la capture (SYN scan)",
            "Détecter une tentative de brute force FTP",
            "Reconstituer une session HTTP et extraire les données transmises",
            "Identifier l'incident dissimulé et rédiger un rapport SOC Level 1",
        ],
        "auto_grading_script": "python /grading/check_wireshark_analysis.py",
        "order_in_course": 1,
        "k8s_manifest": _k8s_manifest("edefence/cisco-lab:wireshark", 22, "ssh"),
    },
    {
        "id": "ccna-lab-02",
        "course_code": "CCNA_CYBEROPS",
        "title": "Configuration Cisco IOS — Sécurisation switches/routeurs",
        "description": (
            "Dans un environnement Cisco Packet Tracer, sécurisez un réseau d'entreprise: "
            "ACLs, port security, DHCP snooping, Dynamic ARP Inspection, "
            "et SSH sur tous les équipements. Réseau représentant une banque UEMOA."
        ),
        "difficulty": 3,
        "duration_minutes": 150,
        "docker_image": "edefence/cisco-ios-lab:1.0",
        "objectives": [
            "Configurer des ACLs standard et étendues",
            "Activer Port Security sur tous les ports d'accès",
            "Configurer DHCP Snooping et Dynamic ARP Inspection",
            "Désactiver Telnet et configurer SSH v2 sur tous les équipements",
            "Valider la configuration avec les outils de vérification Cisco",
        ],
        "auto_grading_script": "python /grading/check_cisco_hardening.py",
        "order_in_course": 2,
        "k8s_manifest": _k8s_manifest("edefence/cisco-ios-lab:1.0", 22, "ssh"),
    },
    {
        "id": "ccna-lab-03",
        "course_code": "CCNA_CYBEROPS",
        "title": "Réponse à incident SOC Cisco",
        "description": (
            "Dans un environnement SOC Cisco (Cisco SecureX + SIEM), gérez un incident "
            "de niveau 2: malware détecté sur un endpoint, possibilité de mouvement latéral. "
            "Suivez le playbook SOC, escaladez correctement, et documentez les actions."
        ),
        "difficulty": 3,
        "duration_minutes": 120,
        "docker_image": "edefence/cisco-soc-lab:1.0",
        "objectives": [
            "Analyser l'alerte initiale dans le SIEM Cisco",
            "Corréler avec les logs endpoint (Cisco AMP/XDR)",
            "Déterminer le scope de l'incident: endpoints compromis",
            "Exécuter le playbook d'isolation réseau",
            "Rédiger le ticket d'incident et escalader selon les SLA",
        ],
        "auto_grading_script": "python /grading/check_cisco_incident.py",
        "order_in_course": 3,
        "k8s_manifest": _k8s_manifest("edefence/cisco-soc-lab:1.0", 443, "https"),
    },
    {
        "id": "ccna-lab-04",
        "course_code": "CCNA_CYBEROPS",
        "title": "Cryptographie appliquée — PKI et certificats",
        "description": (
            "Mettez en place une PKI (Public Key Infrastructure) pour une organisation UEMOA: "
            "CA racine, CA intermédiaire, émission de certificats serveurs et clients, "
            "révocation (CRL/OCSP), et configuration HTTPS sur un serveur web."
        ),
        "difficulty": 3,
        "duration_minutes": 150,
        "docker_image": "edefence/pki-lab:openssl",
        "objectives": [
            "Créer une CA racine auto-signée avec OpenSSL",
            "Émettre une CA intermédiaire signée par la CA racine",
            "Générer et signer des certificats serveurs (web) et clients (VPN)",
            "Configurer la révocation: CRL et OCSP Responder",
            "Déployer HTTPS sur nginx avec le certificat émis",
        ],
        "auto_grading_script": "python /grading/check_pki_setup.py",
        "order_in_course": 4,
        "k8s_manifest": _k8s_manifest("edefence/pki-lab:openssl", 443, "https"),
    },
    {
        "id": "ccna-lab-05",
        "course_code": "CCNA_CYBEROPS",
        "title": "Simulation examen CCNA CyberOps",
        "description": (
            "Passez une simulation d'examen CCNA CyberOps 200-201 en conditions réelles: "
            "60 questions QCM + 5 questions pratiques simulées, 120 minutes. "
            "Accédez au feedback détaillé et aux révisions ciblées sur les domaines échoués."
        ),
        "difficulty": 3,
        "duration_minutes": 120,
        "docker_image": "edefence/exam-sim-lab:1.0",
        "objectives": [
            "Répondre à 60 questions couvrant tous les domaines CBROPS",
            "Obtenir un score de 75%+ (seuil de passage Cisco: 825/1000)",
            "Identifier les 3 domaines les plus faibles pour révision ciblée",
            "Analyser les questions ratées avec les explications détaillées",
        ],
        "auto_grading_script": "python /grading/check_exam_score.py",
        "order_in_course": 5,
        "k8s_manifest": _k8s_manifest("edefence/exam-sim-lab:1.0", 8080, "http"),
    },

    # ── ISO27001_LI Labs ──────────────────────────────────────────────────────
    {
        "id": "iso27001-lab-01",
        "course_code": "ISO27001_LI",
        "title": "Analyse des risques ISO 27005 — Banque UEMOA",
        "description": (
            "Conduisez une analyse des risques ISO 27005 pour une banque fictive de Côte d'Ivoire. "
            "Identifiez les actifs, menaces, vulnérabilités, évaluez les risques, "
            "et proposez un plan de traitement des risques avec les contrôles ISO 27001 Annexe A associés."
        ),
        "difficulty": 3,
        "duration_minutes": 180,
        "docker_image": "edefence/isms-lab:1.0",
        "objectives": [
            "Cartographier les actifs informationnels critiques de la banque",
            "Identifier 20 menaces et vulnérabilités associées",
            "Évaluer les risques (impact × vraisemblance) avec la matrice ISO 27005",
            "Sélectionner les contrôles appropriés de l'Annexe A ISO 27001:2022",
            "Rédiger le Plan de Traitement des Risques (PTR)",
        ],
        "auto_grading_script": None,
        "order_in_course": 1,
        "k8s_manifest": _k8s_manifest("edefence/isms-lab:1.0", 8080, "http"),
    },
    {
        "id": "iso27001-lab-02",
        "course_code": "ISO27001_LI",
        "title": "Documentation SMSI — Politique et procédures",
        "description": (
            "Rédigez la documentation SMSI complète pour une PME de 50 employés: "
            "Politique de Sécurité de l'Information, Déclaration d'Applicabilité (SoA), "
            "Procédure de gestion des incidents, et Procédure de contrôle des accès."
        ),
        "difficulty": 2,
        "duration_minutes": 180,
        "docker_image": "edefence/isms-doc-lab:1.0",
        "objectives": [
            "Rédiger la Politique de Sécurité de l'Information (1-2 pages)",
            "Compléter la Déclaration d'Applicabilité (93 contrôles ISO 27001:2022)",
            "Rédiger la procédure de gestion des incidents (incluant formulaires)",
            "Rédiger la procédure de contrôle des accès (IAM)",
            "Vérifier la cohérence avec les résultats de l'analyse des risques",
        ],
        "auto_grading_script": None,
        "order_in_course": 2,
        "k8s_manifest": _k8s_manifest("edefence/isms-doc-lab:1.0", 8080, "http"),
    },
    {
        "id": "iso27001-lab-03",
        "course_code": "ISO27001_LI",
        "title": "Audit interne SMSI",
        "description": (
            "Conduisez un audit interne SMSI d'une organisation fictive qui prépare "
            "sa certification ISO 27001. Utilisez les checklists E-DEFENCE basées sur "
            "ISO 27001:2022. Identifiez les non-conformités, rédigez les constats, "
            "et animez la réunion de clôture."
        ),
        "difficulty": 3,
        "duration_minutes": 180,
        "docker_image": "edefence/audit-lab:1.0",
        "objectives": [
            "Préparer le plan d'audit et les checklists",
            "Conduire des entretiens d'audit (simulés) avec les responsables",
            "Identifier et classer les non-conformités (NC majeures/mineures)",
            "Rédiger le rapport d'audit avec les constats documentés",
            "Préparer et animer la réunion de clôture",
        ],
        "auto_grading_script": None,
        "order_in_course": 3,
        "k8s_manifest": _k8s_manifest("edefence/audit-lab:1.0", 8080, "http"),
    },
    {
        "id": "iso27001-lab-04",
        "course_code": "ISO27001_LI",
        "title": "Plan de continuité d'activité — PME UEMOA",
        "description": (
            "Rédigez un Plan de Continuité d'Activité (PCA) et un Plan de Reprise "
            "Après Sinistre (PRA) pour une PME de services financiers en zone UEMOA. "
            "Définissez les RTO/RPO, les scénarios de crise locaux (coupure électrique, "
            "inondation, attaque cyber), et les procédures de reprise."
        ),
        "difficulty": 3,
        "duration_minutes": 150,
        "docker_image": "edefence/bcp-lab:1.0",
        "objectives": [
            "Conduire un BIA (Business Impact Analysis)",
            "Définir des RTO et RPO réalistes pour les processus critiques",
            "Identifier les scénarios de crise spécifiques à l'Afrique de l'Ouest",
            "Rédiger les procédures de reprise pour chaque scénario",
            "Planifier un exercice de test PCA/PRA",
        ],
        "auto_grading_script": None,
        "order_in_course": 4,
        "k8s_manifest": _k8s_manifest("edefence/bcp-lab:1.0", 8080, "http"),
    },
    {
        "id": "iso27001-lab-05",
        "course_code": "ISO27001_LI",
        "title": "Simulation examen PECB ISO 27001 Lead Implementer",
        "description": (
            "Simulation d'examen PECB ISO 27001 Lead Implementer: "
            "150 questions en 4 heures couvrant tous les domaines: "
            "Concepts fondamentaux, Planification, Implémentation, Évaluation, Amélioration. "
            "Feedback détaillé sur les réponses avec références normatives."
        ),
        "difficulty": 4,
        "duration_minutes": 240,
        "docker_image": "edefence/exam-sim-lab:iso27001",
        "objectives": [
            "Répondre à 150 questions PECB ISO 27001 Lead Implementer",
            "Obtenir un score de 70%+ (seuil de passage PECB)",
            "Maîtriser les 5 domaines de la certification",
            "Identifier les lacunes pour révision ciblée",
        ],
        "auto_grading_script": "python /grading/check_exam_score.py",
        "order_in_course": 5,
        "k8s_manifest": _k8s_manifest("edefence/exam-sim-lab:iso27001", 8080, "http"),
    },

    # ── CDPO_UEMOA Labs ───────────────────────────────────────────────────────
    {
        "id": "cdpo-lab-01",
        "course_code": "CDPO_UEMOA",
        "title": "Cartographie des traitements — Hôpital UEMOA",
        "description": (
            "Réalisez la cartographie complète des traitements de données personnelles "
            "d'un hôpital fictif en Côte d'Ivoire: patients, personnel, prestataires. "
            "Identifiez les traitements soumis à déclaration/autorisation selon la loi CI 2013-450 "
            "et les données sensibles (données de santé, biométriques)."
        ),
        "difficulty": 2,
        "duration_minutes": 120,
        "docker_image": "edefence/dpo-lab:1.0",
        "objectives": [
            "Identifier tous les traitements de données personnelles de l'hôpital",
            "Compléter le registre des traitements (format RGPD adapté UEMOA)",
            "Identifier les traitements nécessitant une AIPD",
            "Classer les données par catégorie (communes vs sensibles)",
            "Proposer les bases légales applicables selon la loi CI",
        ],
        "auto_grading_script": None,
        "order_in_course": 1,
        "k8s_manifest": _k8s_manifest("edefence/dpo-lab:1.0", 8080, "http"),
    },
    {
        "id": "cdpo-lab-02",
        "course_code": "CDPO_UEMOA",
        "title": "AIPD — Application Mobile Money",
        "description": (
            "Conduisez une Analyse d'Impact sur la Protection des Données (AIPD/PIA) "
            "pour une application Mobile Money collectant des données biométriques "
            "pour l'onboarding KYC. Utilisez la méthodologie CNIL adaptée au contexte UEMOA."
        ),
        "difficulty": 3,
        "duration_minutes": 150,
        "docker_image": "edefence/dpo-lab:1.0",
        "objectives": [
            "Décrire les traitements et la nécessité de l'AIPD",
            "Évaluer les mesures de conformité existantes",
            "Identifier les risques sur les droits et libertés des personnes",
            "Évaluer la gravité et la vraisemblance de chaque risque",
            "Proposer des mesures correctives et planifier leur mise en œuvre",
        ],
        "auto_grading_script": None,
        "order_in_course": 2,
        "k8s_manifest": _k8s_manifest("edefence/dpo-lab:1.0", 8080, "http"),
    },
    {
        "id": "cdpo-lab-03",
        "course_code": "CDPO_UEMOA",
        "title": "Gestion de violation de données",
        "description": (
            "Gérez une violation de données fictive: fuite de 10 000 comptes clients "
            "d'une banque sénégalaise sur un forum darkweb. "
            "Suivez la procédure de notification: CDP Sénégal (Commission de Protection des Données), "
            "personnes concernées, et communication de crise."
        ),
        "difficulty": 3,
        "duration_minutes": 120,
        "docker_image": "edefence/dpo-lab:1.0",
        "objectives": [
            "Qualifier la violation selon les critères légaux sénégalais",
            "Évaluer le risque pour les droits des personnes concernées",
            "Rédiger la notification à la CDP Sénégal (formulaire officiel)",
            "Rédiger la communication aux personnes concernées",
            "Documenter l'incident dans le registre des violations",
        ],
        "auto_grading_script": None,
        "order_in_course": 3,
        "k8s_manifest": _k8s_manifest("edefence/dpo-lab:1.0", 8080, "http"),
    },
    {
        "id": "cdpo-lab-04",
        "course_code": "CDPO_UEMOA",
        "title": "Audit conformité PDCP — Entreprise de télécoms",
        "description": (
            "Conduisez un audit de conformité PDCP pour un opérateur télécoms "
            "opérant dans 3 pays UEMOA (Burkina, Mali, Togo). "
            "Évaluez la conformité sur 50 critères: consentement, droits des personnes, "
            "sécurité, sous-traitants, transferts internationaux."
        ),
        "difficulty": 3,
        "duration_minutes": 180,
        "docker_image": "edefence/dpo-lab:1.0",
        "objectives": [
            "Utiliser la grille d'audit conformité E-DEFENCE (50 critères)",
            "Évaluer le niveau de conformité actuel (score sur 100)",
            "Identifier les non-conformités prioritaires",
            "Rédiger le rapport d'audit avec plan de remédiation",
            "Proposer une roadmap de mise en conformité sur 12 mois",
        ],
        "auto_grading_script": None,
        "order_in_course": 4,
        "k8s_manifest": _k8s_manifest("edefence/dpo-lab:1.0", 8080, "http"),
    },
    {
        "id": "cdpo-lab-05",
        "course_code": "CDPO_UEMOA",
        "title": "Simulation examen PECB DPO",
        "description": (
            "Simulation de l'examen PECB Certified Data Protection Officer "
            "avec 100 questions couvrant: réglementations UEMOA, RGPD, ISO 29100, "
            "droits des personnes, sécurité des données, transferts internationaux. "
            "Durée: 3 heures. Score minimum: 70%."
        ),
        "difficulty": 3,
        "duration_minutes": 180,
        "docker_image": "edefence/exam-sim-lab:dpo",
        "objectives": [
            "Répondre à 100 questions PECB DPO",
            "Obtenir un score de 70%+ (seuil de passage)",
            "Couvrir les 8 réglementations UEMOA de protection des données",
            "Identifier les lacunes pour révision ciblée",
        ],
        "auto_grading_script": "python /grading/check_exam_score.py",
        "order_in_course": 5,
        "k8s_manifest": _k8s_manifest("edefence/exam-sim-lab:dpo", 8080, "http"),
    },
]


async def seed_labs(db: AsyncSession) -> int:
    """
    Insert all 50+ labs into the database.

    Args:
        db: Async SQLAlchemy session

    Returns:
        Number of labs created or updated
    """
    count = 0

    for lab_data in LABS_DATA:
        # Check if already exists
        existing = await db.get(Lab, lab_data["id"])

        if existing:
            for key, value in lab_data.items():
                if key != "id":
                    setattr(existing, key, value)
            logger.info("Lab mis à jour", lab_id=lab_data["id"])
        else:
            lab = Lab(**lab_data)
            db.add(lab)
            logger.info("Lab créé", lab_id=lab_data["id"])
            count += 1

    await db.flush()
    logger.info("Seed labs terminé", created=count, total=len(LABS_DATA))
    return count
