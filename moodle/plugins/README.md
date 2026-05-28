# Plugins Moodle — Cyber Academy E-DEFENCE

Ce répertoire contient les plugins Moodle personnalisés pour la plateforme
**Cyber Academy E-DEFENCE**. Ils sont montés dans le conteneur Moodle via
le volume Docker :

```yaml
volumes:
  - ./moodle/plugins:/bitnami/moodledata/plugins
```

---

## Plugins disponibles

### 1. `theme_cyberacademy/` — Thème personnalisé E-DEFENCE

Thème Boost enfant adapté à l'identité visuelle E-DEFENCE :
- Palette sombre (dark mode) avec accents cyan/vert
- Logo E-DEFENCE intégré
- Bannières de certification par formation
- Dashboard apprenant personnalisé avec progression

**Installation :**
```bash
cp -r theme_cyberacademy /bitnami/moodledata/plugins/theme/
# Puis dans Moodle Admin : Site administration > Appearance > Themes
```

---

### 2. `report_edefence_grades/` — Rapport de notes E-DEFENCE

Plugin de rapport personnalisé qui exporte les notes des apprenants
dans un format compatible avec le système de certification E-DEFENCE :
- Export CSV/PDF des résultats par certification
- Intégration avec le webhook FastAPI pour déclenchement des badges NFT
- Tableau de bord instructeur avec analytics par cohorte UEMOA

**Installation :**
```bash
cp -r report_edefence_grades /bitnami/moodledata/plugins/report/
# Puis dans Moodle Admin : Site administration > Reports
```

---

### 3. `local_edefence_webhook/` — Webhook FastAPI E-DEFENCE

Plugin local qui envoie des événements Moodle vers l'API FastAPI :
- `course_completed` → déclenche l'émission de badge NFT (Polygon)
- `quiz_submitted` → synchronise les scores avec la DB apprenants
- `user_enrolled` → crée le compte apprenant dans FastAPI
- `payment_confirmed` → active l'inscription au cours

**Configuration requise** (dans `config.php` ou via l'interface Admin) :
```php
$CFG->edefence_webhook_url = 'http://backend:8000/api/moodle/webhook';
$CFG->edefence_webhook_secret = 'CHANGE_ME_WEBHOOK_SECRET';
```

**Installation :**
```bash
cp -r local_edefence_webhook /bitnami/moodledata/plugins/local/
# Puis dans Moodle Admin : Site administration > Plugins > Install plugins
```

---

## Développement des plugins

Chaque plugin suit la structure standard Moodle :

```
plugin_name/
├── version.php          # Version et dépendances
├── lang/
│   ├── en/             # Chaînes anglaises
│   └── fr/             # Chaînes françaises
├── classes/            # Classes PHP (autoloaded)
├── templates/          # Templates Mustache
├── styles.css          # Styles CSS
└── README.md           # Documentation plugin
```

## Ressources

- [Moodle Plugin Development Guide](https://moodledev.io/docs/apis)
- [Moodle Plugin Directory](https://moodle.org/plugins/)
- Documentation interne E-DEFENCE : `docs/moodle-plugins.pdf`
