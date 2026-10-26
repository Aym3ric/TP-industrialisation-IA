# Contribuer à Livraison Express Lite

Merci de votre intérêt pour le projet ! Ce guide explique comment proposer une modification de façon efficace et cohérente avec le reste du code.

En participant, vous vous engagez à respecter le [Code de conduite](CODE_OF_CONDUCT.md).

---

## Sommaire

- [Signaler un bug](#signaler-un-bug)
- [Proposer une évolution](#proposer-une-évolution)
- [Mettre en place l'environnement](#mettre-en-place-lenvironnement)
- [Workflow Git](#workflow-git)
- [Conventions de code](#conventions-de-code)
- [Messages de commit](#messages-de-commit)
- [Tests et qualité](#tests-et-qualité)
- [Ouvrir une pull request](#ouvrir-une-pull-request)
- [Règles spécifiques au projet](#règles-spécifiques-au-projet)

---

## Signaler un bug

Avant d'ouvrir une issue, vérifiez qu'elle n'existe pas déjà. Une bonne issue contient :

- un **titre** court et précis ;
- les **étapes pour reproduire** (commande lancée, payload JSON envoyé, etc.) ;
- le **comportement attendu** et le **comportement observé** ;
- la trace d'erreur complète si elle existe ;
- votre environnement : OS, version de Python, valeur de `ENVIRONMENT`.

> Une faille de sécurité ne se signale **pas** dans une issue publique : voir [SECURITY.md](SECURITY.md).

## Proposer une évolution

Ouvrez d'abord une issue pour en discuter. Expliquez **le besoin** avant la solution : le projet suit le principe YAGNI, une capacité n'est ajoutée que lorsqu'un besoin concret la justifie.

Pour une décision structurante (nouveau repository, changement de modèle, configuration du linter…), documentez-la sous forme d'ADR dans `docs/decisions/`.

## Mettre en place l'environnement

```bash
git clone https://github.com/Aym3ric/TP-industrialisation-IA.git
cd TP-industrialisation-IA
python -m venv .venv
source .venv/bin/activate        # Windows : .venv\Scripts\Activate.ps1
pip install -r requirements.txt
pip install pytest ruff
cp .env.example .env
```

Vérifiez ensuite que tout fonctionne :

```bash
python -m src.livraison_express_lite train
python -m src.livraison_express_lite predict --file order.json
```

## Workflow Git

1. Créez une branche à partir de `main` à jour :

   ```bash
   git switch main
   git pull
   git switch -c <type>/<description-courte>
   ```

   Exemples : `feat/sqlite-order-repository`, `fix/predict-missing-model`, `docs/readme-api`.

2. Faites des commits petits et cohérents.
3. Poussez la branche et ouvrez une pull request vers `main`.

On ne pousse **jamais** directement sur `main`.

## Conventions de code

- Python **3.13**, longueur de ligne maximale **100** caractères.
- Respectez l'architecture en couches décrite dans [ARCHITECTURE-livraison-express-lite.md](ARCHITECTURE-livraison-express-lite.md) :
  - `domain` ne dépend ni de FastAPI, ni de pandas, ni de l'infrastructure ;
  - les services ML dépendent des **contrats** (`OrderRepository`, `ModelRepository`), pas des implémentations ;
  - le choix des implémentations concrètes se fait dans `core/core.py`.
- Noms explicites, fonctions courtes orientées vers une action.
- Docstrings en français, qui expliquent le **pourquoi** et les limites, pas seulement le quoi.
- Aucune valeur de configuration (chemin, seuil, URL, secret) écrite en dur : passez par `config.py` et documentez la clé dans `.env.example`.

## Messages de commit

Le projet suit [Conventional Commits](https://www.conventionalcommits.org/fr/) :

```text
<type>(<portée optionnelle>): <description à l'impératif>
```

| Type | Usage |
|---|---|
| `feat` | nouvelle fonctionnalité |
| `fix` | correction de bug |
| `docs` | documentation uniquement |
| `refactor` | restructuration sans changement de comportement |
| `test` | ajout ou correction de tests |
| `chore` | maintenance (dépendances, configuration) |

Exemples :

```text
feat(api): ajouter la validation des plages de distance_km
fix(cli): renvoyer 1 quand le modèle est introuvable
docs: documenter MODEL_THRESHOLD dans le README
```

## Tests et qualité

Avant chaque pull request :

```bash
ruff check .
pytest
```

- Tout nouveau comportement est accompagné d'un test.
- Toute correction de bug est accompagnée d'un test qui échouait avant la correction.
- Pour tester une orchestration, préférez une doublure (faux modèle, repository en mémoire) à un vrai entraînement coûteux.

## Ouvrir une pull request

Votre PR doit :

- avoir un titre au format Conventional Commits ;
- décrire **ce qui change** et **pourquoi** ;
- référencer l'issue concernée (`Closes #12`) ;
- passer `ruff check .` et `pytest` ;
- mettre à jour la documentation (README, `.env.example`, architecture) si nécessaire.

Checklist à copier dans la description :

```markdown
- [ ] `ruff check .` passe
- [ ] `pytest` passe
- [ ] Tests ajoutés ou mis à jour
- [ ] Documentation mise à jour
- [ ] Aucun secret ni fichier `.env` commité
```

Au moins une relecture approuvée est nécessaire avant la fusion.

## Règles spécifiques au projet

- **Ne modifiez pas le notebook** `notebooks/` : c'est l'artefact historique du projet, il doit rester identique octet pour octet.
- **Les features sont un contrat** : `FEATURE_COLUMNS` est défini une seule fois dans `core/learning/order_feature.py`. Renommer une feature impose de mettre à jour l'entité, l'API, l'entraînement et les tests dans la même PR.
- **La cible n'est jamais une feature**, et `order_id` non plus.
- **Ne commitez pas d'artefacts** (`*.joblib`, `artifacts/`) : ils se régénèrent avec `train`.
- **Pas d'endpoint d'entraînement** : l'entraînement reste un job CLI.
- Ajouter une dépendance doit être justifié dans la PR et répercuté dans `requirements.txt`.

Merci pour votre contribution !
