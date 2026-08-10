extends Node

const HUD_SCENE:           PackedScene = preload("res://game/ui/hud.tscn")
const LOADING_SCENE:       PackedScene = preload("res://game/ui/loading_screen.tscn")
const CUSTOMIZATION_SCENE: PackedScene = preload("res://game/ui/character_customization_ui.tscn")

var _hud:     CanvasLayer = null
var _loading: CanvasLayer = null
var _customization: Control = null

func _ready() -> void:
	_spawn_hud()
	_spawn_customization()


func _spawn_hud() -> void:
	if _hud == null:
		_hud = HUD_SCENE.instantiate()
		add_child(_hud)


func _spawn_customization() -> void:
	_customization = CUSTOMIZATION_SCENE.instantiate()
	add_child(_customization)
	_customization.character_confirmed.connect(_on_character_confirmed)


func _on_character_confirmed(data: Dictionary) -> void:
	GameData.player_appearance = data
	_customization = null  # deja libere par queue_free dans le script
	_spawn_loading()
	_show_loading()
	SceneManager.load_start_scene()


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
