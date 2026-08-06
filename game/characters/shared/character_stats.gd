# character_stats.gd
# Statistiques d'un personnage (joueur ou NPC).
# Utilise comme @export dans NpcData.
class_name CharacterStats
extends Resource

@export var force: int = 5
@export var intelligence: int = 5
@export var charisma: int = 5
@export var stamina: int = 5
@export var luck: int = 5
@export var max_hp: int = 30

# Competences (0-100)
@export var skill_farming: int = 0
@export var skill_woodcutting: int = 0
@export var skill_mining: int = 0
@export var skill_crafting: int = 0
@export var skill_combat: int = 0
@export var skill_trading: int = 0


func randomize_stats() -> void:
	force = randi_range(3, 12)
	intelligence = randi_range(3, 12)
	charisma = randi_range(3, 12)
	stamina = randi_range(3, 12)
	luck = randi_range(1, 8)
	max_hp = 20 + stamina * 2 + randi_range(0, 10)


func randomize_skills() -> void:
	var skills: Array[String] = [
		"skill_farming", "skill_woodcutting", "skill_mining",
		"skill_crafting", "skill_combat", "skill_trading"
	]
	for s: String in skills:
		set(s, randi_range(5, 30))
	var dominant: String = skills[randi() % skills.size()]
	set(dominant, randi_range(50, 85))
