"""Seed data — 10 certification courses from CDCD."""
from typing import List

import structlog
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.course import Course, CourseLevel, CoursePartner, CourseType

logger = structlog.get_logger(__name__)

COURSES_DATA = [
    {
        "code": "CACP",
        "title": "Certified Associate in Cybersecurity Practice",
        "short_description": "Initiation à la cybersécurité pour l'espace UEMOA — 40h",
        "description": (
            "Le programme CACP est la porte d'entrée dans l'écosystème Cyber Academy E-DEFENCE. "
            "Conçu pour les professionnels sans expérience préalable en cybersécurité, il couvre "
            "les fondamentaux: phishing en contexte africain, sécurisation des postes de travail, "
            "gestion des mots de passe, bases TCP/IP, et sensibilisation PDCP-UEMOA. "
            "À l'issue du programme, l'apprenant peut conduire une session de sensibilisation "
            "en entreprise et identifier les vecteurs d'attaque courants dans la zone UEMOA."
        ),
        "type": CourseType.ECERT,
        "partner": CoursePartner.EDEFENCE,
        "level": CourseLevel.BEGINNER,
        "hours_total": 40,
        "price_fcfa": 75000,
        "price_eur": 114.0,
        "prerequisites": "Aucun prérequis technique. Maîtrise de base de l'informatique.",
        "objectives": (
            "• Identifier les principales menaces cyber en Afrique de l'Ouest\n"
            "• Appliquer les bonnes pratiques de cyberhygiène\n"
            "• Sécuriser un poste de travail Windows/Linux\n"
            "• Conduire une session de sensibilisation en entreprise\n"
            "• Comprendre le cadre PDCP-UEMOA"
        ),
        "target_audience": "Employés de bureau, assistants administratifs, PME UEMOA, ONG, administrations publiques",
    },
    {
        "code": "CSA",
        "title": "Certified Security Analyst",
        "short_description": "Analyste SOC niveau 1 avec focus sur les menaces UEMOA — 80h",
        "description": (
            "Le CSA forme des analystes SOC opérationnels capables de travailler avec les "
            "outils SIEM open source (Wazuh, ELK Stack) dans un contexte africain. "
            "Le programme inclut l'analyse de logs réels, la qualification d'alertes, "
            "la threat intelligence appliquée aux menaces ciblant la CEMAC et l'UEMOA "
            "(banking trojans, ransomwares PME, fraude Mobile Money), et la rédaction "
            "de rapports d'incidents en français. Lab pratique: qualification de 20 alertes Wazuh réelles."
        ),
        "type": CourseType.ECERT,
        "partner": CoursePartner.EDEFENCE,
        "level": CourseLevel.INTERMEDIATE,
        "hours_total": 80,
        "price_fcfa": 175000,
        "price_eur": 267.0,
        "prerequisites": "CACP ou expérience équivalente en réseau/systèmes. Notions Linux.",
        "objectives": (
            "• Déployer et administrer Wazuh/ELK Stack\n"
            "• Analyser et qualifier des alertes SIEM\n"
            "• Construire une threat intelligence UEMOA\n"
            "• Gérer un incident de sécurité de bout en bout\n"
            "• Rédiger des rapports d'incidents professionnels en français"
        ),
        "target_audience": "Administrateurs système/réseau, informaticiens voulant évoluer vers la cybersécurité",
    },
    {
        "code": "CDPO_UEMOA",
        "title": "Certified Data Protection Officer UEMOA",
        "short_description": "Certification DPO adaptée aux réglementations africaines — 120h",
        "description": (
            "Programme PECB spécialement adapté pour la zone UEMOA, couvrant les 8 réglementations "
            "nationales de protection des données en vigueur: Burkina Faso (loi 045-2009 révisée), "
            "Côte d'Ivoire (loi 2013-450), Sénégal (loi 2008-12), Mali, Niger, Togo, Bénin, Guinée-Bissau. "
            "Le programme inclut la cartographie des traitements, l'AIPD (analyse d'impact), "
            "la gestion des violations de données, et la mise en conformité PDCP. "
            "La certification est reconnue par les autorités de protection des données UEMOA."
        ),
        "type": CourseType.INTERNATIONAL,
        "partner": CoursePartner.PECB,
        "level": CourseLevel.INTERMEDIATE,
        "hours_total": 120,
        "price_fcfa": 425000,
        "price_eur": 648.0,
        "prerequisites": "Expérience juridique ou en gestion des risques. Connaissance des réglementations locales recommandée.",
        "objectives": (
            "• Exercer la fonction de DPO dans une organisation UEMOA\n"
            "• Cartographier les traitements de données personnelles\n"
            "• Conduire une AIPD (PIA) conforme aux standards UEMOA\n"
            "• Gérer les droits des personnes et les violations de données\n"
            "• Piloter un programme de mise en conformité PDCP\n"
            "• Réussir l'examen de certification PECB DPO"
        ),
        "target_audience": "Juristes, responsables conformité, DPO en exercice, DSI d'organisations opérant en zone UEMOA",
    },
    {
        "code": "ISO27001_LI",
        "title": "ISO 27001 Lead Implementer",
        "short_description": "Certification internationale PECB — Implémenteur SMSI ISO 27001:2022 — 100h",
        "description": (
            "Programme de référence mondiale pour la mise en œuvre d'un Système de Management "
            "de la Sécurité de l'Information (SMSI) conforme à la norme ISO 27001:2022. "
            "Le programme couvre le cycle complet: périmètre, évaluation des risques (ISO 27005), "
            "sélection des contrôles (Annexe A révisée), documentation, audit interne et revue de direction. "
            "La certification PECB ISO 27001 Lead Implementer est reconnue internationalement "
            "et très recherchée en Afrique subsaharienne pour les appels d'offres IT."
        ),
        "type": CourseType.INTERNATIONAL,
        "partner": CoursePartner.PECB,
        "level": CourseLevel.ADVANCED,
        "hours_total": 100,
        "price_fcfa": 650000,
        "price_eur": 991.0,
        "prerequisites": "CSA ou expérience de 2 ans en sécurité. Connaissance des normes ISO recommandée.",
        "objectives": (
            "• Comprendre les exigences ISO 27001:2022\n"
            "• Planifier et mettre en œuvre un SMSI\n"
            "• Appliquer ISO 27005 pour l'évaluation des risques\n"
            "• Sélectionner et implémenter les contrôles de l'Annexe A\n"
            "• Préparer un audit de certification tierce partie\n"
            "• Obtenir la certification PECB ISO 27001 Lead Implementer"
        ),
        "target_audience": "RSSI, consultants sécurité, auditeurs, DSI voulant certifier leur organisation",
    },
    {
        "code": "CLEH_SAHEL",
        "title": "Certified Lead Ethical Hacker SAHEL Edition",
        "short_description": "Hacking éthique adapté aux infrastructures PME et administrations UEMOA — 160h",
        "description": (
            "Le CLEH SAHEL est la formation de hacking éthique la plus complète adaptée au contexte "
            "africain. Couvrant 160 heures, le programme va de la reconnaissance OSINT (cibles africaines, "
            "sources ouvertes locales) jusqu'à la rédaction de rapports de pentest conformes aux standards "
            "légaux burkinabè, ivoiriens et sénégalais. Partenariat double PECB / EC-Council. "
            "Les labs incluent des scénarios réels: PME télécoms UEMOA, portails e-gouvernement, "
            "APIs Mobile Money, réseaux Wi-Fi Orange/Moov. "
            "La certification couvre les aspects légaux spécifiques (loi cybercriminalité Burkina, CI, Sénégal)."
        ),
        "type": CourseType.INTERNATIONAL,
        "partner": CoursePartner.EC_COUNCIL,
        "level": CourseLevel.ADVANCED,
        "hours_total": 160,
        "price_fcfa": 750000,
        "price_eur": 1143.0,
        "prerequisites": "CSA ou WASO + 1 an d'expérience réseau/système. Python ou scripting recommandé.",
        "objectives": (
            "• Conduire un pentest complet de bout en bout\n"
            "• Maîtriser les outils: Nmap, Metasploit, Burp Suite, Aircrack-ng\n"
            "• Exploiter des vulnérabilités dans des environnements africains\n"
            "• Rédiger un rapport de pentest professionnel en français\n"
            "• Respecter le cadre légal de la cybercriminalité UEMOA\n"
            "• Obtenir la double certification PECB/EC-Council CEH"
        ),
        "target_audience": "Pentesters, auditeurs sécurité, équipes red team, RSSI voulant comprendre l'attaque",
    },
    {
        "code": "WASO",
        "title": "Web Application Security Operator",
        "short_description": "Sécurité des applications web avec focus fintech et Mobile Money UEMOA — 100h",
        "description": (
            "WASO couvre la sécurité des applications web avec un focus particulier sur les "
            "vulnérabilités courantes dans les fintech et e-commerce de la zone UEMOA. "
            "Le programme traite des APIs Mobile Money (CinetPay, Orange Money API, Wave API), "
            "des portails bancaires locaux, et des e-administrations. "
            "OWASP Top 10 complet, tests avec Burp Suite, remédiation dans du code Python/PHP/Node.js, "
            "et intégration de la sécurité dans les pipelines CI/CD (DevSecOps). "
            "Lab phare: 'Injection SQL sur E-COMPTA Vuln Edition' — application bancaire vulnérable."
        ),
        "type": CourseType.ECERT,
        "partner": CoursePartner.EDEFENCE,
        "level": CourseLevel.INTERMEDIATE,
        "hours_total": 100,
        "price_fcfa": 350000,
        "price_eur": 534.0,
        "prerequisites": "Bases en développement web (HTML/PHP/Python). Notions HTTP/HTTPS.",
        "objectives": (
            "• Maîtriser l'OWASP Top 10 en contexte africain\n"
            "• Utiliser Burp Suite pour les tests d'intrusion web\n"
            "• Tester la sécurité des APIs Mobile Money\n"
            "• Corriger les vulnérabilités dans du code Python/PHP/Node.js\n"
            "• Intégrer SAST/DAST dans un pipeline CI/CD\n"
            "• Rédiger un rapport de test d'intrusion web"
        ),
        "target_audience": "Développeurs, testeurs QA, DevOps, équipes sécurité applicative",
    },
    {
        "code": "CCNA_CYBEROPS",
        "title": "Cisco CCNA CyberOps (CBROPS 200-201)",
        "short_description": "Certification officielle Cisco CCNA CyberOps — analyste SOC niveau 1 — 90h",
        "description": (
            "Préparation officielle à la certification Cisco CCNA CyberOps 200-201 (CBROPS). "
            "Programme accrédité Cisco NetAcad avec accès aux labs Cisco Packet Tracer. "
            "Couvre l'architecture de sécurité réseau Cisco, l'analyse du trafic réseau, "
            "la sécurité endpoint, la cryptographie appliquée, et la réponse aux incidents "
            "dans un environnement SOC Cisco. "
            "Le programme inclut un voucher d'examen officiel Cisco (Pearson VUE)."
        ),
        "type": CourseType.INTERNATIONAL,
        "partner": CoursePartner.CISCO,
        "level": CourseLevel.INTERMEDIATE,
        "hours_total": 90,
        "price_fcfa": 425000,
        "price_eur": 648.0,
        "prerequisites": "Notions réseau TCP/IP. CCNA Routing & Switching recommandé.",
        "objectives": (
            "• Comprendre l'architecture SOC Cisco\n"
            "• Analyser le trafic réseau avec Wireshark/NetFlow\n"
            "• Gérer les incidents de sécurité dans un environnement Cisco\n"
            "• Appliquer la cryptographie dans les architectures réseau\n"
            "• Utiliser Cisco IOS pour la sécurisation des équipements\n"
            "• Obtenir la certification Cisco CCNA CyberOps 200-201"
        ),
        "target_audience": "Ingénieurs réseau voulant évoluer vers la sécurité, analystes SOC débutants",
    },
    {
        "code": "NSE4",
        "title": "Fortinet NSE 4 Network Security Professional",
        "short_description": "Administration FortiGate — certification Fortinet NSE 4 — 80h",
        "description": (
            "Préparation officielle à la certification Fortinet NSE 4 (Network Security Professional). "
            "Le programme couvre l'administration complète d'un FortiGate: pare-feu, politiques de sécurité, "
            "VPN IPsec et SSL, authentification LDAP/RADIUS, antivirus FortiGuard, IPS, filtrage web, "
            "FortiManager et FortiAnalyzer, et déploiements cloud. "
            "Formation dispensée par un formateur certifié Fortinet NSE 7. "
            "Inclut un voucher d'examen officiel NSE 4 (Fortinet Training Institute)."
        ),
        "type": CourseType.INTERNATIONAL,
        "partner": CoursePartner.FORTINET,
        "level": CourseLevel.INTERMEDIATE,
        "hours_total": 80,
        "price_fcfa": 525000,
        "price_eur": 800.0,
        "prerequisites": "Expérience en administration réseau. FortiGate 7.x recommandé. Notions pare-feu.",
        "objectives": (
            "• Administrer un FortiGate 7.x en production\n"
            "• Configurer des politiques de sécurité avancées\n"
            "• Déployer des VPN IPsec et SSL-VPN\n"
            "• Analyser les logs FortiAnalyzer\n"
            "• Gérer plusieurs FortiGate via FortiManager\n"
            "• Obtenir la certification Fortinet NSE 4"
        ),
        "target_audience": "Administrateurs réseau/sécurité, ingénieurs MSSP, équipes SOC utilisant Fortinet",
    },
    {
        "code": "CDFIR",
        "title": "Certified Digital Forensics & Incident Response",
        "short_description": "Forensic numérique et réponse aux incidents — contexte juridique africain — 110h",
        "description": (
            "CDFIR forme des experts en forensic numérique et réponse aux incidents capables "
            "de travailler dans le contexte juridique africain (droit burkinabè, ivoirien, sénégalais). "
            "Le programme couvre l'acquisition légale de preuves numériques, l'analyse de disques "
            "avec Autopsy et FTK, le forensic mémoire avec Volatility, les investigations ransomware "
            "(cas réels PME burkinabè et ivoiriennes), le forensic réseau (PCAP), le forensic mobile "
            "(Android dominant en Afrique de l'Ouest), et la rédaction de rapports légaux. "
            "Cas pratique: investigation complète d'un incident ransomware sur une PME de Ouagadougou."
        ),
        "type": CourseType.ECERT,
        "partner": CoursePartner.EDEFENCE,
        "level": CourseLevel.ADVANCED,
        "hours_total": 110,
        "price_fcfa": 475000,
        "price_eur": 724.0,
        "prerequisites": "CSA + 2 ans d'expérience IT. Notions Linux avancées. Python recommandé.",
        "objectives": (
            "• Conduire une investigation forensic numérique complète\n"
            "• Acquérir des preuves numériques conformes au droit africain\n"
            "• Analyser des disques avec Autopsy/FTK et la mémoire avec Volatility\n"
            "• Investiguer des incidents ransomware dans des PME africaines\n"
            "• Analyser des appareils Android (forensic mobile)\n"
            "• Rédiger des rapports expertaux conformes aux standards juridiques locaux\n"
            "• Témoigner en tant qu'expert devant un tribunal"
        ),
        "target_audience": "Enquêteurs cyber, RSSI, équipes CERT/CSIRT, juristes spécialisés cybercriminalité",
    },
    {
        "code": "CMSP",
        "title": "Certified Malware & Security Professional",
        "short_description": "Analyse de malwares ciblant l'Afrique de l'Ouest — 90h",
        "description": (
            "CMSP forme des analystes de malwares spécialisés dans les menaces ciblant "
            "les environnements africains: banking trojans (faux applications Mobile Money), "
            "ransomwares ciblant les PME et ONG, RATs utilisés dans l'espionnage économique, "
            "et documents malveillants en français. "
            "Le programme couvre l'analyse statique (strings, imports, YARA), "
            "l'analyse dynamique dans un sandbox (Cuckoo/Any.run), "
            "le reverse engineering basique avec Ghidra, "
            "et la création d'IOCs et de règles YARA pour les SOC. "
            "Lab phare: analyse d'un banking trojan ciblant Orange Money."
        ),
        "type": CourseType.ECERT,
        "partner": CoursePartner.EDEFENCE,
        "level": CourseLevel.INTERMEDIATE,
        "hours_total": 90,
        "price_fcfa": 375000,
        "price_eur": 572.0,
        "prerequisites": "CSA ou CDFIR. Python requis. Notions assembleur x86 recommandées.",
        "objectives": (
            "• Configurer et utiliser un sandbox d'analyse (Cuckoo)\n"
            "• Conduire une analyse statique complète d'un malware\n"
            "• Analyser le comportement d'un malware avec analyse dynamique\n"
            "• Utiliser Ghidra pour du reverse engineering basique\n"
            "• Analyser des documents malveillants (PDF/Office/macro)\n"
            "• Identifier les malwares ciblant l'Afrique de l'Ouest\n"
            "• Créer des IOCs et règles YARA exploitables par un SOC"
        ),
        "target_audience": "Analystes malwares, ingénieurs réponse aux incidents, chercheurs sécurité UEMOA",
    },
]


async def seed_courses(db: AsyncSession) -> int:
    """
    Insert all 10 courses with real data from CDCD.

    Args:
        db: Async SQLAlchemy session

    Returns:
        Number of courses created or updated
    """
    count = 0

    for course_data in COURSES_DATA:
        # Check if already exists
        existing = await db.execute(
            select(Course).where(Course.code == course_data["code"])
        )
        course = existing.scalar_one_or_none()

        if course:
            # Update existing
            for key, value in course_data.items():
                if key != "code":
                    setattr(course, key, value)
            logger.info("Formation mise à jour", code=course_data["code"])
        else:
            # Create new
            course = Course(**course_data)
            db.add(course)
            logger.info("Formation créée", code=course_data["code"])
            count += 1

    await db.flush()
    logger.info("Seed formations terminé", created=count, total=len(COURSES_DATA))
    return count
