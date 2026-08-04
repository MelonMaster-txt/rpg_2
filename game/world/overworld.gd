extends Node2D

const PLAYER_SCENE           := preload("res://game/characters/player/player.tscn")
const FARM_PLACER_SCR        := preload("res://game/world/farm_placer.gd")
const NOISE_DEBUG_SCN        := preload("res://game/world/noise_debug.tscn")
const DEBUG_MENU_SCR         := preload("res://game/ui/debug_menu.gd")
const NOISE_KEY_LISTENER     := preload("res://game/world/noise_key_listener.gd")
const IN_GAME_SAVE_MENU_SCN  := preload("res://game/core/in_game_save_menu.tscn")

@onready var _player_container : Node2D   = $PlayerContainer
@onready var _player_spawn     : Marker2D = $PlayerSpawn

# Référence à l'écran de chargement créé en code
var _loading_screen: CanvasLayer = null


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

	# Noise debug F2
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
	_setup_loading_screen()


func _spawn_player() -> void:
	var player : Node2D = PLAYER_SCENE.instantiate() as Node2D
	if GameManager.has_saved_position:
		player.global_position = GameManager.consume_spawn_position()
	else:
		player.global_position = _player_spawn.global_position
	_player_container.add_child(player)


func _setup_loading_screen() -> void:
	# Crée le CanvasLayer de loading en code (layer 128 = toujours au-dessus)
	_loading_screen = CanvasLayer.new()
	_loading_screen.layer = 128
	_loading_screen.name = "LoadingScreen"

	# Fond noir opaque
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_loading_screen.add_child(bg)

	# Label centré
	var lbl := Label.new()
	lbl.text = "Chargement du monde..."
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_loading_screen.add_child(lbl)

	add_child(_loading_screen)

	# Connecte le signal du ChunkManager
	var chunk_manager := get_node_or_null("ChunkManager")
	if chunk_manager != null:
		chunk_manager.initial_load_completed.connect(_on_initial_load_completed)
	else:
		# Pas de ChunkManager ? On cache directement
		_on_initial_load_completed()


func _on_initial_load_completed() -> void:
	if _loading_screen != null and is_instance_valid(_loading_screen):
		_loading_screen.queue_free()
		_loading_screen = null
