# Sprites LPC — Instructions

Le dossier `sprites/` doit contenir les spritesheets au format LPC (576×256 px, 9 cols × 4 rows).

## Fichiers attendus

### Corps
- `body_male.png`
- `body_female.png`

### Tête
- `head_male.png`
- `head_female.png`

### Yeux
- `eyes_normal.png`
- `eyes_closed.png`
- `eyes_angry.png`
- `eyes_sad.png`

### Cheveux
- `hair_back_short.png` / `hair_front_short.png`
- `hair_back_medium.png` / `hair_front_medium.png`
- `hair_back_long.png` / `hair_front_long.png`
- `hair_back_bald.png` / `hair_front_bald.png`

### Tenues
- `outfit_peasant.png`
- `outfit_guard.png`
- `outfit_mage.png`
- `outfit_farmer.png`

## En attendant les sprites
Le système utilise des `ColorRect` comme fallback visuel (rectangles de couleur unie).
Il suffit de remplacer `_make_rect()` par `_make_sprite()` dans `character_appearance.gd` une fois les PNG présents.
