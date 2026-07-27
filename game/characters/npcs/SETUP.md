# Setup NPC — Pipeline LPC → Godot

## 1. Générer les sprites (Universal LPC Generator)

URL : https://sanderfrenken.github.io/Universal-LPC-Spritesheet-Character-Generator/

### Layers à exporter (un PNG par layer, en gris/blanc) :
| Fichier attendu | Onglet LPC | Conseil |
|---|---|---|
| `body_male.png` | Body → Male | Choisir "Grayscale" ou désaturer après |
| `body_female.png` | Body → Female | idem |
| `head_male.png` | Head → Male | |
| `head_female.png` | Head → Female | |
| `hair_back_short.png` | Hair → Short → Back | |
| `hair_back_medium.png` | Hair → Medium → Back | |
| `hair_back_long.png` | Hair → Long → Back | |
| `hair_back_bald.png` | (vide — PNG transparent) | |
| `hair_front_short.png` | Hair → Short → Front | |
| `hair_front_medium.png` | Hair → Medium → Front | |
| `hair_front_long.png` | Hair → Long → Front | |
| `hair_front_bald.png` | (vide — PNG transparent) | |
| `eyes_normal.png` | Eyes → Normal | |
| `eyes_closed.png` | Eyes → Closed | |
| `eyes_angry.png` | Eyes → Angry | |
| `eyes_sad.png` | Eyes → Sad | |
| `outfit_peasant.png` | Clothes → Peasant | |
| `outfit_guard.png` | Clothes → Guard | |
| `outfit_mage.png` | Clothes → Mage | |
| `outfit_farmer.png` | Clothes → Farmer | |

## 2. Désaturer en lot (Python)

```python
from PIL import Image
import os

SPRITES_DIR = "game/characters/shared/sprites/"
for f in os.listdir(SPRITES_DIR):
    if not f.endswith(".png"): continue
    path = os.path.join(SPRITES_DIR, f)
    img = Image.open(path).convert("RGBA")
    r, g, b, a = img.split()
    # Luminance = moyenne des canaux
    from PIL import ImageOps
    gray = ImageOps.grayscale(img.convert("RGB"))
    gray_rgba = Image.merge("RGBA", [gray, gray, gray, a])
    gray_rgba.save(path)
print("Désaturation terminée.")
```

## 3. Placer les PNG
```
res://game/characters/shared/sprites/
├── body_male.png
├── body_female.png
├── head_male.png
├── ...
```

## 4. Import Godot
- Sélectionner tous les PNG dans le FileSystem
- Onglet **Import** → `Texture2D`
- **Filter** : `Nearest`  ← OBLIGATOIRE pour le pixel art
- Cliquer **Re-Import**

## 5. Ajouter NpcSpawner en Autoload

Dans **Project → Project Settings → Autoload** :
- Path : `res://game/characters/npcs/npc_spawner.gd`
- Name : `NpcSpawner`

## 6. Tester un spawn rapide

```gdscript
# Dans n'importe quel script, en _ready() :
NpcSpawner.spawn_at(Vector2(200, 150))
NpcSpawner.spawn_random_around(get_parent().global_position, 150.0, 3)
```
