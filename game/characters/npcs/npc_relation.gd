extends Node
class_name NpcRelation

# ─── SIGNALS ──────────────────────────────────────────────────────────────────
signal relation_changed(new_value: int)

# ─── CONSTS ───────────────────────────────────────────────────────────────────
const MIN_RELATION: int = -100
const MAX_RELATION: int = 100

# ─── VARS ─────────────────────────────────────────────────────────────────────
var _value: int = 0


func get_value() -> int:
	return _value


func modify(amount: int) -> void:
	_value = clampi(_value + amount, MIN_RELATION, MAX_RELATION)
	relation_changed.emit(_value)


func reset() -> void:
	_value = 0
	relation_changed.emit(_value)


# Appelée depuis random_npc._add_relation_component()
# Initialise la relation avec une valeur aléatoire neutre à légèrement positive
func randomize_mood() -> void:
	_value = randi_range(-10, 20)
	relation_changed.emit(_value)
