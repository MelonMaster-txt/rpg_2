extends Node2D

const PLAYER_SCENE    := preload("res://game/characters/player/player.tscn")
const FARM_PLACER_SCR := preload("res://game/world/farm_placer.gd")
const NOISE_DEBUG_SCN := preload("res://game/world/noise_debug.tscn")
const DEBUG_MENU_SCN  := preload("res://game/ui/debug_menu.tscn")

@onready var _player_container : Node2D   = $PlayerContainer
@onready var _player_spawn     : Marker2D = $PlayerSpawn

var _noise_debug_node : CanvasLayer
var _debug_menu_node  : CanvasLayer

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
	_debug_menu_node = DEBUG_MENU_SCN.instantiate()
	add_child(_debug_menu_node)

	# Noise debug F2 — caché par défaut
	_noise_debug_node = CanvasLayer.new()
	_noise_debug_node.layer = 101
	var nd := NOISE_DEBUG_SCN.instantiate()
	_noise_debug_node.add_child(nd)
	_noise_debug_node.visible = false
	add_child(_noise_debug_node)

	_spawn_player()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		var key := (event as InputEventKey).keycode
		if key == KEY_F2:
			_noise_debug_node.visible = not _noise_debug_node.visible
			get_viewport().set_input_as_handled()

func _spawn_player() -> void:
	var player : Node2D = PLAYER_SCENE.instantiate() as Node2D
	if GameManager.has_saved_position:
		player.global_position = GameManager.consume_spawn_position()
	else:
		player.global_position = _player_spawn.global_position
	_player_container.add_child(player)
