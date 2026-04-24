#!/bin/bash
# Script d'import Data Pump pour Oracle
# TP2 - Restauration de la base de données entreprise

# Configuration
ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
export ORACLE_HOME
PATH=$ORACLE_HOME/bin:$PATH
export PATH

BACKUP_DIR=/opt/oracle/userhome/oracle/sauvegarde
IMPORT_DATE=$(date +%Y%m%d_%H%M%S)
IMP_PAR_FILE="${BACKUP_DIR}/entreprise_imp.par"

# Créer le fichier de paramètres pour l'import
cat > ${IMP_PAR_FILE} << EOF
userid=ENTREPRISEDB/mdpentreprise@localhost:1521/freepdb1
directory=entreprise_sauvegarde
dumpfile=entreprise_%U.dmp
logfile=entreprise_imp_${IMPORT_DATE}.log
schemas=ENTREPRISEDB
table_exists_action=REPLACE
parallel=2
EOF

# Afficher la liste des fichiers dump disponibles
echo "Fichiers de sauvegarde disponibles :"
ls -lh ${BACKUP_DIR}/entreprise_*.dmp

# Demander confirmation
read -p "Voulez-vous procéder à la restauration? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restauration annulée."
    exit 1
fi

# Exécuter l'import
echo "Début de la restauration à ${IMPORT_DATE}"
impdp parfile=${IMP_PAR_FILE}

# Vérifier le résultat
if [ $? -eq 0 ]; then
    echo "Restauration réussie à $(date)"
else
    echo "ERREUR: La restauration a échoué à $(date)"
    exit 1
fi

echo "Restauration terminée"
