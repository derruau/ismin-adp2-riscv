#! /usr/bin/env bash

# Ce script est utilisé pour build le projet d'un coup
# sans devoir faire cd firmware, ./build.sh, cd ../sim, ./build.sh

# Retourne le chemin vers le dossier actuel
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ $# -ne 1 ]; then
    echo "$0: usage: ./build [Q3/Q10/Q12/Q14/Q15/Q17]"
    echo ""
    echo "Pour build avec le script relié à une question"
    echo "précise du TD, veuillez insérer le nom de la question:"
    echo "  - Q3: Le script avec des NOP partout"
    echo "  - Q10: Le script avec les dépendances de données sans NOP"
    echo "  - Q12: Le script sans dépendances de contrôle type J et sans les dépendances de données"
    echo "  - Q14: Le script qui gère toutes les dépendances de données et de contrôle"
    echo "  - Q15: Le script ilock_tests.S"
    echo "  - Q17: Le script ilock_tests.S avec le Wait State"
    exit 1
fi

# On map la question au nom du fichier
case "$1" in
    Q3)
        FILENAME="exo2_Q3.S"
        ;;
    Q10)
        FILENAME="exo2_Q10.S"
        ;;
    Q12)
        FILENAME="exo2_Q12.S"
        ;;
    Q14)
        FILENAME="exo2_Q14.S"
        ;;
    Q15) 
        FILENAME="ilock_tests.S"
        ;;
    Q17)
        FILENAME="ilock_tests.S"
        ;;
    *)
        echo "Erreur: Question inconnue: $1"
        exit 1
        ;;
esac

cd "$SCRIPT_DIR/firmware" || exit 1;
source ./build.sh "$FILENAME";
cd "$SCRIPT_DIR/sim" || exit 1;
source ./build.sh "$1";
