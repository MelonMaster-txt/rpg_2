extends Node2D

const PLAYER_SCENE           := preload("res://game/characters/player/player.tscn")
const FARM_PLACER_SCR        := preload("res://game/world/farm_placer.gd")
const NOISE_DEBUG_SCN        := preload("res://game/world/noise_debug.tscn")
const DEBUG_MENU_SCR         := preload("res://game/ui/debug_menu.gd")
const NOISE_KEY_LISTENER     := preload("res://game/world/noise_key_listener.gd")
const IN_GAME_SAVE_MENU_SCN  := preload("res://game/core/in_game_save_menu.tscn")

@onready var _player_container : Node2D   = $PlayerContainer
@onready var _player_spawn     : Marker2D = $PlayerSpawn

func _ready() -> void:
	var fc := Node2D.new()
	fc.name = "FarmContainer"
	add_child(fc)

	var fp := Node2D.new()
	fp.set_script(FARM_PLACER_SCR)
	fp.name = "FarmPlacer"
	fp.add_to_group("farm_placer")
	add_child(fp)

	# Debug F1
	var debug_menu := CanvasLayer.new()
	debug_menu.set_script(DEBUG_MENU_SCR)
	debug_menu.name = "DebugMenu"
	add_child(debug_menu)

	# Noise debug F2 - la scene contient un CanvasLayer root
	var nd_scene := NOISE_DEBUG_SCN.instantiate()
	nd_scene.visible = false
	add_child(nd_scene)

	# Listener F2
	var listener := Node.new()
	listener.set_script(NOISE_KEY_LISTENER)
	listener.name = "NoiseKeyListener"
	add_child(listener)

	# Menu sauvegarde en jeu (Échap)
	var save_overlay := IN_GAME_SAVE_MENU_SCN.instantiate()
	save_overlay.name = "InGameSaveMenu"
	add_child(save_overlay)

	_spawn_player()
	_connect_loading_screen()


func _spawn_player() -> void:
	var player : Node2D = PLAYER_SCENE.instantiate() as Node2D
	if GameManager.has_saved_position:
		player.global_position = GameManager.consume_spawn_position()
	else:
		player.global_position = _player_spawn.global_position
	_player_container.add_child(player)


func _connect_loading_screen() -> void:
	var chunk_manager := get_node_or_null("ChunkManager")
	if chunk_manager == null:
		return
	var main := get_tree().root.get_node_or_null("Main")
	if main == null:
		return
	if not chunk_manager.initial_load_completed.is_connected(
			main._on_chunk_manager_initial_load_completed):
		chunk_manager.initial_load_completed.connect(
				main._on_chunk_manager_initial_load_completed)
