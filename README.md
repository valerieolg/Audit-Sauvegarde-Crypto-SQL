# Audit, Sauvegarde et Crypto SQL

---

## Table des matières

1. [Description du projet](#description-du-projet)
2. [Structure du projet](#structure-du-projet)
3. [Prérequis](#prérequis)
4. [Installation et configuration](#installation-et-configuration)
5. [Exécution des scripts](#exécution-des-scripts)
   - [1. Création de la base de données](#1-création-de-la-base-de-données)
   - [2. Gestion des rôles et profils](#2-gestion-des-rôles-et-profils)
   - [3. Audit](#3-audit)
   - [4. Chiffrement avec DBMS_CRYPTO](#4-chiffrement-avec-dbms_crypto)
   - [5. Sauvegarde et restauration](#5-sauvegarde-et-restauration)
6. [Tests de validation](#tests-de-validation)
7. [Dépannage](#dépannage)
8. [Livrables](#livrables)

---

## Description du projet

Ce projet implémente une solution complète de gestion de base de données Oracle avec les fonctionnalités suivantes :

| Section | Description |
|---------|-------------|
| **1. Création de la base de données** | Création des tables DEPARTEMENTS, EMPLOYES, PROJETS avec contraintes d'intégrité et insertion de données de test |
| **2. Gestion des rôles et profils** | Création de rôles (GESTIONNAIRE_PROJET, GESTIONNAIRE_DEPARTEMENT, ADMINISTRATEUR_DB) et profils de sécurité |
| **3. Audit unifié** | Politiques d'audit pour tracer les connexions et les modifications sur les tables sensibles |
| **4. Chiffrement AES-128** | Chiffrement de la table PROJETS avec DBMS_CRYPTO et gestion des clés par projet |
| **5. Sauvegarde et restauration** | Backup logique avec Oracle Data Pump et scripts automatisés |

---

## Structure du projet

```
Audit-Sauvegarde-Crypto-SQL/
│
├── README.md                                   
│
├── TP2.docx                                    # Rapport complet du projet
│
└── scripts/
    ├── sql/
    │   ├── 01_creation_base.sql                # Création BD, tables et données
    │   ├── 02_roles_profils.sql                # Rôles, utilisateurs et profils
    │   ├── 03_audit.sql                        # Politiques d'audit unifié
    │   ├── 04_crypto.sql                       # Chiffrement DBMS_CRYPTO
    │   └── 05_sauvegarde.sql                   # Backup/restore Data Pump
    │
    └── backup/
         ├── export_script.sh                    # Script de sauvegarde automatique
         └── import_script.sh                    # Script de restauration automatique

```

---

### Prérequis

Avant d'exécuter ce projet, assurez-vous d'avoir :

| Prérequis | Détails |
|-----------|---------|
| **Oracle Database** | Version 19c ou supérieure |
| **PDB** | Base de données `freepdb1` |
| **Accès SYSDBA** | Pour la création des utilisateurs et rôles |
| **Espace disque** | Minimum 500 MB pour les sauvegardes |
| **Système d'exploitation** | Oracle Linux / RHEL (pour les scripts shell) |

### Vérification de l'environnement

```bash
# Vérifier que la PDB est accessible
sqlplus sys/oracle@localhost:1521/freepdb1 as sysdba

# Vérifier les tablespaces disponibles
SELECT TABLESPACE_NAME, STATUS FROM DBA_TABLESPACES;
```

---

## Installation et configuration

### Étape 1 : Cloner le dépôt

```bash
# Cloner le dépôt GitHub
git clone https://github.com/valerieolg/Audit-Sauvegarde-Crypto-SQL.git

# Entrer dans le dossier
cd Audit-Sauvegarde-Crypto-SQL
```

### Étape 2 : Rendre les scripts exécutables

```bash
# Donner les droits d'exécution aux scripts shell
chmod +x scripts/backup/*.sh
```

### Étape 3 : Créer le répertoire de sauvegarde (optionnel)

```bash
# Créer le répertoire pour les exports Data Pump
sudo mkdir -p /opt/oracle/userhome/oracle/sauvegarde
sudo chown oracle:oinstall /opt/oracle/userhome/oracle/sauvegarde
```

---

## Exécution des scripts

### 1. Création de la base de données

```bash
# Se connecter en SYSDBA
sqlplus sys/oracle@localhost:1521/freepdb1 as sysdba

# Exécuter le script
SQL> @scripts/sql/01_creation_base.sql
```

**Ce script crée :**
- L'utilisateur `ENTREPRISEDB`
- Les tables `DEPARTEMENTS`, `EMPLOYES`, `PROJETS`
- Les contraintes d'intégrité référentielle
- Les données de test

### 2. Gestion des rôles et profils

```bash
# Toujours connecté en SYSDBA
SQL> @scripts/sql/02_roles_profils.sql
```

**Ce script crée :**
- Les rôles `GESTIONNAIRE_PROJET`, `GESTIONNAIRE_DEPARTEMENT`, `ADMINISTRATEUR_DB`
- Les utilisateurs `chef_projet`, `chef_dept`, `admin_sys`
- Le profil `PROFIL_LIMIT_EMPLOYES` (limites de session, CPU, temps, mots de passe)

### 3. Audit

```bash
# Toujours connecté en SYSDBA
SQL> @scripts/sql/03_audit.sql
```

**Ce script configure :**
| Politique d'audit | Événements surveillés |
|-------------------|----------------------|
| `CONNEXIONS_AUDIT_POLICY` | Tentatives de connexion (LOGON) |
| `EMPLOYES_AUDIT_POLICY` | INSERT, UPDATE, DELETE sur EMPLOYES |
| `PROJETS_AUDIT_POLICY` | INSERT, UPDATE, DELETE sur PROJETS |

### 4. Chiffrement avec DBMS_CRYPTO

```bash
# Toujours connecté en SYSDBA
SQL> @scripts/sql/04_crypto.sql
```

**Ce script :**
1. Donne les droits d'exécution `DBMS_CRYPTO` à `ENTREPRISEDB`
2. Crée la table chiffrée `PROJETS_DBMS_CRYPTO`
3. Crée la table des secrets `PROJETS_SECRETS`
4. Crée le package `PKG_PROJETS_CRYPTO` avec les fonctions :
   - `CHIFFRER_NOM()` - Chiffrement AES-128 d'une valeur
   - `DECHIFFRER_NOM()` - Déchiffrement avec code d'accès
5. Génère une clé unique (swordfish) par projet
6. Chiffre et insère toutes les données de la table `PROJETS`

**Schéma du chiffrement :**

```
Projet (PROJ_ID) → Clé Swordfish (16 octets aléatoires)
                          ↓
                    Chiffrée avec clé maître
                          ↓
                    Stockée dans PROJETS_SECRETS
                    
Données (NOM_PROJET, DATE_DEBUT, etc.)
                          ↓
                    Chiffrées avec Swordfish
                          ↓
                    Encodées en BASE64
                          ↓
                    Stockées dans PROJETS_DBMS_CRYPTO
```

### 5. Sauvegarde et restauration

```bash
# Exécuter les scripts dans SQL*Plus
SQL> @scripts/sql/05_sauvegarde.sql
```

**Ou utiliser les scripts shell automatisés :**

```bash
# Sauvegarde automatique
./scripts/backup/export_script.sh

# Restauration automatique
./scripts/backup/import_script.sh
```

**Détails de l'export Data Pump :**

| Paramètre | Valeur |
|-----------|--------|
| Mode | Schema (ENTREPRISEDB) |
| Compression | ALL |
| Parallélisme | 2 threads |
| Format | dumpfile avec %U (fichiers multiples) |

---

## Tests de validation

### Vérification du chiffrement

```sql
-- Se connecter en tant que ENTREPRISEDB
ALTER SESSION SET CURRENT_SCHEMA = ENTREPRISEDB;

-- Voir les données chiffrées (illisibles)
SELECT * FROM PROJETS_DBMS_CRYPTO;

-- Déchiffrer avec le code d'accès correct
SELECT
  PROJ_ID,
  PKG_PROJETS_CRYPTO.DECHIFFRER_NOM(NOM_PROJET, PROJ_ID, 'AccesAutorise') AS NOM_PROJET_CLAIR,
  PKG_PROJETS_CRYPTO.DECHIFFRER_NOM(STATUT, PROJ_ID, 'AccesAutorise') AS STATUT_CLAIR
FROM PROJETS_DBMS_CRYPTO;

-- Tentative sans code d'accès (retourne NULL)
SELECT
  PROJ_ID,
  PKG_PROJETS_CRYPTO.DECHIFFRER_NOM(NOM_PROJET, PROJ_ID) AS NOM_PROJET_SANS_CODE
FROM PROJETS_DBMS_CRYPTO;
```

### Vérification de l'audit

```sql
-- Consulter les logs de connexion
SELECT DBUSERNAME, ACTION_NAME, EVENT_TIMESTAMP, RETURN_CODE
FROM UNIFIED_AUDIT_TRAIL
WHERE ACTION_NAME = 'LOGON'
ORDER BY EVENT_TIMESTAMP DESC;

-- Consulter les modifications sur EMPLOYES
SELECT DBUSERNAME, ACTION_NAME, OBJECT_NAME, EVENT_TIMESTAMP
FROM UNIFIED_AUDIT_TRAIL
WHERE UNIFIED_AUDIT_POLICIES = 'EMPLOYES_AUDIT_POLICY'
ORDER BY EVENT_TIMESTAMP DESC;

-- Consulter les modifications sur PROJETS
SELECT DBUSERNAME, ACTION_NAME, OBJECT_NAME, EVENT_TIMESTAMP
FROM UNIFIED_AUDIT_TRAIL
WHERE UNIFIED_AUDIT_POLICIES = 'PROJETS_AUDIT_POLICY'
ORDER BY EVENT_TIMESTAMP DESC;
```

### Vérification des rôles et profils

```sql
-- Voir les rôles attribués aux utilisateurs
SELECT GRANTEE, GRANTED_ROLE
FROM DBA_ROLE_PRIVS
WHERE GRANTEE IN ('CHEF_PROJET', 'CHEF_DEPT', 'ADMIN_SYS');

-- Voir les profils assignés
SELECT USERNAME, PROFILE FROM DBA_USERS
WHERE USERNAME IN ('CHEF_PROJET', 'CHEF_DEPT');
```

### Vérification de la sauvegarde

```bash
# Vérifier les fichiers dump créés
ls -l /opt/oracle/userhome/oracle/sauvegarde/

# Vérifier le contenu du log d'export
cat /opt/oracle/userhome/oracle/sauvegarde/entreprise_exp.log

# Vérifier que la table PROJETS a été restaurée
sqlplus ENTREPRISEDB/mdpentreprise@localhost:1521/freepdb1
SQL> SELECT TABLE_NAME FROM USER_TABLES WHERE TABLE_NAME = 'PROJETS';
SQL> SELECT * FROM PROJETS;
```

### Test d'accès depuis chef_projet

```sql
-- Se connecter en tant que chef_projet
ALTER SESSION SET CURRENT_SCHEMA = chef_projet;

SELECT
  PROJ_ID,
  ENTREPRISEDB.PKG_PROJETS_CRYPTO.DECHIFFRER_NOM(NOM_PROJET, PROJ_ID, 'AccesAutorise') AS NOM_PROJET,
  ENTREPRISEDB.PKG_PROJETS_CRYPTO.DECHIFFRER_NOM(STATUT, PROJ_ID, 'AccesAutorise') AS STATUT_CLAIR
FROM ENTREPRISEDB.PROJETS_DBMS_CRYPTO;
```

---

## ⚠️ Dépannage

### Erreur ORA-00001 - Violation de contrainte unique

**Problème :** Insertion multiple de clés pour le même PROJ_ID

**Solution :**
```sql
TRUNCATE TABLE PROJETS_SECRETS;
TRUNCATE TABLE PROJETS_DBMS_CRYPTO;
COMMIT;
-- Réexécuter le script 04_crypto.sql
```

### Erreur ORA-00904 - Identifiant non valide

**Problème :** Package ou table non trouvé

**Solution :**
```sql
ALTER SESSION SET CURRENT_SCHEMA = ENTREPRISEDB;
-- Vérifier que le package existe
SELECT OBJECT_NAME, STATUS FROM USER_OBJECTS WHERE OBJECT_NAME = 'PKG_PROJETS_CRYPTO';
```

### Erreur Data Pump - Répertoire invalide

**Problème :** Le répertoire OS n'existe pas ou les droits sont insuffisants

**Solution :**
```sql
-- Vérifier le répertoire Oracle
SELECT * FROM DBA_DIRECTORIES WHERE DIRECTORY_NAME = 'ENTREPRISE_SAUVEGARDE';

-- Vérifier les droits OS
ls -ld /opt/oracle/userhome/oracle/sauvegarde/

-- Recréer le répertoire si nécessaire
CREATE OR REPLACE DIRECTORY entreprise_sauvegarde AS '/opt/oracle/userhome/oracle/sauvegarde';
GRANT READ, WRITE ON DIRECTORY entreprise_sauvegarde TO ENTREPRISEDB;
```

### Erreur de connexion à la PDB

**Problème :** Impossible de se connecter à freepdb1

**Solution :**
```sql
-- Vérifier que la PDB est ouverte
SELECT NAME, OPEN_MODE FROM V$PDBS;

-- Ouvrir la PDB si nécessaire
ALTER PLUGGABLE DATABASE freepdb1 OPEN;
ALTER SESSION SET CONTAINER = freepdb1;
```

### Erreur git: command not found

**Problème :** Git n'est pas installé sur le serveur Oracle Linux

**Solution :**
```bash
# Installer Git avec yum ou dnf
sudo yum install git -y
# ou
sudo dnf install git -y

# Alternative : télécharger le ZIP sans Git
wget https://github.com/valerieolg/Audit-Sauvegarde-Crypto-SQL/archive/refs/heads/main.zip
unzip main.zip
```

---

## Résultats attendus

| Opération | Résultat attendu |
|-----------|------------------|
| Création des tables | 3 tables créées avec contraintes |
| Insertion des données | 4 départements, 4 employés, 4 projets |
| Création des rôles | 3 rôles créés |
| Création des utilisateurs | 3 utilisateurs créés |
| Audit | Les modifications sont tracées dans UNIFIED_AUDIT_TRAIL |
| Chiffrement | Les données dans PROJETS_DBMS_CRYPTO sont illisibles |
| Déchiffrement | Les données sont lisibles uniquement avec le code 'AccesAutorise' |
| Sauvegarde | Fichier .dmp généré dans le répertoire de sauvegarde |
| Restauration | La table PROJETS est restaurée avec ses données |

---

## Livrables

| Fichier | Description |
|---------|-------------|
| `docs/TP2.docx` | Rapport complet en format Word |
| `scripts/sql/01_creation_base.sql` | Script de création de la BD |
| `scripts/sql/02_roles_profils.sql` | Script des rôles et profils |
| `scripts/sql/03_audit.sql` | Script des politiques d'audit |
| `scripts/sql/04_crypto.sql` | Script du chiffrement DBMS_CRYPTO |
| `scripts/sql/05_sauvegarde.sql` | Script de sauvegarde/restauration |
| `scripts/backup/export_script.sh` | Script shell de sauvegarde automatique |
| `scripts/backup/import_script.sh` | Script shell de restauration automatique |

---

## Liens utiles

- [Documentation Oracle DBMS_CRYPTO](https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_CRYPTO.html)
- [Oracle Unified Auditing Guide](https://docs.oracle.com/en/database/oracle/oracle-database/19/dbseg/introduction-to-unified-auditing.html)
- [Oracle Data Pump Utility](https://docs.oracle.com/en/database/oracle/oracle-database/19/sutil/oracle-data-pump-overview.html)

---

## Auteurs

| Nom | Rôle |
|-----|------|
| ERIC DE CELLES | Développeur |
| VALÉRIE OUELLET | Développeur |
| WILLIAM BOURBONNIÈRE | Développeur |

---

## Licence

Ce projet a été réalisé dans le cadre du cours **420-3GS-BB Gestion de serveurs de bases de données** au Cégep Bois-de-Boulogne.

---

**© 2026 - Tous droits réservés**

---
*Document généré le 30 avril 2026*
