#!/bin/bash
# Script d'export Data Pump pour Oracle
# TP2 - Sauvegarde de la base de données entreprise

# Configuration
ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
export ORACLE_HOME
PATH=$ORACLE_HOME/bin:$PATH
export PATH

BACKUP_DIR=/opt/oracle/userhome/oracle/sauvegarde
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
DUMP_FILE="entreprise_${BACKUP_DATE}.dmp"
LOG_FILE="entreprise_exp_${BACKUP_DATE}.log"
PAR_FILE="${BACKUP_DIR}/entreprise.par"

# Créer le répertoire de backup s'il n'existe pas
mkdir -p ${BACKUP_DIR}

# Créer le fichier de paramètres
cat > ${PAR_FILE} << EOF
userid=ENTREPRISEDB/mdpentreprise@localhost:1521/freepdb1
directory=entreprise_sauvegarde
dumpfile=entreprise_%U.dmp
logfile=entreprise_exp.log
schemas=ENTREPRISEDB
parallel=2
compression=ALL
EOF

# Exécuter l'export
echo "Début de la sauvegarde à ${BACKUP_DATE}"
expdp parfile=${PAR_FILE}

# Vérifier le résultat
if [ $? -eq 0 ]; then
    echo "Sauvegarde réussie à $(date)"
    # Compresser les fichiers de log
    gzip ${BACKUP_DIR}/*.log -c > ${BACKUP_DIR}/logs_${BACKUP_DATE}.gz
else
    echo "ERREUR: La sauvegarde a échoué à $(date)"
    exit 1
fi

# Nettoyage : garder les 5 dernières sauvegardes
cd ${BACKUP_DIR}
ls -t entreprise_*.dmp | tail -n +6 | xargs -r rm -f

echo "Sauvegarde terminée"
