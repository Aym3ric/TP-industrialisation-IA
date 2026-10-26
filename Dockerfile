# Construire l'image de production (cible par défaut) :
#   docker build -t livraison-express-lite .
# Construire uniquement l'image de test :
#   docker build --target test -t livraison-express-lite:test .

ARG PYTHON_VERSION=3.13

# -----------------------------------------------------------------------------
# Stage 0 — deps : dépendances de l'application dans un environnement virtuel.
# Image complète : compilateurs et en-têtes disponibles si une roue manque.
# -----------------------------------------------------------------------------
FROM python:${PYTHON_VERSION}-bookworm AS deps

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copié seul avant le code : la couche des dépendances reste en cache tant que
# requirements.txt ne change pas, même si le code change.
COPY requirements.txt .
RUN pip install -r requirements.txt

# -----------------------------------------------------------------------------
# Stage 1 — test : dépendances de test + vérifications + entraînement du modèle.
# Si une étape échoue, le build échoue : aucune image de prod n'est produite.
# -----------------------------------------------------------------------------
FROM deps AS test

WORKDIR /app

COPY requirements.txt requirements-dev.txt ./
RUN pip install -r requirements-dev.txt

# Tout le contexte filtré par .dockerignore : code, tests éventuels, order.json.
COPY . .

ENV MODEL_PATH=/app/models/express_delivery_model.joblib \
    MLFLOW_TRACKING_URI=sqlite:////tmp/mlflow.db

# Lint et tests unitaires.
RUN ruff check --no-cache . \
 && pytest -q -p no:cacheprovider

# Entraînement (graine fixe : reproductible) puis test de fumée de la prédiction.
RUN python -m src.livraison_express_lite train \
 && python -m src.livraison_express_lite predict --file order.json

# -----------------------------------------------------------------------------
# Stage 2 — slim-venv : venv nettoyé de ce qui ne sert pas à l'exécution.
# Fait dans un stage à part : les fichiers supprimés n'existent dans aucune
# couche de l'image finale (un `rm` dans l'image prod ne la réduirait pas).
# -----------------------------------------------------------------------------
FROM deps AS slim-venv

# Suites de tests embarquées par les bibliothèques (~100 Mo) et outils
# d'installation : inutiles en production, et pip serait une porte d'entrée
# pour installer des paquets dans un conteneur compromis.
# (Pas les dossiers `testing` : numpy importe numpy.testing à l'exécution.)
RUN find /opt/venv -depth -type d -name tests \
      -path '*/site-packages/*' -exec rm -rf {} + \
 && pip uninstall -y pip setuptools wheel 2>/dev/null; \
    rm -f /opt/venv/bin/pip*

# -----------------------------------------------------------------------------
# Stage 3 — prod : image minimale, utilisateur non-root, sans outils de test.
# -----------------------------------------------------------------------------
FROM python:${PYTHON_VERSION}-slim-bookworm AS prod

LABEL org.opencontainers.image.title="livraison-express-lite" \
      org.opencontainers.image.description="API de prédiction d'éligibilité à la livraison express" \
      org.opencontainers.image.source="https://github.com/Aym3ric/TP-industrialisation-IA" \
      org.opencontainers.image.licenses="MIT"

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    ENVIRONMENT=prod \
    MODEL_PATH=/app/models/express_delivery_model.joblib

# Rootless : un utilisateur système sans shell ni répertoire personnel.
# On retire aussi le pip de l'image de base : rien ne doit s'installer à l'exécution.
RUN groupadd --system --gid 10001 app \
 && useradd --system --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app \
 && rm -rf /usr/local/bin/pip* /usr/local/lib/python*/site-packages/pip*

WORKDIR /app

# Uniquement ce qui sert à l'exécution : ni requirements.txt, ni tests, ni pytest,
# ni .env, ni documentation. Les fichiers restent la propriété de root : l'utilisateur
# `app` peut les lire, pas les modifier.
COPY --from=slim-venv /opt/venv /opt/venv
COPY src/ src/
COPY --from=test /app/models/ models/

USER app

# Seul port nécessaire : l'API HTTP.
EXPOSE 8000

# Readiness : l'API répond ET le modèle est chargé. Pas de curl dans l'image slim,
# on utilise Python.
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD ["python", "-c", "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health/ready', timeout=4).status == 200 else 1)"]

# 0.0.0.0 : écouter sur l'interface du conteneur (127.0.0.1 serait injoignable de l'hôte).
CMD ["uvicorn", "src.livraison_express_lite.api.app:app", "--host", "0.0.0.0", "--port", "8000"]
