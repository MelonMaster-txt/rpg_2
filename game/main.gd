extends Node

const HUD_SCENE = preload("res://game/ui/hud.tscn")

var _hud: CanvasLayer = null

func _ready() -> void:
	_spawn_hud()
	SceneManager.load_start_scene()

func _spawn_hud() -> void:
	if _hud == null:
		_hud = HUD_SCENE.instantiate()
		add_child(_hud)
