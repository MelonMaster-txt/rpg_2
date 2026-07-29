extends Node2D

const PLAYER_SCENE       := preload("res://game/characters/player/player.tscn")
const FARM_PLACER_SCR    := preload("res://game/world/farm_placer.gd")
const NOISE_DEBUG_SCN    := preload("res://game/world/noise_debug.tscn")
const DEBUG_MENU_SCR     := preload("res://game/ui/debug_menu.gd")
const NOISE_KEY_LISTENER := preload("res://game/world/noise_key_listener.gd")

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

	# Noise debug F2 - instancie la scene directement (elle contient deja son CanvasLayer)
	# On la cache via le groupe "noise_debug_panel" dans le script
	var nd := NOISE_DEBUG_SCN.instantiate()
	nd.visible = false
	add_child(nd)

	# Listener F2
	var listener := Node.new()
	listener.set_script(NOISE_KEY_LISTENER)
	listener.name = "NoiseKeyListener"
	add_child(listener)

	_spawn_player()

func _spawn_player() -> void:
	var player : Node2D = PLAYER_SCENE.instantiate() as Node2D
	if GameManager.has_saved_position:
		player.global_position = GameManager.consume_spawn_position()
	else:
		player.global_position = _player_spawn.global_position
	_player_container.add_child(player)
