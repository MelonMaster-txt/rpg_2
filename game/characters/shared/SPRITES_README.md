# Sprites — Système de layers LPC

## Format
- **576 × 256 px** par spritesheet
- **9 colonnes** × **4 rangées**
- Rangées : `down(0)` / `left(1)` / `right(2)` / `up(3)`
- Colonnes : `idle(0)` / `walk1-8(1-8)`
- **Filtre Godot : NEAREST** (pixel art)

## Layers (ordre z-index)
```
5 - hair_front_{short|medium|long|bald}.png   ← bangs, dessus tête
4 - eyes_{normal|closed|angry|sad}.png        ← iris colorable
3 - head_{male|female}.png                    ← visage
2 - outfit_{peasant|guard|mage|farmer}.png    ← tenue
1 - body_{male|female}.png                    ← corps nu
0 - hair_back_{short|medium|long|bald}.png    ← cheveux derrière
```

## Coloration RGB (modulate Godot)
Toutes les sheets sont en **niveaux de gris blanc** :
- `set_skin_color(Color)` → applique sur body + head
- `set_hair_color(Color)` → applique sur hair_back + hair_front  
- `set_eyes_color(Color)` → applique sur eyes
- `set_outfit_color(Color)` → applique sur outfit

Exemple :
```gdscript
appearance.set_skin_color(Color(0.9, 0.7, 0.5))   # peau claire
appearance.set_hair_color(Color(0.15, 0.08, 0.02)) # cheveux noirs
appearance.set_eyes_color(Color(0.2, 0.8, 0.3))    # yeux verts
appearance.set_outfit_color(Color(0.4, 0.2, 0.6))  # tenue violette

# NPC entièrement aléatoire :
appearance.randomize_appearance()

# Sauvegarde :
var data = appearance.get_appearance_data()
# Restauration :
appearance.apply_appearance_data(data)
```

## Ajouter un nouveau layer
1. Créer la spritesheet en niveaux de gris (blanc = valeur max), 576×256px
2. Placer dans `res://game/characters/shared/sprites/`
3. Ajouter une variable `_s_XXXX: Sprite2D` dans `character_appearance.gd`
4. L'instancier dans `_build_layers()` avec le bon z_index
5. Ajouter `set_XXX_color()` et `_reload_XXX()`
