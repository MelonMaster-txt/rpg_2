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

# ── Debug : spawn d'un NPC autour du joueur ────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Touche F9 pour debug NPC
		if event.keycode == Key.F9:
			_spawn_debug_npc()

func _spawn_debug_npc() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player := players[0] as Node2D
	var origin := player.global_position
	# rayon petit pour debug
	NpcSpawner.spawn_random_around(origin, 200.0, 1)
