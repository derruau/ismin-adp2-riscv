#! /usr/bin/env bash

# Ce script est utilisé pour build le projet d'un coup
# sans devoir faire cd firmware, ./build.sh, cd ../sim, ./build.sh

# Retourne le chemin vers le dossier actuel
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ $# -ne 1 ]; then
    echo "$0: usage: ./build [exo1/main]"
    echo ""
    echo "Pour build avec le script relié à un programme précis"
    exit 1
fi

# On map la question au nom du fichier
case "$1" in
    exo1)
        FILENAME="exo1.S"
        ;;
    main)
        FILENAME="main.S"
        ;;
    *)
        echo "Erreur - Programme inconnu: $1"
        exit 1
        ;;
esac

cd "$SCRIPT_DIR/firmware" || exit 1;
source ./build.sh "$FILENAME";
cd "$SCRIPT_DIR/sim" || exit 1;
source ./build.sh;
