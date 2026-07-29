extends Node2D

const PLAYER_SCENE    := preload("res://game/characters/player/player.tscn")
const FARM_PLACER_SCR := preload("res://game/world/farm_placer.gd")
const NOISE_DEBUG_SCN := preload("res://game/world/noise_debug.tscn")

@onready var _player_container : Node2D   = $PlayerContainer
@onready var _player_spawn     : Marker2D = $PlayerSpawn

func _ready() -> void:
	# FarmContainer
	var fc := Node2D.new()
	fc.name = "FarmContainer"
	add_child(fc)

	# FarmPlacer dans le groupe farm_placer pour que le joueur le trouve
	var fp := Node2D.new()
	fp.set_script(FARM_PLACER_SCR)
	fp.name = "FarmPlacer"
	fp.add_to_group("farm_placer")
	add_child(fp)

	# DEBUG — panel noise preview (à retirer avant merge sur main)
	add_child(NOISE_DEBUG_SCN.instantiate())

	_spawn_player()

func _spawn_player() -> void:
	var player : Node2D = PLAYER_SCENE.instantiate() as Node2D
	if GameManager.has_saved_position:
		player.global_position = GameManager.consume_spawn_position()
	else:
		player.global_position = _player_spawn.global_position
	_player_container.add_child(player)
