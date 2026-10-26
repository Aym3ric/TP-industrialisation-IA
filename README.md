# Livraison Express Lite

Prédiction de l'éligibilité d'une commande à la **livraison express**, à partir de ses caractéristiques (distance, poids, météo, zone, capacité du transporteur, etc.).

Ce projet transforme un prototype de notebook en petite application exploitable : un job d'entraînement, un modèle persisté, une API HTTP et une CLI.

> Pour une description détaillée de l'architecture (couches, flux de données, choix de conception), voir [ARCHITECTURE-livraison-express-lite.md](ARCHITECTURE-livraison-express-lite.md).

---

## Sommaire

- [Fonctionnalités](#fonctionnalités)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Configuration](#configuration)
- [Utilisation](#utilisation)
- [API HTTP](#api-http)
- [Structure du projet](#structure-du-projet)
- [Qualité du code](#qualité-du-code)
- [Limites connues](#limites-connues)
- [Contribuer](#contribuer)
- [Sécurité](#sécurité)
- [Licence](#licence)

---

## Fonctionnalités

| Usage | Entrée | Résultat |
|---|---|---|
| **Entraînement** | commandes synthétiques + labels | pipeline scikit-learn, métriques (MLflow), artefact `.joblib` |
| **Prédiction (API)** | une commande JSON via `POST /predict` | probabilité, décision oui/non, version du modèle, horodatage |
| **Prédiction (CLI)** | un fichier JSON | même résultat, affiché sur la sortie standard |

Principe clé : **entraîner et servir sont séparés**. L'API ne réentraîne jamais le modèle ; elle charge au démarrage l'artefact produit par le job d'entraînement.

## Prérequis

- Python **3.13** ou supérieur
- `pip` et un environnement virtuel (`venv`)
- Git

## Installation

```bash
git clone https://github.com/Aym3ric/TP-industrialisation-IA.git
cd TP-industrialisation-IA

python -m venv .venv
# Linux / macOS
source .venv/bin/activate
# Windows (PowerShell)
.venv\Scripts\Activate.ps1

pip install -r requirements.txt
```

## Configuration

La configuration est lue depuis les variables d'environnement, puis depuis un fichier `.env` (voir [`src/livraison_express_lite/config.py`](src/livraison_express_lite/config.py)).

```bash
cp .env.example .env
```

Une clé laissée vide utilise la valeur par défaut définie dans `config.py`.

| Variable | Défaut | Rôle |
|---|---|---|
| `ENVIRONMENT` | `local` | `local`, `test` ou `prod` |
| `MODEL_PATH` | `notebooks/artifacts/express_delivery_model.joblib` | chemin de l'artefact du modèle |
| `MLFLOW_MODEL_URI` | *(vide)* | URI MLflow du modèle (ex. `runs:/<run_id>/model`) |
| `MODEL_THRESHOLD` | `0.5` | seuil qui transforme la probabilité en décision |
| `MODEL_VERSION` | `1.0.0` | version du modèle exposée par l'API |
| `LOG_LEVEL` | `INFO` | `DEBUG`, `INFO`, `WARNING`, `ERROR` |

> ⚠️ Ne versionnez jamais le fichier `.env` : il est ignoré par Git. Seul `.env.example` documente le contrat de configuration.

## Utilisation

Toutes les commandes se lancent depuis la racine du dépôt.

### 1. Entraîner le modèle

```bash
python -m src.livraison_express_lite train
```

Génère des données synthétiques reproductibles (graine `42`), entraîne la pipeline, journalise les métriques dans MLflow et écrit l'artefact dans `MODEL_PATH`.

### 2. Prédire une commande en local

```bash
python -m src.livraison_express_lite predict --file order.json
```

Le fichier [`order.json`](order.json) fournit un exemple de commande.

### 3. Démarrer l'API

```bash
python -m src.livraison_express_lite serve --host 127.0.0.1 --port 8000
```

La documentation interactive est ensuite disponible sur <http://127.0.0.1:8000/docs>.

Codes de sortie de la CLI : `0` en cas de succès, `1` en cas d'échec (utile en CI).

## Docker

L'image se construit en plusieurs étapes (*multi-stage*) : une image de **test** complète installe les dépendances, lance les tests et entraîne le modèle. L'image de **production** (`python:3.13-slim`) ne reçoit que l'environnement virtuel nettoyé, le code et le modèle entraîné.

```bash
# Construire et lancer l'API (http://127.0.0.1:8000)
docker compose up --build -d

# Vérifier l'état (healthy = modèle chargé)
docker compose ps

# Arrêter
docker compose down
```

Sans Compose :

```bash
docker build -t livraison-express-lite .
docker run --rm -p 127.0.0.1:8000:8000 -e MODEL_THRESHOLD=0.6 livraison-express-lite
```

Pour construire uniquement l'image de test : `docker build --target test -t livraison-express-lite:test .`

| Mesure | Détail |
|---|---|
| **Optimisation** | build multi-stage, image de base `slim`, `.dockerignore` (pas de `.git`, docs, notebook, `.env`), couche des dépendances mise en cache, suites de tests des bibliothèques et `pip` retirés |
| **Rootless** | exécution sous l'utilisateur `app` (UID 10001), sans shell |
| **Secrets** | aucun `.env` dans l'image : la configuration passe par `-e` / `environment:` à l'exécution |
| **Ports** | seul le port `8000` est exposé, publié sur `127.0.0.1` par défaut |
| **Durcissement (Compose)** | système de fichiers en lecture seule, `cap_drop: ALL`, `no-new-privileges`, limites CPU / mémoire |
| **Supervision** | `HEALTHCHECK` sur `/health/ready` |

Taille mesurée : environ **1,8 Go** pour l'image de test et **800 Mo** pour l'image de production. Ce volume vient surtout de MLflow et de ses dépendances (pyarrow, scipy…).

## API HTTP

| Endpoint | Méthode | Description | Erreur possible |
|---|---|---|---|
| `/health` | `GET` | le processus est vivant (*liveness*) | — |
| `/health/ready` | `GET` | le modèle est chargé (*readiness*) | `503` si modèle absent |
| `/predict` | `POST` | prédit l'éligibilité d'une commande | `503` si modèle absent, `422` si payload invalide |

Exemple :

```bash
curl -X POST http://127.0.0.1:8000/predict \
  -H "Content-Type: application/json" \
  -d @order.json
```

```json
{
  "express_eligible": true,
  "decision": "oui",
  "probability": 0.8734,
  "model_version": "1.0.0",
  "prediction_timestamp": "2026-10-22T15:30:00+00:00"
}
```

## Structure du projet

```text
.
├── notebooks/                    # notebook historique (ne pas modifier)
├── src/livraison_express_lite/
│   ├── api/                      # FastAPI et endpoints
│   ├── core/                     # racine de composition + apprentissage
│   │   └── learning/             # pipeline, entraînement, prédiction, features
│   ├── domain/                   # entités métier et exceptions
│   ├── infrastructure/           # contrats et implémentations de stockage
│   ├── cli.py                    # commandes serve / train / predict
│   └── config.py                 # configuration par environnement
├── .env.example                  # contrat de configuration
├── order.json                    # exemple de commande
├── pyproject.toml
└── requirements.txt
```

## Qualité du code

```bash
pip install pytest ruff
ruff check .
pytest
```

Le notebook est volontairement exclu du linting : c'est l'artefact historique du projet et il doit rester identique.

## Limites connues

Ce projet est **pédagogique** :

- les commandes sont stockées en mémoire et perdues au redémarrage ;
- le modèle est un fichier local, sans registre ni rollback ;
- l'API n'a **ni authentification, ni autorisation, ni rate limiting** : ne pas l'exposer publiquement en l'état ;
- les données d'entraînement sont synthétiques et ne reflètent pas une vérité métier.

## Contribuer

Les contributions sont les bienvenues. Lisez [CONTRIBUTING.md](CONTRIBUTING.md) avant d'ouvrir une issue ou une pull request, et respectez le [Code de conduite](CODE_OF_CONDUCT.md).

## Sécurité

Pour signaler une vulnérabilité, **n'ouvrez pas d'issue publique** : suivez la procédure décrite dans [SECURITY.md](SECURITY.md).

## Licence

Distribué sous licence MIT. Voir [LICENSE](LICENSE).
