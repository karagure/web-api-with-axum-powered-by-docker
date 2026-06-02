# Bonus — image Docker < 500 octets (affiche 0 → 10000)

Deux implémentations d'un programme qui imprime les nombres `0` à `10000`
(un par ligne) sur la sortie standard, packagées dans l'image Docker la plus
petite possible (`FROM scratch` → l'image ≈ le binaire).

| Version | Image | Binaire | Sortie |
|---------|-------|---------|--------|
| **ASM** (`numbers.asm`) | **198 o** | 198 o | 0..10000, 10001 lignes |
| **Zig** (`numbers.zig`) | **264 o** | 264 o | 0..10000, 10001 lignes |

Les deux sont **bien en-dessous des 500 octets** demandés.

## Principe

Une image `scratch` est vide : sa taille est exactement celle du binaire copié
dedans. Tout le jeu consiste donc à produire un exécutable Linux x86-64 le plus
petit possible, qui :

1. boucle de 0 à 10000,
2. convertit chaque entier en ASCII décimal,
3. appelle `write(2)` puis `exit(2)` via l'instruction `syscall` (aucune libc).

### ASM (`numbers.asm`)
ELF fabriqué à la main et assemblé en **binaire plat** (`nasm -f bin`) : aucun
remplissage d'éditeur de liens. Le fichier = en-tête ELF (64 o) + un en-tête de
programme (56 o) + le code (~78 o).

### Zig (`numbers.zig`)
Code Zig **freestanding** (pas de libc ni runtime), compilé en `ReleaseSmall`.
Pour approcher la taille de l'ASM :
- `tiny.ld` force **un seul segment `PT_LOAD`** et jette `.eh_frame`, `.note`, etc.
  → **456 octets**, déjà sous 500, avec seulement `zig build-exe` ;
- un **sstrip** (écrit en Zig, `sstrip.zig`, lancé via `zig run` — **aucun python**)
  retire la table des sections, inutile à l'exécution → **264 octets**.

La toolchain reste donc **100 % Zig**.

## Build & run

```sh
# --- ASM (tout se compile dans Docker, rien sur l'hôte) ---
docker build -f Dockerfile.asm -t bonus-asm .
docker run --rm bonus-asm | tail        # ... 9999 / 10000

# --- Zig (binaire produit sur l'hôte puis copié) ---
./build.sh                               # nécessite zig uniquement
docker build -f Dockerfile.zig -t bonus-zig .
docker run --rm bonus-zig | tail

# Vérifier la taille de l'image
docker images bonus-asm bonus-zig
```

> Note : `build.sh` produit `numbers-zig` (artefact). L'image ASM n'a besoin
> d'aucun pré-build, elle est 100 % reproductible via Docker seul.
