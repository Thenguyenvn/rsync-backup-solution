#!/bin/bash

###############################################################################
# Automated Backup System - Production Grade
# Author: Valentine Zajac
# License: MIT
###############################################################################

# === CONFIGURATION GLOBALE ===
utilisateur_stockage="adminocr"
hote_stockage="10.10.10.2"
racine="/home/${utilisateur_stockage}"
source_locale="$HOME"
dossier_logs="$HOME/logs"
fichier_log="${dossier_logs}/backup.log"
date_du_jour=$(date +%Y-%m-%d)
heure=$(date +%H:%M:%S)

mkdir -p "$dossier_logs"

# === LISTE DES DOSSIERS À SAUVEGARDER (STRATÉGIE 1) AVEC RÉTENTION PERSONNALISÉE ===
# Format : dossier:rétention_en_jours
dossiers_strategy1=(
  "RH:3"
  "SITE:7"
  "MAILS:3"
  "FICHIERS:3"
  "TICKETS:2"
)

echo "[${date_du_jour} ${heure}] 🔁 Démarrage de la sauvegarde complète" >> "$fichier_log"

# === STRATÉGIE 1 : sauvegarde incrémentale avec n/n-1 ===
for element in "${dossiers_strategy1[@]}"; do
  dossier="${element%%:*}"
  retention="${element##*:}"

  source="${source_locale}/${dossier}/"
  destination="${racine}/${dossier}"
  dossier_n_1="${racine}/${dossier}_n-1/${date_du_jour}"

  echo "[${date_du_jour} ${heure}] 🔧 Sauvegarde de ${dossier} (rétention : ${retention} jours)" >> "$fichier_log"

  ssh ${utilisateur_stockage}@${hote_stockage} "find ${racine}/${dossier}_n-1/ -type f -mtime +${retention} -exec rm -v {} \;" >> "$fichier_log" 2>&1

  rsync -azv --delete --backup \
    --backup-dir="${dossier_n_1}" \
    "${source}" "${utilisateur_stockage}@${hote_stockage}:${destination}/" >> "$fichier_log" 2>&1

  echo "[${date_du_jour} ${heure}] ✅ ${dossier} sauvegardé avec succès" >> "$fichier_log"
  echo "-------------------------------------------------------------" >> "$fichier_log"
done

# === STRATÉGIE 2 : sauvegarde complète brute pour MACHINES ===
dossier="MACHINES"
source="${source_locale}/${dossier}/"
destination="${racine}/${dossier}"

echo "[${date_du_jour} ${heure}] 💽 Sauvegarde complète de ${dossier} (STRATÉGIE 2)" >> "$fichier_log"

ssh ${utilisateur_stockage}@${hote_stockage} "rm -rf ${destination}" >> "$fichier_log" 2>&1

rsync -azv --delete --partial "${source}" "${utilisateur_stockage}@${hote_stockage}:${destination}/" >> "$fichier_log" 2>&1

echo "[${date_du_jour} ${heure}] ✅ Dossier ${dossier} sauvegardé avec stratégie 2" >> "$fichier_log"
echo "=============================================================" >> "$fichier_log"
