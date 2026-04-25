# Mise en place CI/CD GitHub Actions pour déploiement

## Plan approuvé :
**Information recueillies :**
- App Flutter web + backend Java/Spring Boot (Maven/Docker)
- Déploiement prod : docker-compose.prod.yml sur VPS 37.27.222.149 (api/nginx/mongo/redis/minio)
- nginx redirige tout vers api:8100 (Spring Boot sert le frontend web ?)
- Pas de workflows existants

**Fichiers à créer/éditer :**
- `.github/workflows/backend-ci-cd.yml`
- `.github/workflows/flutter-ci.yml`
- `.env.example`
- `backend/README.md`

**Étapes :**

- [x] Créer répertoire `.github/workflows/`
- [x] Créer workflow backend : test Maven → Flutter build → fullstack Docker → push ghcr.io → SSH VPS deploy **(amélioré fullstack)**
- [x] Créer workflow Flutter : test/build web **(optionnel maintenant)**
- [x] Créer `.env.example` pour secrets
- [x] Mettre à jour `backend/README.md` avec instructions CI/CD
- [ ] Tester workflows **(push GitHub → voir logs)**
- [x] Configurer secrets GitHub **(déjà faits d'après feedback)**

**Suivi étapes après édition :**
- Tester localement
- Push vers GitHub pour trigger workflows
- Vérifier déploiement VPS 37.27.222.149
