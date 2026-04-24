--=============================
-- 5. Sauvegarde et Restauration (Data Pump)
--=============================

-- Partie 1: Préparation de l'environnement de sauvegarde
-- (À exécuter en tant que SYS ou utilisateur avec privilèges ADMIN)

-- Octroi du privilège CREATE ANY DIRECTORY
-- CONNECT SYS/oracle@localhost:1521/freepdb1 AS SYSDBA
GRANT CREATE ANY DIRECTORY TO ENTREPRISEDB;

-- Création du répertoire OS (commande Linux à exécuter dans le terminal)
-- mkdir -p /opt/oracle/userhome/oracle/sauvegarde
-- chown oracle:oinstall /opt/oracle/userhome/oracle/sauvegarde

-- Création de l'objet DIRECTORY dans Oracle
CREATE OR REPLACE DIRECTORY entreprise_sauvegarde AS '/opt/oracle/userhome/oracle/sauvegarde';

-- Octroi des droits d'écriture sur le répertoire
GRANT READ, WRITE ON DIRECTORY entreprise_sauvegarde TO ENTREPRISEDB;

-- Vérification du répertoire
SELECT * FROM DBA_DIRECTORIES WHERE DIRECTORY_NAME = 'ENTREPRISE_SAUVEGARDE';

-- Partie 2: Export (Sauvegarde) - Fichier de paramètres entreprise.par
-- Contenu du fichier /opt/oracle/userhome/oracle/sauvegarde/entreprise.par :
-----------------------------------------------------------------------------
-- userid=ENTREPRISEDB/mdpentreprise@localhost:1521/freepdb1
-- directory=entreprise_sauvegarde
-- dumpfile=entreprise_%U.dmp
-- logfile=entreprise_exp.log
-- schemas=ENTREPRISEDB
-- parallel=2
-- compression=ALL
-----------------------------------------------------------------------------

-- Exécution de l'export
-- Commande Linux : expdp parfile=/opt/oracle/userhome/oracle/sauvegarde/entreprise.par

-- Vérification des fichiers générés
-- Commande Linux : ls -l /opt/oracle/userhome/oracle/sauvegarde/

-- Partie 3: Simulation de perte de données
ALTER SESSION SET CURRENT_SCHEMA = ENTREPRISEDB;

-- Vérifier l'état initial des tables
SELECT TABLE_NAME FROM USER_TABLES ORDER BY TABLE_NAME;

-- Créer une table de sauvegarde avant suppression (précaution)
CREATE TABLE PROJETS_BK AS SELECT * FROM PROJETS;

-- Supprimer la table PROJETS
DROP TABLE PROJETS CASCADE CONSTRAINTS;

-- Vérifier que la table a bien été supprimée
SELECT TABLE_NAME FROM USER_TABLES WHERE TABLE_NAME = 'PROJETS';

-- Partie 4: Import (Restauration) - Fichier de paramètres entreprise_imp.par
-- Contenu du fichier /opt/oracle/userhome/oracle/sauvegarde/entreprise_imp.par :
-----------------------------------------------------------------------------
-- userid=ENTREPRISEDB/mdpentreprise@localhost:1521/freepdb1
-- directory=entreprise_sauvegarde
-- dumpfile=entreprise_%U.dmp
-- logfile=entreprise_imp.log
-- schemas=ENTREPRISEDB
-- table_exists_action=REPLACE
-- parallel=2
-----------------------------------------------------------------------------

-- Exécution de l'import
-- Commande Linux : impdp parfile=/opt/oracle/userhome/oracle/sauvegarde/entreprise_imp.par

-- Partie 5: Validation de la restauration
-- Vérifier que la table PROJETS a été restaurée
SELECT TABLE_NAME FROM USER_TABLES WHERE TABLE_NAME = 'PROJETS';

-- Vérifier l'intégrité des données restaurées
SELECT * FROM PROJETS;

-- Comparer avec la sauvegarde
SELECT * FROM PROJETS_BK;

-- Vérifier les contraintes
SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE, STATUS 
FROM USER_CONSTRAINTS 
WHERE TABLE_NAME = 'PROJETS';

-- Nettoyage (optionnel)
-- DROP TABLE PROJETS_BK;
-- DROP DIRECTORY entreprise_sauvegarde;
