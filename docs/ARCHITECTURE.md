# Architecture du projet RPG Barbare

## Vue d'ensemble

```
rpg_2/
├── game/
│   ├── main.gd / main.tscn       ← Point d'entrée
│   ├── characters/               ← Player, NPC
│   ├── core/                     ← Données de base
│   ├── systems/                  ← Tous les systèmes
│   │   ├── combat/
│   │   ├── dialogue/
│   │   ├── jobs/
│   │   ├── kingdom/
│   │   ├── religion/
│   │   ├── resources/
│   │   ├── item_database.gd
│   │   ├── workbench.gd/.tscn
│   │   └── workbench_ui.gd/.tscn
│   ├── ui/                       ← HUD, menus
│   └── world/                    ← TileMap, génération
├── addons/
├── tools/
└── docs/                         ← Documentation (ce dossier)
```

---

## Autoloads (Singletons)

| Autoload | Fichier | Rôle |
|---|---|---|
| `GameData` | `game/core/game_data.gd` | Seed map, état global, sauvegarde |
| `ResourceManager` | `game/systems/resources/resource_manager.gd` | food, wood, stone, gold, faith |
| `PopulationManager` | `game/systems/kingdom/population_manager.gd` | Habitants, statuts, recrutement |
| `KingdomManager` | `game/systems/kingdom/kingdom_manager.gd` | Bâtiments, niveau royaume |
| `ReligionManager` | `game/systems/religion/religion_manager.gd` | Foi, religion active, effets |
| `EventManager` | `game/systems/event_manager.gd` | Événements aléatoires, rencontres |

---

## Signaux globaux

```gdscript
# ResourceManager
signal resource_changed(type: String, amount: int)
signal resource_depleted(type: String)

# PopulationManager
signal npc_captured(npc: NPCData)
signal npc_recruited(npc: NPCData)
signal npc_died(npc: NPCData)
signal job_assigned(npc: NPCData, job: JobData)

# KingdomManager
signal building_built(building_id: String)
signal kingdom_level_up(new_level: int)

# ReligionManager
signal faith_changed(amount: float)
signal religion_event(event_id: String)

# EventManager
signal encounter_triggered(npc: NPCData)
signal encounter_resolved(result: String)
```

---

## Flux de jeu principal

```
[Joueur explore la forêt]
        ↓
[EventManager] → encounter_triggered(npc)
        ↓
[EncounterManager] → Choix : DISCUSS / FIGHT / RECRUIT
        ↓
  ┌─────┴──────┐
FIGHT        RECRUIT
  ↓              ↓
[CombatSystem]  [PopulationManager]
  ↓              .add_npc(npc, COMPANION)
KILL / CAPTURE
  ↓
[PopulationManager]
  .add_npc(npc, SLAVE/COMPANION)
        ↓
[JobSystem] → assign_job(npc, job)
        ↓
[ResourceManager] → production ticker
```

---

## State Machine PNJ

```
      ┌──────────────────────────────┐
      ↓                              │
   [IDLE] ──timer──→ [WANDER]        │
      ↑                 │            │
      └─────────────────┘            │
      │                              │
  player_near                        │
      ↓                              │
  [COMBAT] ──win──→ résolution  ─────┘
      │
   job_assigned
      ↓
   [WORK]
      │
   follow_order
      ↓
  [FOLLOW]
```

---

## Resources personnalisées (.tres)

### NPCData
```gdscript
@export var npc_name: String
@export var strength: int
@export var job_potential: Array[String]
@export var status: String  # "family", "companion", "slave"
@export var faith: float
@export var is_family: bool
@export var portrait: Texture2D
```

### JobData
```gdscript
@export var job_id: String
@export var job_name: String
@export var production_type: String
@export var production_rate: float  # par seconde de jeu
@export var building_required: String
```

### BuildingData
```gdscript
@export var building_id: String
@export var building_name: String
@export var cost: Dictionary  # {"wood": 10, "stone": 5}
@export var unlocks_job: String
@export var production_bonus: float
@export var max_workers: int
```
