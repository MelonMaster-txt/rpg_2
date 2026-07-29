extends Node2D

const PLAYER_SCENE      := preload("res://game/characters/player/player.tscn")
const FARM_PLACER_SCR   := preload("res://game/world/farm_placer.gd")
const CHUNK_MANAGER_SCR := preload("res://game/world/chunk_manager.gd")

@onready var _player_container : Node2D   = $PlayerContainer
@onready var _player_spawn     : Marker2D = $PlayerSpawn
@onready var _chunk_manager    : Node2D   = $ChunkManager

func _ready() -> void:
	# Attache le script au noeud ChunkManager
	if _chunk_manager.get_script() == null:
		_chunk_manager.set_script(CHUNK_MANAGER_SCR)

	# Farm placer (Node2D avec script)
	var fp := Node2D.new()
	fp.set_script(FARM_PLACER_SCR)
	fp.name = "FarmPlacer"
	add_child(fp)

	call_deferred("_spawn_player")

func _spawn_player() -> void:
	var player : Node2D = PLAYER_SCENE.instantiate() as Node2D
	if GameManager.has_saved_position:
		player.global_position = GameManager.consume_spawn_position()
	else:
		player.global_position = _player_spawn.global_position
	_player_container.add_child(player)
