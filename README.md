# anais_inspection_controle
Pipeline de l'étape de InspectionControlePA de la plateforme ANAIS ou en local

# Installation & Lancement du projet DBT

Cette section décrit les étapes nécessaires pour installer les dépendances, configurer DBT, instancier la base de données si besoin, et exécuter le projet.

---

## 1. Installation des dépendances via UV

Le projet utilise [UV] pour la gestion des dépendances Python.  
Voici les étapes à suivre pour initialiser l’environnement :

```bash

# 1. Se placer dans le dossier du projet
cd chemin/vers/le/projet

# 2. Vérifier que uv est installé
uv --version
pip install uv # Si pas installé

# 3. Installer les dépendances
uv sync
```

---

## 2. ⚙️ Configuration du fichier `profiles.yml`

DBT nécessite un fichier de configuration appelé `profiles.yml`, qui contient les informations de connexion à la base de données.

### Où se trouve le fichier ?

Il doit se trouver dans le répertoire suivant :
- **Linux/macOS** : `~/.dbt/profiles.yml`
- **Windows** : `C:\Users\<VotreNom>\.dbt\profiles.yml`

> Si le dossier `.dbt` n’existe pas encore, vous pouvez le créer manuellement.  

### Où placer le fichier ?

Il doit être placé dans à la racine du projet inspection_controle (au même niveau que le README et pyproject.toml) :
- **VM Cegedim** : `~/anais_inspection_controle/profiles.yml`
- **Local** : `C:\Users\<VotreNom>\...\<projet>\profiles.yml`
 
Le fichier `profiles.yml` est disponible à la racine du repo.  


### Que contient le fichier ?

Il contient les informations relatives aux bases de données des différents projets :
- Staging (DuckDB et postegres)
- Helios (DuckDB et postegres)
- Matrice (DuckDB et postegres)
- InspectionControlePA (DuckDB et postegres)
- CertDC (DuckDB et postegres)

Seul le password des bases postgres n'est pas indiqué -> il est indiqué dans le `.env`

---
## 3. ⚙️ Configuration du fichier `metadata.yml`

Le fichier `metadata.yml` contient le paramétrage relatif aux fichiers en entrée et en sortie pour les différents projets.

Chaque projet à sa section.

### Section directory

Contient les informations relatives aux fichiers et répertoires du projet.
- local_directory_input = répertoire où sont trouvables les fichiers csv en entrée. Exemple: "input/inspection_controle_pa"
- local_directory_output = répertoire où sont enregistrés les fichiers csv en sortie. Exemple: "output/inspection_controle_pa"
- models_directory = répertoire dans lequel sont enregistrés les modèles dbt du projet. dbtInspectionControlePA" trouvable dans '/anais_inspection_controle/dbtInspectionControlePA/models/'
- create_table_directory = répertoire où sont enregistrés les fichiers SQL Create table. Exemple: 'output_sql/'
- remote_directory_input = listes des répertoires sur le SFTP où sont enregistrés les fichiers csv en entrée (pour la recette). Exemple: "/SCN_BDD/INSPECTION_CONTROLE/PA/input"
- remote_directory_output = listes des répertoires sur le SFTP où sont enregistrés les fichiers csv en sortie. Exemple: "/SCN_BDD/INSPECTION_CONTROLE/PA/output"


### Section **input_to_download**

Contient les informations relatives aux fichiers csv provenant du SFTP.
La section `input_to_download` (fichier à récupérer) contient :
- path = Chemin du fichier sur le SFTP. Exemple : "/SCN_BDD/INSERN"
- keyword = Terme dans le nom du fichier qui permet de le distinguer des autres fichiers. Exemple : "DNUM_TdB_CertDc" pour un fichier nommer DNUM_TdB_CertDcT42024T12025.csv
- file = Nom d'enregistrement du fichier une fois importé. Exemple : "sa_insern.csv"

### Section **files_to_upload**

Contient les informations relatives aux vues à exporter en csv.
La section `files_to_upload` à envoyer contient :
- nom de la vue sql (nom du modèle dbt)
- radical du nom donné au fichier csv exporté. Le nom final sera '<radical>_<date_du_jour>.csv'. 
Exemple: ods_insee: ods_insee


---
## 4. Lancement du pipeline :

L'ensemble de la Pipeline est exécuté depuis le `main.py`.

### Pour l'exécution de la pipeline:
1. Placer vous dans le bon répertoire `anais_inspection_controle`

```bash
# Placer vous dans anais_inspection_controle
cd anais_inspection_controle
```

2. Lancer le `main.py`
```bash
uv run main.py --env "local" --profile "InspectionControlePA"
```
Avec env = 'local' ou 'anais' selon votre environnement de travail
et profile = 'InspectionControlePA'

### Pipeline sur env 'local':
1. Récupération des fichiers d'input. !! Les fichiers doivent être placés manuellement dans le dossier `input/` sous format **.csv** !! (les délimiteurs sont gérés automatiquement)
2. Création de la base DuckDB si inexistante.
3. Connexion à la base DuckDB
4. Création des tables si inexistantes
5. Lecture des csv avec standardisation des colonnes (sans caractères spéciaux) -> injection des données dans les tables
6. Vérification de l'injection
7. Exécution de la commande `run dbt` -> Création des vues relatives au projet
8. Export des vues dans le dossier `output/`
9. Fermeture de la connexion à la base DuckDB

### Pipeline sur env 'anais':
1. Récupération des fichiers d'input. Ces fichiers sont récupérés automatiquement sur le SFTP et placés dans le dossier `input/` sous format **.csv** (les délimiteurs sont gérés automatiquement)
2. Création de la base Postgres si inexistante.
3. Connexion à la base Postgres
4. Création des tables si inexistantes
5. Lecture des csv avec standardisation des colonnes (sans caractères spéciaux) -> injection des données dans les tables
6. Vérification de l'injection
7. Exécution de la commande `run dbt` -> Création des vues relatives au projet
8. Export des vues dans le dossier `output/` au format **.csv**
9. Fermeture de la connexion à la base Postgres
10. Export des **.csv** en output vers le SFTP


## 5. Architecture du projet
# MonProjet

## 🏗️ Architecture du projet

```plaintext
.
├── data
│   └── duckdb_database.duckdb
├── input
│   ├── cert_dc_insern_2023_2024.csv
│   ...
│   └── v_region.csv
├── logs
│   └── sources.log
├── output
│   ├── sa_ods_insee_2025_07_09.csv
│   ...
│   └── sa_ods_pmsi_2025_07_09.csv
├── Staging
│   ├── dbtStaging
│   │   ├── dbt_project.yml
│   │   ├── logs
│   │   ├── macros
│   │   ├── models
│   │   ├── target
│   │   └── tests
│   ├── logs
│   ├── main.py
│   ├── output_sql
│   │   ├── cert_dc_insern_2023_2024.sql
│   │   ...
│   │   └── v_region.sql
│   ├── pipeline
│   │   ├── __init__.py
│   │   ├── csv_management.py
│   │   ├── database_pipeline.py
│   │   ├── duckdb_pipeline.py
│   │   ├── load_yml.py
│   │   ├── metadata.yml
│   │   ├── postgres_loader.py
│   │   └── sftp_sync.py
│   ├── staging_tables.txt
│   └── staging_views.txt
├── poetry.lock
├── profiles.yml
├── pyproject.toml
├── README.md
└── uv.lock
```

## 6. Utilités des fichiers
### ./dbtCertDC/
Répertoire de fonctionnement des modèles DBT -> création de vue SQL.

dbt_project.yml : Fichier de configuration de DBT (obligatoire)

macros/ : Répertoire de stockage des macro jinja

models/ : Répertoire de stockage des modèles dbt

### ./pipeline/
Répertoire d'orchestration de la pipeline Python.

.env : Fichier secret contenant le paramétrage vers le SFTP et les mots de passes des bases de données postgres.

database_pipeline.py : Réalise les actions communes pour n'importe quelle database (lecture de fichier SQL, exécution du fichier sql, export de vues, run de la pipeline...). Fonctionne en complément avec duckdb_pipeline.py et postgres_loader.py.

duckdb_pipeline.py : Réalise les actions spécifiques à une base (connexion à la base, création de table, chargement des données dans la BDD). Fonctionne en complément avec database_pipeline.py.

postgres_loader.py : Réalise les actions spécifiques à une base postgres (connexion à la base, création de table, chargement des données dans la BDD). Fonctionne en complément avec database_pipeline.py.

sftp_sync.py : Réalise les actions relatives à une connexion SFTP (connexion, import, export...).

csv_management.py : Réalise les actions relatives à la manipulation de fichier csv (transformation d'un .xlsx en .csv, lecture du .csv avec délimiteur personnalisé, standarisation des colonnes, conversion des types, export ...).

metadata.yml : Contient les informations relatives aux fichiers .csv provenant du SFTP.

load_yml.py : Lit un fichier .yml


./main.py : Programme d'exécution de la pipeline


./output_sql/ : Répertoire qui contient les fichiers .sql de création de table (CREATE TABLE)


./logs/ : Répertoire de la log


./data/duckdb_database.duckdb : Base duckDB


./input/ : Répertoire de stockage des fichiers .csv en entrée
./output/ : Répertoire de stockage des fichiers .csv en sortie


./profiles.yml : Contient les informations relatives aux bases des différents projets.


./poetry.lock
./uv.lock
./pyproject.toml