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
	emit_signal("relation_changed", _value)

func reset() -> void:
	_value = 0
	emit_signal("relation_changed", _value)
