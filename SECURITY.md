# Politique de sécurité

Ce document décrit comment signaler une vulnérabilité, quelles versions reçoivent des correctifs, dans quels délais, et comment les vulnérabilités sont identifiées.

---

## Sommaire

1. [Signaler une vulnérabilité](#1-signaler-une-vulnérabilité)
2. [Versions et durée de vie](#2-versions-et-durée-de-vie)
3. [Délais de correction](#3-délais-de-correction)
4. [Numérotation des vulnérabilités (CVE)](#4-numérotation-des-vulnérabilités-cve)
5. [Périmètre et limites connues](#5-périmètre-et-limites-connues)
6. [Bonnes pratiques pour les contributeurs](#6-bonnes-pratiques-pour-les-contributeurs)

---

## 1. Signaler une vulnérabilité

**N'ouvrez jamais d'issue publique, de pull request ou de discussion** pour une faille de sécurité : cela l'exposerait avant qu'un correctif soit disponible.

### Procédure

Utilisez le signalement privé de GitHub :

1. Rendez-vous dans l'onglet **Security** du dépôt : <https://github.com/Aym3ric/TP-industrialisation-IA/security>
2. Cliquez sur **Report a vulnerability**.
3. Remplissez le formulaire.

Le signalement n'est visible que par vous et les responsables du projet.

### Contenu attendu

- le type de vulnérabilité (injection, désérialisation, fuite de données, déni de service…) ;
- le ou les fichiers concernés et, si possible, la ligne ;
- la version ou le commit concerné ;
- les étapes pour reproduire (commande, requête HTTP, payload) ;
- l'impact estimé et un scénario d'exploitation ;
- une proposition de correctif si vous en avez une.

### Divulgation coordonnée

Nous appliquons une **divulgation coordonnée** :

1. vous signalez la faille en privé ;
2. nous la confirmons et développons un correctif, en vous tenant informé·e ;
3. le correctif est publié dans une nouvelle version ;
4. l'avis de sécurité est rendu public, et vous êtes crédité·e si vous le souhaitez.

Merci de ne pas divulguer la faille publiquement avant la publication du correctif, ou au plus tard **90 jours** après votre signalement.

---

## 2. Versions et durée de vie

### Numérotation des versions

Le projet suit le [versionnage sémantique](https://semver.org/lang/fr/) `MAJEUR.MINEUR.CORRECTIF` :

| Changement | Exemple | Signification |
|---|---|---|
| **Majeur** | `1.0.0` → `2.0.0` | changement incompatible (API, contrat des features…) |
| **Mineur** | `1.0.0` → `1.1.0` | nouvelle fonctionnalité compatible |
| **Correctif** | `1.0.0` → `1.0.1` | correction de bug ou de sécurité |

Les correctifs de sécurité sont toujours publiés dans une **version de correctif**, sans changement incompatible.

### Cycle de vie

À la manière de [endoflife.date](https://endoflife.date/), chaque version mineure passe par trois phases :

| Phase | Durée | Contenu |
|---|---|---|
| **Support actif** | jusqu'à la sortie de la version mineure suivante | correctifs de bugs et de sécurité |
| **Support sécurité** | 6 mois après la sortie de la version mineure suivante | correctifs de sécurité uniquement |
| **Fin de vie (EOL)** | ensuite | plus aucun correctif : mettez à jour |

### Versions prises en charge

| Version | Sortie | Support actif | Support sécurité | Statut |
|---|---|---|---|---|
| `0.1.x` | 2026-10 | ✅ en cours | ✅ en cours | **Prise en charge** |
| `< 0.1` | — | ❌ | ❌ | Fin de vie |

> Tant que le projet est en version `0.x`, il est considéré comme instable : seule la **dernière** version mineure reçoit des correctifs.

### Dépendances

Le projet dépend lui-même de composants qui ont leur propre fin de vie. Une version du projet n'est plus prise en charge si elle exige un composant en fin de vie :

| Composant | Version utilisée | Fin de vie |
|---|---|---|
| Python | 3.13 | voir <https://endoflife.date/python> |
| FastAPI, scikit-learn, pandas, MLflow | voir `requirements.txt` | suivies via les avis de sécurité GitHub (Dependabot) |

---

## 3. Délais de correction

La gravité est évaluée avec le score **CVSS v4.0** ([calculateur FIRST](https://www.first.org/cvss/calculator/4-0)).

### Délais de réponse

| Étape | Délai |
|---|---|
| Accusé de réception | **3 jours ouvrés** |
| Confirmation et évaluation de la gravité | **7 jours ouvrés** |

### Délais de correction selon la gravité

| Gravité | Score CVSS | Délai maximal de correction |
|---|---|---|
| 🔴 **Critique** | 9.0 – 10.0 | **7 jours** |
| 🟠 **Élevée** | 7.0 – 8.9 | **30 jours** |
| 🟡 **Moyenne** | 4.0 – 6.9 | **60 jours** |
| 🟢 **Faible** | 0.1 – 3.9 | **90 jours** ou prochaine version mineure |

Les délais courent à partir de la confirmation de la vulnérabilité. Si un délai ne peut pas être tenu, la personne qui a signalé la faille en est informée, avec une mesure de contournement lorsque c'est possible.

---

## 4. Numérotation des vulnérabilités (CVE)

Chaque vulnérabilité confirmée reçoit des identifiants publics, pour que les utilisateurs et les outils d'analyse (Dependabot, `pip-audit`…) puissent la suivre.

| Identifiant | Format | Attribué par |
|---|---|---|
| **GHSA** (GitHub Security Advisory) | `GHSA-xxxx-xxxx-xxxx` | GitHub, dès la création de l'avis de sécurité |
| **CVE** (Common Vulnerabilities and Exposures) | `CVE-AAAA-NNNNN` | GitHub, qui est une autorité de numérotation (CNA) agréée par le programme [CVE de MITRE](https://www.cve.org/) |

### Processus

1. Un **avis de sécurité privé** (GHSA) est créé dans l'onglet *Security* du dépôt.
2. Le correctif est développé dans un fork privé temporaire lié à l'avis.
3. Un **identifiant CVE** est demandé à GitHub depuis l'avis.
4. À la publication du correctif, l'avis est rendu public : il mentionne le CVE, les versions affectées, la version corrigée, le score CVSS et les crédits.
5. Le CVE est alors référencé dans la base [NVD](https://nvd.nist.gov/) et dans la [GitHub Advisory Database](https://github.com/advisories).

Les notes de version qui contiennent un correctif de sécurité indiquent toujours l'identifiant CVE correspondant, par exemple :

```text
0.1.1 — security: valider la taille du payload de /predict (CVE-2026-XXXXX, gravité moyenne)
```

---

## 5. Périmètre et limites connues

Ce projet est un **projet pédagogique**. Les points suivants sont des limites connues et documentées, pas des vulnérabilités à signaler :

- l'API n'a **ni authentification, ni autorisation, ni rate limiting** ;
- les commandes sont stockées en mémoire ;
- les données d'entraînement sont synthétiques.

**Ne déployez pas l'API sur un réseau public en l'état.**

Sont en revanche dans le périmètre : exécution de code arbitraire, contournement de la validation des entrées, fuite de secrets ou de configuration, plantage du service par une requête forgée, vulnérabilité d'une dépendance exploitable via le projet.

---

## 6. Bonnes pratiques pour les contributeurs

- **Secrets** : ne commitez jamais de fichier `.env`, de clé d'API, de mot de passe ou de chaîne de connexion réelle. Seul `.env.example`, sans valeur sensible, est versionné.
- **Artefacts de modèle** : un fichier `.joblib` est désérialisé avec `pickle`, ce qui peut **exécuter du code arbitraire**. Ne chargez jamais un modèle d'origine inconnue ; utilisez uniquement les artefacts produits par `python -m src.livraison_express_lite train` ou par une source de confiance.
- **Dépendances** : les versions sont figées dans `requirements.txt`. Vérifiez-les régulièrement avec `pip-audit` et mettez à jour celles qui présentent une vulnérabilité connue.
- **Validation des entrées** : toute donnée reçue par l'API passe par les schémas Pydantic ; ne contournez pas cette validation.
- **Journaux** : ne journalisez aucune donnée sensible (secret, donnée personnelle).
