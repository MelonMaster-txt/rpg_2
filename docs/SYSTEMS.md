# Documentation des Systèmes

## ResourceManager

**Fichier** : `game/systems/resources/resource_manager.gd`  
**Type** : Autoload

Gère toutes les ressources du jeu. Toute modification de ressource passe **obligatoirement** par ce manager.

```gdscript
# API publique
func add(type: String, amount: int) -> void
func remove(type: String, amount: int) -> bool  # retourne false si insuffisant
func get_amount(type: String) -> int
func has_enough(cost: Dictionary) -> bool

# Signaux
signal resource_changed(type: String, amount: int)
signal resource_depleted(type: String)

# Ressources disponibles
# "food", "wood", "stone", "gold", "faith"
```

---

## PopulationManager

**Fichier** : `game/systems/kingdom/population_manager.gd`  
**Type** : Autoload

Gère tous les habitants du royaume : famille, compagnons, esclaves.

```gdscript
# API publique
func add_npc(npc: NPCData, status: String) -> void  # status: "family"|"companion"|"slave"
func remove_npc(npc: NPCData) -> void
func get_all() -> Array[NPCData]
func get_by_status(status: String) -> Array[NPCData]
func get_by_job(job_id: String) -> Array[NPCData]

# Signaux
signal npc_captured(npc: NPCData)
signal npc_recruited(npc: NPCData)
signal npc_died(npc: NPCData)
signal job_assigned(npc: NPCData, job: JobData)
```

---

## JobSystem

**Fichier** : `game/systems/jobs/job_system.gd`  
**Type** : Scène indépendante instanciée par KingdomManager

Assigne des métiers aux PNJ et déclenche le ticker de production.

```gdscript
# Métiers disponibles
const JOBS = {
    "farmer":    {"production": "food",  "rate": 0.5, "building": "farm"},
    "lumberjack":{"production": "wood",  "rate": 0.4, "building": "sawmill"},
    "blacksmith": {"production": "gold", "rate": 0.2, "building": "forge"},
    "guard":     {"production": "",      "rate": 0.0, "building": "barracks"},
    "priest":    {"production": "faith", "rate": 0.3, "building": "temple"},
}

# Ticker : toutes les 5 secondes de jeu réel
# → appelle ResourceManager.add() pour chaque travailleur actif
```

---

## KingdomManager

**Fichier** : `game/systems/kingdom/kingdom_manager.gd`  
**Type** : Autoload

Gère la progression globale du royaume.

```gdscript
# API publique
func build(building_id: String) -> bool  # vérifie les ressources via ResourceManager
func get_buildings() -> Array[String]
func get_kingdom_level() -> int

# Signaux
signal building_built(building_id: String)
signal kingdom_level_up(new_level: int)
```

---

## ReligionManager

**Fichier** : `game/systems/religion/religion_manager.gd`  
**Type** : Autoload

Gère la foi globale et ses effets sur le gameplay.

```gdscript
# API publique
func set_religion(religion_id: String) -> void
func get_faith() -> float
func get_moral_bonus() -> float      # bonus sur productivité
func get_production_bonus() -> float # multiplicateur de production

# Signaux
signal faith_changed(amount: float)
signal religion_event(event_id: String)

# Religions disponibles (à implémenter)
# "pantheon_guerrier" → bonus combat
# "culte_nature"      → bonus food/wood
# "ordre_forgeron"    → bonus stone/gold
```

---

## EncounterManager

**Fichier** : `game/systems/encounter_manager.gd`  
**Type** : Scène instanciée dans World

Gère les rencontres avec les PNJ aléatoires dans la forêt.

```gdscript
# Flux
# 1. EventManager émet encounter_triggered(npc)
# 2. EncounterManager affiche le panneau de choix
# 3. Joueur choisit DISCUSS / FIGHT / RECRUIT
# 4. EncounterManager émet encounter_resolved(result)

signal choice_made(choice: String, npc: NPCData)
# choice: "discuss", "fight", "recruit"
```
