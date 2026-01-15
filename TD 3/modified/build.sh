#! /usr/bin/env bash

# Ce script est utilisé pour build le projet d'un coup
# sans devoir faire cd firmware, ./build.sh, cd ../sim, ./build.sh

# Retourne le chemin vers le dossier actuel
#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# On autorise 1 argument (obligatoire) ou 2 arguments (optionnel)
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "$0: Usage: ./build [direct/associatif] [OPTIONNEL:sans-nop]"
    echo ""
    echo "Exemple: Simuler le cache direct avec le programme sans les NOP: "
    echo " ./build direct sans-nop"
    echo ""
    echo "Exemple: Simuler le cache associatif avec le programme qui contient les NOP"
    echo " ./build associatif"
    exit 1 
fi

# 1. Choix du dossier (Argument 1)
case "$1" in
    direct)     FOLDER="cache_direct" ;;
    associatif) FOLDER="cache_associatif" ;;
    *)          echo "Erreur: option inconnue: $1"; exit 1 ;;
esac

# 2. Choix du fichier (Argument 2 optionnel)
FILE="exo3_2ways.S"
if [ "$2" == "sans-nop" ]; then
    FILE="exo3_2ways_sans_nop.S"
fi

# 3. Exécution avec gestion d'erreurs
echo "--- Compilation du firmware ($FILE) ---"
cd "$SCRIPT_DIR/firmware" || exit 1
source ./build.sh "$FILE"

echo "--- Lancement de la simulation ($FOLDER) ---"
cd "$SCRIPT_DIR/sim" || exit 1
source ./build.sh "$FOLDER"