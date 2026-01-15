#! /usr/bin/env bash

# Ce script est utilisé pour build le projet d'un coup
# sans devoir faire cd firmware, ./build.sh, cd ../sim, ./build.sh

# Retourne le chemin vers le dossier actuel
#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# On autorise 1 argument (obligatoire) ou 2 arguments (optionnel)
if [ $# -gt 1 ]; then
    echo "$0: Usage: ./build [OPTIONNEL:sans-nop]"
    echo ""
    exit 1 
fi

# 2. Choix du fichier (Argument 2 optionnel)
FILE="exo3_2ways.S"
if [ "$1" == "sans-nop" ]; then
    FILE="exo3_2ways_sans_nop.S"
fi

# 3. Exécution avec gestion d'erreurs
echo "--- Compilation du firmware ($FILE) ---"
cd "$SCRIPT_DIR/firmware" || exit 1
source ./build.sh "$FILE"

echo "--- Lancement de la simulation ($FOLDER) ---"
cd "$SCRIPT_DIR/sim" || exit 1
source ./build.sh ""
