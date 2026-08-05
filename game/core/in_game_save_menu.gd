extends CanvasLayer

# ─── SIGNALS ──────────────────────────────────────────────────────────────────
signal resume_requested

# ─── ONREADY ──────────────────────────────────────────────────────────────────
@onready var _save_menu: Control = $SaveMenu

func _ready() -> void:
	_save_menu.visible = false

func open() -> void:
	_save_menu.visible = true
	get_tree().paused = true

func close() -> void:
	_save_menu.visible = false
	get_tree().paused = false
	emit_signal("resume_requested")

func _on_resume_pressed() -> void:
	close()
