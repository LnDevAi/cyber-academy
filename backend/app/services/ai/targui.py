"""TARGUI AI tutor service — RAG-powered cybersecurity assistant."""
import json
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

import anthropic
import structlog
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import Chroma
from langchain_anthropic import ChatAnthropic
from langchain.schema import Document

from app.core.config import settings

logger = structlog.get_logger(__name__)

# ── Course summaries for RAG corpus ─────────────────────────────────────────

COURSE_DOCUMENTS = [
    Document(
        page_content="""
        CACP — Certified Associate in Cybersecurity Practice (40h, Niveau: Débutant)
        Ce programme initie aux fondamentaux de la cybersécurité dans le contexte UEMOA.
        Modules: Cybersécurité 101, Phishing & Ingénierie sociale en Afrique de l'Ouest,
        Sécurisation des postes de travail, Gestion des mots de passe et authentification,
        Bases des réseaux TCP/IP, Sensibilisation à la protection des données personnelles RGPD/PDCP-UEMOA.
        Compétences: identifier les menaces courantes, appliquer les bonnes pratiques de cyberhygiène,
        réaliser une sensibilisation basique en entreprise.
        Partenaire: E-DEFENCE. Prix: 75 000 FCFA.
        """,
        metadata={"course_code": "CACP", "type": "course_summary"}
    ),
    Document(
        page_content="""
        CSA — Certified Security Analyst (80h, Niveau: Intermédiaire)
        Formation d'analyste SOC orientée menaces africaines et plateformes SIEM open source.
        Modules: Architecture SOC & gestion des incidents, Analyse de logs avec Wazuh/ELK,
        Threat Intelligence UEMOA (malwares, ransomwares ciblant la CEMAC/UEMOA),
        Forensic numérique niveau 1, Gestion des alertes SIEM, Rapports d'incidents,
        Exercice pratique de réponse à incident.
        Compétences: Déployer et administrer Wazuh, analyser des logs SIEM, qualifier des alertes,
        rédiger des rapports d'incidents en français.
        Partenaire: E-DEFENCE. Prix: 175 000 FCFA.
        """,
        metadata={"course_code": "CSA", "type": "course_summary"}
    ),
    Document(
        page_content="""
        CDPO_UEMOA — Certified Data Protection Officer UEMOA (120h, Niveau: Intermédiaire)
        Préparation à la certification DPO reconnue dans l'espace UEMOA, avec focus sur
        les réglementations locales: PDCP-CI, PDCP-SN, lois protection données du Burkina, Mali, Niger.
        Modules: RGPD vs réglementations UEMOA, Cartographie des traitements, AIPD/PIA,
        Contrats sous-traitants, Gestion des violations de données, Droits des personnes,
        Politique de confidentialité adaptée au contexte africain.
        Compétences: Exercer la fonction de DPO dans une organisation UEMOA,
        conduire des audits conformité, piloter la mise en conformité PDCP.
        Partenaire: PECB. Prix: 425 000 FCFA.
        """,
        metadata={"course_code": "CDPO_UEMOA", "type": "course_summary"}
    ),
    Document(
        page_content="""
        ISO27001_LI — ISO 27001 Lead Implementer (100h, Niveau: Avancé)
        Certification internationale PECB pour la mise en œuvre d'un SMSI conforme ISO 27001:2022.
        Modules: Introduction SMSI et ISO 27001:2022, Planification et périmètre,
        Évaluation des risques (ISO 27005), Sélection et mise en œuvre des contrôles (Annexe A),
        Gestion documentaire, Audit interne SMSI, Revue de direction, Amélioration continue.
        Compétences: Planifier, implémenter et gérer un SMSI ISO 27001,
        préparer une organisation à la certification tierce partie.
        Partenaire: PECB. Prix: 650 000 FCFA.
        """,
        metadata={"course_code": "ISO27001_LI", "type": "course_summary"}
    ),
    Document(
        page_content="""
        CLEH_SAHEL — Certified Lead Ethical Hacker SAHEL Edition (160h, Niveau: Avancé)
        Hacking éthique adapté aux infrastructures des PME et administrations de la zone Sahel.
        Modules: Reconnaissance et OSINT (cibles africaines), Scanning avec Nmap/Nessus,
        Exploitation Metasploit — environnements Windows Server locaux,
        Web application hacking (injections SQL, XSS sur apps locales),
        Attaques sur réseaux Wi-Fi Orange/Moov/Wave, Social engineering UEMOA,
        Rédaction de rapports de pentest en français, Aspects légaux Burkina/CI/Sénégal.
        Compétences: Conduire un pentest complet, rédiger un rapport professionnel,
        respecter le cadre légal africain.
        Partenaires: PECB / EC-COUNCIL. Prix: 750 000 FCFA.
        """,
        metadata={"course_code": "CLEH_SAHEL", "type": "course_summary"}
    ),
    Document(
        page_content="""
        WASO — Web Application Security Operator (100h, Niveau: Intermédiaire)
        Sécurité des applications web avec focus sur les vulnérabilités courantes dans les fintech
        et e-commerce UEMOA (Mobile Money API, portails bancaires locaux).
        Modules: OWASP Top 10, Injections SQL sur SGBD africains, XSS/CSRF,
        Sécurité des API REST Mobile Money (CinetPay, Orange API, Wave API),
        Tests de sécurité avec Burp Suite, Remédiation et hardening,
        DevSecOps — intégration sécurité dans CI/CD.
        Compétences: Tester la sécurité d'une application web, utiliser Burp Suite,
        corriger les vulnérabilités OWASP dans du code Python/PHP/Node.js.
        Partenaire: E-DEFENCE. Prix: 350 000 FCFA.
        """,
        metadata={"course_code": "WASO", "type": "course_summary"}
    ),
    Document(
        page_content="""
        CCNA_CYBEROPS — Cisco CCNA CyberOps (90h, Niveau: Intermédiaire)
        Préparation officielle à la certification Cisco CCNA CyberOps 200-201 (CBROPS).
        Modules: Architecture de sécurité réseau, Analyse du trafic réseau,
        Hôte et endpoint security, Analyse des menaces et réponse aux incidents,
        Cryptographie appliquée, Évaluation des vulnérabilités réseau,
        Laboratoires Cisco Packet Tracer et IOS.
        Compétences: Monitorer et analyser la sécurité d'un réseau Cisco,
        répondre aux incidents dans un environnement SOC Cisco.
        Partenaire: CISCO. Prix: 425 000 FCFA. Inclut voucher examen Cisco.
        """,
        metadata={"course_code": "CCNA_CYBEROPS", "type": "course_summary"}
    ),
    Document(
        page_content="""
        NSE4 — Fortinet NSE 4 Network Security Professional (80h, Niveau: Intermédiaire)
        Préparation officielle à la certification Fortinet NSE 4.
        Modules: Administration FortiGate, Politiques de pare-feu, VPN IPsec/SSL,
        Authentification et contrôle d'accès, Antivirus/IPS/Web Filtering FortiGuard,
        Haute disponibilité FortiGate, FortiManager et FortiAnalyzer,
        Déploiement en environnement cloud.
        Compétences: Administrer un FortiGate, configurer VPN et politiques de sécurité,
        analyser les logs FortiAnalyzer.
        Partenaire: FORTINET. Prix: 525 000 FCFA. Inclut voucher NSE 4.
        """,
        metadata={"course_code": "NSE4", "type": "course_summary"}
    ),
    Document(
        page_content="""
        CDFIR — Certified Digital Forensics & Incident Response (110h, Niveau: Avancé)
        Forensic numérique et réponse aux incidents orienté contexte africain.
        Modules: Fondamentaux du forensic numérique, Acquisition de preuves légales,
        Analyse de disques (Autopsy, FTK), Forensic mémoire (Volatility),
        Investigation de ransomwares (cas PME burkinabè et ivoiriennes),
        Forensic réseau et analyse PCAP, Forensic mobile (Android dominant en Afrique de l'Ouest),
        Rédaction de rapports légaux conformes aux droits burkinabè/ivoirien/sénégalais,
        Témoignage d'expert.
        Compétences: Conduire une investigation forensic, préparer des preuves numériques légales,
        présenter les conclusions devant un tribunal.
        Partenaire: E-DEFENCE. Prix: 475 000 FCFA.
        """,
        metadata={"course_code": "CDFIR", "type": "course_summary"}
    ),
    Document(
        page_content="""
        CMSP — Certified Malware & Security Professional (90h, Niveau: Intermédiaire)
        Analyse de malwares ciblant les environnements africains (banking trojans, RATs, ransomwares).
        Modules: Introduction à l'analyse de malwares, Configuration sandbox (Cuckoo/Any.run),
        Analyse statique (strings, imports, signature), Analyse dynamique (comportement réseau/FS),
        Reverse engineering basique (Ghidra), Analyse de documents malveillants (PDF/Office),
        Malwares spécifiques Afrique de l'Ouest (faux Mobile Money, SMS frauduleux),
        Création d'IOCs et règles YARA.
        Compétences: Analyser un malware inconnu, créer des IOCs, rédiger un rapport d'analyse.
        Partenaire: E-DEFENCE. Prix: 375 000 FCFA.
        """,
        metadata={"course_code": "CMSP", "type": "course_summary"}
    ),
    Document(
        page_content="""
        Contexte cybersécurité UEMOA / Afrique de l'Ouest:
        L'Union Économique et Monétaire Ouest Africaine (UEMOA) regroupe 8 pays:
        Burkina Faso, Côte d'Ivoire, Mali, Niger, Sénégal, Togo, Bénin, Guinée-Bissau.
        Monnaie commune: Franc CFA (XOF). Mobile Money dominant: Orange Money, Moov Money, Wave.
        Menaces principales: ransomwares ciblant les banques, fraude Mobile Money,
        phishing en français/mooré/bambara, attaques sur les e-administrations.
        Cadre légal: Loi 045-2009 Burkina, Loi 2008-12 Sénégal, loi CI sur la cybercriminalité.
        E-DEFENCE est basée à Ouagadougou, Burkina Faso.
        """,
        metadata={"course_code": "ALL", "type": "context"}
    ),
]


class TARGUIService:
    """TARGUI — Tuteur IA RAG pour Cyber Academy E-DEFENCE."""

    SYSTEM_PROMPT = """Tu es TARGUI, le tuteur IA de Cyber Academy E-DEFENCE, une plateforme de formation en cybersécurité pour l'espace UEMOA (Afrique de l'Ouest).

Ton rôle:
- Aider les apprenants à comprendre les concepts de cybersécurité
- Guider les étudiants dans leurs labs pratiques sans donner les réponses directement
- Expliquer les réglementations de protection des données africaines (PDCP, RGPD adapté)
- Donner des exemples concrets du contexte africain (Mobile Money, réseaux locaux, menaces régionales)
- Répondre principalement en français, avec des termes techniques en anglais quand nécessaire
- Être encourageant et pédagogique

Tu as accès aux documents de cours via RAG. Utilise ces informations pour fournir des réponses précises et contextualisées.

Important: Ne donne jamais directement les mots de passe, flags ou solutions complètes des labs. Guide l'apprenant par des questions socratiques et des indices progressifs."""

    def __init__(self):
        self.client = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)
        self.model = settings.TARGUI_MODEL
        self._vectorstore: Optional[Chroma] = None
        self._initialized = False

    def _get_vectorstore(self) -> Chroma:
        """Lazy-initialize ChromaDB vector store with course documents."""
        if self._vectorstore is not None:
            return self._vectorstore

        try:
            from langchain_anthropic import AnthropicEmbeddings
            # Use simple text embedding approach with ChromaDB
            from chromadb import Client
            from chromadb.config import Settings as ChromaSettings

            splitter = RecursiveCharacterTextSplitter(
                chunk_size=1000,
                chunk_overlap=200,
            )
            all_docs = splitter.split_documents(COURSE_DOCUMENTS)

            # Use Chroma with in-memory store for simplicity
            self._vectorstore = Chroma.from_documents(
                documents=all_docs,
                embedding=self._get_embeddings(),
                collection_name="cyber_academy_courses",
            )
            logger.info("ChromaDB vectorstore initialisé", doc_count=len(all_docs))
        except Exception as exc:
            logger.warning("ChromaDB unavailable, using fallback", error=str(exc))
            self._vectorstore = None

        return self._vectorstore

    def _get_embeddings(self):
        """Get embedding function — uses sentence-transformers as fallback."""
        try:
            from langchain_community.embeddings import FakeEmbeddings
            # Use FakeEmbeddings for development; replace with real embeddings in production
            return FakeEmbeddings(size=1536)
        except Exception:
            return None

    def _retrieve_context(self, query: str, course_code: Optional[str] = None) -> str:
        """Retrieve relevant documents from ChromaDB for the query."""
        try:
            vectorstore = self._get_vectorstore()
            if vectorstore is None:
                return self._get_static_context(course_code)

            filter_dict = {}
            if course_code:
                filter_dict = {"course_code": {"$in": [course_code, "ALL"]}}

            docs = vectorstore.similarity_search(query, k=3, filter=filter_dict if filter_dict else None)
            if docs:
                return "\n\n".join([d.page_content for d in docs])
        except Exception as exc:
            logger.warning("Erreur RAG retrieval", error=str(exc))

        return self._get_static_context(course_code)

    def _get_static_context(self, course_code: Optional[str] = None) -> str:
        """Fallback: return static course context."""
        if not course_code:
            return COURSE_DOCUMENTS[-1].page_content

        for doc in COURSE_DOCUMENTS:
            if doc.metadata.get("course_code") == course_code:
                return doc.page_content

        return COURSE_DOCUMENTS[-1].page_content

    def _get_history_context(self, session_id: str, limit: int = 6) -> List[Dict]:
        """Retrieve recent chat history for context (simplified in-memory)."""
        # In production, fetch from DB. Here we return empty for stateless calls.
        return []

    async def chat(
        self,
        user_message: str,
        session_id: str,
        context: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Main chat method — RAG-augmented response from TARGUI."""
        course_code = context.get("course_code") if context else None
        lab_id = context.get("lab_id") if context else None

        # Retrieve relevant context
        rag_context = self._retrieve_context(user_message, course_code)

        # Build context string
        context_parts = [f"Contexte RAG:\n{rag_context}"]
        if lab_id:
            context_parts.append(f"Lab actif: {lab_id}")
        if course_code:
            context_parts.append(f"Formation en cours: {course_code}")

        context_str = "\n\n".join(context_parts)

        # Build messages for Claude
        messages = [
            {
                "role": "user",
                "content": f"{context_str}\n\nQuestion de l'apprenant: {user_message}",
            }
        ]

        try:
            response = self.client.messages.create(
                model=self.model,
                max_tokens=2048,
                system=self.SYSTEM_PROMPT,
                messages=messages,
            )

            assistant_message = response.content[0].text
            input_tokens = response.usage.input_tokens
            output_tokens = response.usage.output_tokens

            logger.info(
                "TARGUI réponse générée",
                session_id=session_id,
                input_tokens=input_tokens,
                output_tokens=output_tokens,
            )

            return {
                "response": assistant_message,
                "model": self.model,
                "input_tokens": input_tokens,
                "output_tokens": output_tokens,
                "sources": [doc.metadata.get("course_code", "context") for doc in COURSE_DOCUMENTS[:3]],
            }

        except anthropic.APIError as exc:
            logger.error("Erreur API Anthropic", error=str(exc))
            raise RuntimeError(f"Erreur du tuteur IA: {str(exc)}")

    async def get_hint(self, lab_id: str, user_action: str) -> Dict[str, Any]:
        """Provide a contextual hint for a lab exercise without giving the answer."""
        lab_context = self._get_static_context(lab_id.split("-")[0].upper() if lab_id else None)

        prompt = f"""Un apprenant travaille sur le lab: {lab_id}
Voici ce qu'il vient de faire/essayer: {user_action}

Fournis un indice pédagogique progressif qui:
1. Valide ce qu'il fait correctement
2. Oriente vers la prochaine étape sans donner la solution
3. Rappelle les concepts clés pertinents
4. Pose une question socratique pour guider la réflexion

Contexte du cours: {lab_context}

Réponds en 3-5 phrases, en français."""

        response = self.client.messages.create(
            model=self.model,
            max_tokens=512,
            system=self.SYSTEM_PROMPT,
            messages=[{"role": "user", "content": prompt}],
        )

        return {
            "hint": response.content[0].text,
            "confidence": 0.85,
            "related_concepts": ["Sécurité réseau", "Analyse de vulnérabilités"],
        }

    async def generate_quiz(
        self, course_code: str, topic: str, n_questions: int = 5
    ) -> List[Dict[str, Any]]:
        """Generate practice quiz questions for a course topic."""
        course_context = self._get_static_context(course_code)

        prompt = f"""Génère {n_questions} questions QCM de révision pour la formation {course_code}, sur le thème: {topic}.

Contexte du cours: {course_context}

Pour chaque question, fournis:
- La question
- 4 options de réponse (A, B, C, D)
- L'index de la bonne réponse (0=A, 1=B, 2=C, 3=D)
- Une explication de la bonne réponse

Réponds en JSON valide avec ce format:
[
  {{
    "question": "...",
    "options": ["A: ...", "B: ...", "C: ...", "D: ..."],
    "correct_answer": 0,
    "explanation": "..."
  }}
]"""

        response = self.client.messages.create(
            model=self.model,
            max_tokens=2000,
            system="Tu es un expert en cybersécurité qui crée des QCM pédagogiques en français pour des formations certifiantes. Réponds uniquement en JSON valide.",
            messages=[{"role": "user", "content": prompt}],
        )

        try:
            # Extract JSON from response
            text = response.content[0].text.strip()
            if "```json" in text:
                text = text.split("```json")[1].split("```")[0]
            elif "```" in text:
                text = text.split("```")[1].split("```")[0]
            return json.loads(text)
        except (json.JSONDecodeError, IndexError) as exc:
            logger.error("Erreur parsing quiz JSON", error=str(exc))
            return []

    async def explain_concept(
        self, concept: str, course_code: Optional[str] = None
    ) -> Dict[str, Any]:
        """Explain a cybersecurity concept with examples adapted to UEMOA context."""
        context = self._retrieve_context(concept, course_code)

        prompt = f"""Explique le concept de cybersécurité suivant: {concept}

Contexte du cours: {context}

Fournis:
1. Une définition claire et concise
2. 2-3 exemples concrets du contexte africain/UEMOA
3. Pourquoi c'est important dans la pratique
4. Les erreurs courantes à éviter

Réponds en JSON avec: explanation (str), examples (list[str]), related_topics (list[str]), references (list[str])"""

        response = self.client.messages.create(
            model=self.model,
            max_tokens=1500,
            system=self.SYSTEM_PROMPT,
            messages=[{"role": "user", "content": prompt}],
        )

        try:
            text = response.content[0].text.strip()
            if "```json" in text:
                text = text.split("```json")[1].split("```")[0]
            elif "```" in text:
                text = text.split("```")[1].split("```")[0]
            data = json.loads(text)
        except (json.JSONDecodeError, IndexError):
            data = {
                "explanation": response.content[0].text,
                "examples": [],
                "related_topics": [],
                "references": [],
            }

        return data


# Singleton instance
targui_service = TARGUIService()
