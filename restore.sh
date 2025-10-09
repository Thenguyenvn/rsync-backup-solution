#!/bin/bash

###################################################################################################
# SCRIPT : restore.sh
# AUTEUR : Valentine Z.
# CONTEXTE : Projet de sauvegarde
#
# OBJET :
# Ce script permet de restaurer des fichiers ou répertoires depuis la VM de stockage vers la VM
# simulation selon 3 scénarios :
# OPTION 1 - Restauration complète (version N) :
#	- Restaure un répertoire de contexte (ex: RH, SITE) à son état actuel
#
# OPTION 2 - Restauration ciblée d'un fichier (version n-1) :
#	- Permet de récupérer un fichier depuis une sauvegarde datée
#
# OPTION 3 - Restauration d'une marchine virtuelle :
# 	- Permet de restaurer un fichier VM depuis le répertoire MACHINES de la VM Stockage
#
# JOURNALISATION :
# Toutes les restaurations sont enregistrées dans :
# ~/logs/restore.log
#
#################################################################################################

# === CONFIGURATION ===
REMOTE_USER="adminocr"
REMOTE_HOST="10.10.10.2"
BACKUP_DIR_BASE="/home/${REMOTE_USER}"
RESTORE_LOG="/home/userocr/logs/restore.log"

# === FONCTIONS ===

restore_version_n() {
    read -p "📁 Entrez le nom du dossier de contexte (ex: RH, MAILS, etc.) : " CONTEXT

    SRC="${REMOTE_USER}@${REMOTE_HOST}:${BACKUP_DIR_BASE}/${CONTEXT}/"
    DEST="/home/userocr/${CONTEXT}/"

    echo "🔁 Restauration complète de ${SRC} vers ${DEST}"
    rsync -az --delete "$SRC" "$DEST"

    if [ $? -eq 0 ]; then
        echo "$(date '+%F %T') : Restauration complète de ${SRC} vers ${DEST}" >> "$RESTORE_LOG"
        echo "✅ Restauration complète réussie."
    else
        echo "$(date '+%F %T') : Échec restauration complète de ${SRC}" >> "$RESTORE_LOG"
        echo "❌ Échec de la restauration complète."
    fi
}

restore_n1_file() {
    read -p "📁 Entrez le nom du dossier de contexte (ex: RH_n-1, MAILS_n-1, etc.) : " CONTEXT
    read -p "📅 Entrez la date de sauvegarde (format YYYY-MM-DD) : " DATE_N1
    read -p "📄 Entrez le chemin relatif du fichier à restaurer (ex: Fiches/monfichier.txt) : " FILE

    # Retirer le "_n-1" pour reconstituer le dossier de destination
    DEST_CONTEXT="${CONTEXT%_n-1}"

    SRC="${REMOTE_USER}@${REMOTE_HOST}:${BACKUP_DIR_BASE}/${CONTEXT}/${DATE_N1}/${FILE}"
    DEST="/home/userocr/${DEST_CONTEXT}/${FILE}"

    mkdir -p "$(dirname "$DEST")"

    echo "🔁 Restauration du fichier ${SRC} vers ${DEST}"
    rsync -az "$SRC" "$DEST"

    if [ $? -eq 0 ]; then
        echo "$(date '+%F %T') : Restauration fichier ${SRC} vers ${DEST}" >> "$RESTORE_LOG"
        echo "✅ Fichier restauré avec succès dans ${DEST}"
    else
        echo "$(date '+%F %T') : Échec restauration fichier ${SRC}" >> "$RESTORE_LOG"
        echo "❌ Échec de la restauration du fichier."
    fi
}



restore_vm() {
    read -p "🖥️  Entrez le nom du fichier de la machine virtuelle à restaurer (ex: debian.qcow2) : " VM_FILE

    SRC="${REMOTE_USER}@${REMOTE_HOST}:${BACKUP_DIR_BASE}/MACHINES/${VM_FILE}"
    DEST="/home/userocr/MACHINES/${VM_FILE}"

    mkdir -p "$(dirname "$DEST")"

    echo "🔁 Restauration de la VM ${SRC} vers ${DEST}"
    rsync -az "$SRC" "$DEST"

    if [ $? -eq 0 ]; then
        echo "$(date '+%F %T') : ✅ Restauration de VM ${VM_FILE}" >> "$RESTORE_LOG"
        echo "✅ Machine virtuelle restaurée avec succès."
    else
        echo "$(date '+%F %T') : ❌ Échec restauration de VM ${VM_FILE}" >> "$RESTORE_LOG"
        echo "❌ Échec de la restauration de la machine virtuelle."
    fi
}

# === MENU ===

echo "------ RESTAURATION -------"
echo "1. Restaurer la version N (complète d’un contexte)"
echo "2. Restaurer un fichier en version N-1"
echo "3. Restaurer une machine virtuelle"
read -p "Choix (1/2/3) : " CHOIX

if [ "$CHOIX" == "1" ]; then
    restore_version_n
elif [ "$CHOIX" == "2" ]; then
    restore_n1_file
elif [ "$CHOIX" == "3" ]; then
    restore_vm
else
    echo "❌ Choix invalide."
fi
