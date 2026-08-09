# character_stats.gd
# Resource définissant les statistiques d'un personnage (joueur ou PNJ).
class_name CharacterStats
extends Resource

@export var force:        int = 5
@export var stamina:      int = 5
@export var luck:         int = 5
@export var intelligence: int = 5
@export var charisma:     int = 5
@export var max_hp:       int = 30

# Compétences (0 – 100)
@export var skill_farming:     int = 0
@export var skill_woodcutting: int = 0
@export var skill_mining:      int = 0
@export var skill_crafting:    int = 0
@export var skill_combat:      int = 0
@export var skill_trading:     int = 0


func randomize_stats() -> void:
	force        = randi_range(3, 12)
	stamina      = randi_range(3, 12)
	luck         = randi_range(1, 8)
	intelligence = randi_range(3, 12)
	charisma     = randi_range(3, 12)
	max_hp       = 20 + force * 2 + randi_range(0, 10)


func randomize_skills() -> void:
	skill_farming     = randi_range(0, 40)
	skill_woodcutting = randi_range(0, 40)
	skill_mining      = randi_range(0, 40)
	skill_crafting    = randi_range(0, 40)
	skill_combat      = randi_range(0, 40)
	skill_trading     = randi_range(0, 40)
