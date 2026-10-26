# Politique de sécurité

## Versions prises en charge

| Version | Correctifs de sécurité |
|---|---|
| `0.1.x` (branche `main`) | ✅ |
| versions antérieures | ❌ |

## Signaler une vulnérabilité

**N'ouvrez pas d'issue publique** pour une faille de sécurité : cela l'exposerait avant qu'un correctif soit disponible.

Utilisez le signalement privé de GitHub :

1. Rendez-vous dans l'onglet **Security** du dépôt : <https://github.com/Aym3ric/TP-industrialisation-IA/security>
2. Cliquez sur **Report a vulnerability**.
3. Décrivez le problème.

Votre signalement doit idéalement contenir :

- le type de vulnérabilité (injection, désérialisation, fuite de données, déni de service…) ;
- le ou les fichiers concernés et, si possible, la ligne ;
- les étapes pour reproduire (commande, requête HTTP, payload) ;
- l'impact estimé et un scénario d'exploitation ;
- une proposition de correctif si vous en avez une.

## Délais de traitement

| Étape | Délai indicatif |
|---|---|
| Accusé de réception | 3 jours ouvrés |
| Première évaluation | 7 jours ouvrés |
| Correctif ou plan d'action | 30 jours selon la gravité |

Vous serez tenu·e informé·e de l'avancement. Une fois le correctif publié, la vulnérabilité pourra être divulguée publiquement et, si vous le souhaitez, votre contribution sera créditée.

## Périmètre et limites connues

Ce projet est un **projet pédagogique**. Les points suivants sont des limites connues et documentées, pas des vulnérabilités à signaler :

- l'API n'a **ni authentification, ni autorisation, ni rate limiting** ;
- les commandes sont stockées en mémoire ;
- les données d'entraînement sont synthétiques.

**Ne déployez pas l'API sur un réseau public en l'état.**

## Bonnes pratiques pour les contributeurs

- **Secrets** : ne commitez jamais de fichier `.env`, de clé d'API, de mot de passe ou de chaîne de connexion réelle. Seul `.env.example`, sans valeur sensible, est versionné.
- **Artefacts de modèle** : un fichier `.joblib` est désérialisé avec `pickle`, ce qui peut **exécuter du code arbitraire**. Ne chargez jamais un modèle d'origine inconnue ; utilisez uniquement les artefacts produits par `python -m src.livraison_express_lite train` ou par une source de confiance.
- **Dépendances** : les versions sont figées dans `requirements.txt`. Vérifiez-les régulièrement, par exemple avec `pip-audit`, et mettez à jour celles qui présentent une vulnérabilité connue.
- **Validation des entrées** : toute donnée reçue par l'API passe par les schémas Pydantic ; ne contournez pas cette validation.
- **Journaux** : ne journalisez aucune donnée sensible (secret, donnée personnelle).
