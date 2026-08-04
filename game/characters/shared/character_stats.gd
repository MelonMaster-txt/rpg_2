# character_stats.gd
# Resource de base partagee par tous les personnages (joueur et NPC)
class_name CharacterStats
extends Resource

# ── Stats de combat ────────────────────────────────────────────────
@export var hp_max: int     = 100
@export var hp: int         = 100
@export var attack: int     = 10
@export var defense: int    = 5
@export var speed: int      = 5

# ── Stats sociales / RPG ───────────────────────────────────────────
@export var force: int        = 5
@export var intelligence: int = 5
@export var charisma: int     = 5
@export var stamina: int      = 5
@export var luck: int         = 5

# ── Competences metier (buffs de production) ───────────────────────
# Valeur entre 0 et 100, genere aleatoirement sur les NPC
@export var skill_farming: int    = 0   # +% recolte agricole
@export var skill_woodcutting: int = 0  # +% bois coupe
@export var skill_mining: int     = 0   # +% pierre/minerai
@export var skill_crafting: int   = 0   # +% production artisanat
@export var skill_combat: int     = 0   # +% degats/defense combat
@export var skill_trading: int    = 0   # +% valeur echanges

func randomize_stats(min_val: int = 1, max_val: int = 15) -> void:
	force        = randi_range(min_val, max_val)
	intelligence = randi_range(min_val, max_val)
	charisma     = randi_range(min_val, max_val)
	stamina      = randi_range(min_val, max_val)
	luck         = randi_range(min_val, max_val)
	attack       = randi_range(min_val, max_val)
	defense      = randi_range(min_val, max_val)
	speed        = randi_range(min_val, max_val)
	hp_max       = 50 + force * 5
	hp           = hp_max

func randomize_skills() -> void:
	# Un NPC a 1 ou 2 competences dominantes, les autres sont faibles
	var skills := ["skill_farming", "skill_woodcutting", "skill_mining",
				   "skill_crafting", "skill_combat", "skill_trading"]
	for s in skills:
		set(s, randi_range(0, 20))
	# On booste 1 ou 2 competences dominantes
	var nb_dominant := randi_range(1, 2)
	var dominant := skills.duplicate()
	dominant.shuffle()
	for i in nb_dominant:
		set(dominant[i], randi_range(50, 100))

func get_primary_skill() -> String:
	var best := "skill_farming"
	var best_val := skill_farming
	if skill_woodcutting > best_val: best = "skill_woodcutting"; best_val = skill_woodcutting
	if skill_mining      > best_val: best = "skill_mining";      best_val = skill_mining
	if skill_crafting    > best_val: best = "skill_crafting";    best_val = skill_crafting
	if skill_combat      > best_val: best = "skill_combat";      best_val = skill_combat
	if skill_trading     > best_val: best = "skill_trading";     best_val = skill_trading
	return best

func is_alive() -> bool:
	return hp > 0

func take_damage(amount: int) -> int:
	var dmg := max(1, amount - defense)
	hp = max(0, hp - dmg)
	return dmg
