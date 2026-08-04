extends Node

const HUD_SCENE          = preload("res://game/ui/hud.tscn")
const LOADING_SCENE      = preload("res://game/ui/loading_screen.tscn")

var _hud: CanvasLayer        = null
var _loading: CanvasLayer    = null

func _ready() -> void:
	_spawn_hud()
	_spawn_loading()
	_show_loading()
	SceneManager.load_start_scene()

func _spawn_hud() -> void:
	if _hud == null:
		_hud = HUD_SCENE.instantiate()
		add_child(_hud)

func _spawn_loading() -> void:
	if _loading == null:
		_loading = LOADING_SCENE.instantiate() as CanvasLayer
		add_child(_loading)

func _show_loading() -> void:
	if _loading != null and _loading.has_method("show_loading"):
		_loading.show_loading()

func _hide_loading() -> void:
	if _loading != null and _loading.has_method("hide_loading"):
		_loading.hide_loading()

func _on_chunk_manager_initial_load_completed() -> void:
	_hide_loading()
