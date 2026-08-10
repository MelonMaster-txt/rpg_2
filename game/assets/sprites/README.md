# Structure des sprites

Tous les sprites du jeu sont rangés ici.
Les **NPC partagent la même banque que le joueur** (dossier `characters/`).

```
game/assets/sprites/
│
├── characters/          ← JOUEUR + NPC (même banque de sprites)
│   ├── body/            ← Corps de base (idle, walk, attack, work)
│   │                       Nommage : body_{genre}_{action}.png
│   │                       ex: body_male_idle.png, body_female_walk.png
│   ├── hair/            ← Calques cheveux
│   │                       ex: hair_short_brown.png, hair_long_black.png
│   ├── eyes/            ← Calques yeux
│   │                       ex: eyes_normal_blue.png
│   ├── outfit/          ← Calques tenues
│   │                       ex: outfit_peasant.png, outfit_guard.png
│   └── accessories/     ← Chapeaux, armes tenues, etc.
│
├── world/               ← Éléments du monde
│   ├── vegetation/      ← Arbres, buissons, herbes, cultures
│   │                       ex: bush_spritesheet.png
│   ├── tiles/           ← Tuiles de sol (TileMap)
│   │                       ex: tileset_grass.png, tileset_stone.png
│   ├── buildings/       ← Bâtiments et constructions
│   │                       ex: hut_small.png, forge.png
│   └── props/           ← Objets décoratifs du monde
│                           ex: rock_small.png, barrel.png
│
├── items/               ← Icônes et sprites d'objets
│   ├── weapons/         ← Armes
│   ├── tools/           ← Outils (hache, pioche...)
│   └── consumables/     ← Nourriture, potions
│
├── ui/                  ← Interface utilisateur
│   ├── icons/           ← Icônes génériques
│   ├── hud/             ← Éléments HUD (barres, cadres)
│   └── portraits/       ← Portraits PNJ pour dialogues
│
└── fx/                  ← Effets visuels
    ├── particles/       ← Textures de particules
    └── animations/      ← Animations FX (explosion, magie...)
```

## Convention de nommage

- `snake_case` obligatoire
- Format : `{categorie}_{variante}_{etat}.png`
- Spritesheets : suffixe `_sheet.png`
- Frames découpées : suffixe `_f01.png`, `_f02.png`...

## Note sur les personnages

Le système de personnalisation fonctionne par **calques superposés** :
1. `body` (base)
2. `eyes` (par-dessus le body)
3. `hair` (par-dessus les yeux)
4. `outfit` (par-dessus le body)
5. `accessories` (au-dessus de tout)

Chaque calque est un `Sprite2D` enfant du nœud personnage.
Les NPC utilisent exactement les mêmes fichiers que le joueur.
