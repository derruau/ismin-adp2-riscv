# RV32i Pipelined Processor & Cache Optimization

**CE PROJET A ÉTÉ DÉVELOPPÉ DANS LE CADRE D'UN COURS AUX [MINES DE SAINT-ETIENNE](https://www.mines-stetienne.fr/)**

Ce projet présente le développement complet d'un processeur **RISC-V 32 bits (RV32i)** pipeliné. Initialement fourni avec architecture de base, le processeur a été progressivement amélioré pour gérer les dépendances, la latence mémoire et l'optimisation des performances via un cache d'instructions associatif.

## 📂 Structure du Projet

Les dossiers `TD1`, `TD2` et `TD3` contiennent le même code à des moment différent de l'avancement du projet

- **`hdl_src/`** : Contient les sources SystemVerilog du processeur et du cache.
- **`firmware/`** : Programmes assembleur (`.S`) et scripts de compilation pour les tests.
- **`sim/`** : Scripts pour lancer les simulations ModelSim.
- **`tb`** : Le testbench du processeur.

## 🛠️ Installation et Prérequis

### 1. Compilateur RISC-V

Pour compiler les programmes de test (`.S`), vous avez besoin de la [chaîne de compilation RISC-V](https://github.com/riscv-collab/riscv-gnu-toolchain).

```bash
git clone https://github.com/riscv-collab/riscv-gnu-toolchain

cd riscv-gnu-toolchain

# Sur Ubuntu et les systèmes Debian
sudo apt-get install autoconf automake autotools-dev curl python3 python3-pip python3-tomli libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build git cmake libglib2.0-dev libslirp-dev libncurses-dev

./configure --prefix=/opt/riscv --with-arch=rv32gc --with-abi=ilp32d

# ATTENTION: cette commande prends BEAUCOUP de temps (~2h pour moi)
# Veuillez laisser votre ordinateur branché
make linux
```

Et ajoutez les programmes compilés au `PATH`

### 2. ModelSim

Logiciel requis pour la simulation HDL et la visualisation des chronogrammes.

Assurez-vous que les exécutables suivant soient présent dans votre `PATH`:
- `vsim` 
- `vdel`
- `vlib`
- `vmap`
- `vlog`.

Vous pouvez télécharger ModelSim depuis [ce lien](https://www.altera.com/downloads/simulation-tools/modelsim-fpgas-standard-edition-software-version-20-1-1). Le logiciel est disponible pour **Windows et Linux**

## 🚀 Guide d'Utilisation (Build & Simulation)

Le projet utilise un script `./build` pour compiler et simuler le projet en une seule commande.

### Pour le TD 1: Prise en main du processeur

```bash
# Pour compiler et simuler le programme fourni avec le processeur
./build exo1

# Pour compiler et simuler le programme main.S de l'ennoncé
./build main
```

### Pour le TD 2 : Implémentation des gestions de dépendance et du Wait State

```bash
# Pour build le projet tel qu'il était à la question X du TD
./build [Q3/Q10/Q12/Q14/Q15/Q17]
```

### Pour le TD 3 : Implémentation du Cache

```bash
# Pour build le projet avec le cache direct
./build direct 


# Pour build le projet avec le cache associatif 2 voies
./build associatif
```

Derrière ces deux commandes, vous pouvez rajouter un `sans-nop` pour
aussi compiler le même programme sans les instructions NOP qui empêchent
les dépendances. Exemple:
```bash
# Pour build le projet avec le cache associatif et compiler le programme
# sans les NOP.
./build associatif sans-nop
```

---

## 📈 Résultats de Performance

L'efficacité du cache a été mesurée en simulant l'arrêt d'un programme de test après exécution complète:

| Architecture | Temps d'exécution (ns) |
| --- | --- |
| Sans cache (Latence brute) | 12 530 ns |
| Cache Direct | 5 670 ns |
| **Cache Associatif 2 voies** | **3 870 ns** |

Ces mesures ont été effectuées avec les commandes suivante (dans l'ordre):
- `./TD3_SANS_CACHE/build.sh sans-nop`:
- `./TD3/modified/build.sh direct sans-nop`
- `./TD3/modified/build.sh associatif sans-nop`

Pour ces programmes, la latence de la mémoire d'instruction était de *5 cycles d'horloge*.
