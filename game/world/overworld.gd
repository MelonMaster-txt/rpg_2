extends Node2D

const PLAYER_SCENE    := preload("res://game/characters/player/player.tscn")
const FARM_PLACER_SCR := preload("res://game/world/farm_placer.gd")

@onready var _player_container : Node2D   = $PlayerContainer
@onready var _player_spawn     : Marker2D = $PlayerSpawn
@onready var _chunk_manager    : Node2D   = $ChunkManager

func _ready() -> void:
	# Conteneur pour les FarmTiles
	var fc := Node2D.new()
	fc.name = "FarmContainer"
	add_child(fc)

	# Farm placer (doit etre enfant du meme parent que FarmContainer)
	var fp := Node2D.new()
	fp.set_script(FARM_PLACER_SCR)
	fp.name = "FarmPlacer"
	add_child(fp)

	_spawn_player()

func _spawn_player() -> void:
	var player : Node2D = PLAYER_SCENE.instantiate() as Node2D
	if GameManager.has_saved_position:
		player.global_position = GameManager.consume_spawn_position()
	else:
		player.global_position = _player_spawn.global_position
	_player_container.add_child(player)
