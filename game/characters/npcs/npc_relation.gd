# npc_relation.gd — Composant de relation/humeur d'un NPC recruté ou capturé.
# Ajouté dynamiquement via random_npc._add_relation_component()
extends Node

enum Mood { CONTENT, NEUTRAL, UNHAPPY, REBELLIOUS }

var mood: Mood = Mood.NEUTRAL
var happiness: int = 100
var _decay_timer: float = 0.0
const DECAY_INTERVAL: float = 30.0
const DECAY_AMOUNT: int = 1


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_decay_timer += delta
	if _decay_timer >= DECAY_INTERVAL:
		_decay_timer = 0.0
		_tick_happiness()


func randomize_mood() -> void:
	happiness = randi_range(40, 100)
	_update_mood()


func add_happiness(amount: int) -> void:
	happiness = clampi(happiness + amount, 0, 100)
	_update_mood()


func _tick_happiness() -> void:
	# Les esclaves perdent plus de bonheur que les compagnons
	var parent: Node = get_parent()
	var role: String = ""
	if parent != null:
		var worker: Node = parent.get_node_or_null("WorkerAI")
		if worker != null:
			role = worker.get("role") if worker.get("role") != null else ""
	var decay: int = DECAY_AMOUNT * (2 if role == "slave" else 1)
	happiness = clampi(happiness - decay, 0, 100)
	_update_mood()


func _update_mood() -> void:
	if happiness >= 70:
		mood = Mood.CONTENT
	elif happiness >= 40:
		mood = Mood.NEUTRAL
	elif happiness >= 20:
		mood = Mood.UNHAPPY
	else:
		mood = Mood.REBELLIOUS


func get_mood_string() -> String:
	match mood:
		Mood.CONTENT:    return "Content"
		Mood.NEUTRAL:    return "Neutre"
		Mood.UNHAPPY:    return "Malheureux"
		Mood.REBELLIOUS: return "Rebelle"
	_: return "Inconnu"
