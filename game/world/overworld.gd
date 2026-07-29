extends Node2D

const PLAYER_SCENE    := preload("res://game/characters/player/player.tscn")
const FARM_PLACER_SCR := preload("res://game/world/farm_placer.gd")

@onready var _player_container: Node2D = $PlayerContainer
@onready var _player_spawn:     Marker2D = $PlayerSpawn
@onready var _farm_container:   Node2D = $FarmContainer

var _farm_placer: Node = null

func _ready() -> void:
	_farm_placer = FARM_PLACER_SCR.new()
	_farm_placer.name = "FarmPlacer"
	add_child(_farm_placer)
	_farm_placer.init(_farm_container)
	call_deferred("_spawn_player")

func _spawn_player() -> void:
	var player: Node2D = PLAYER_SCENE.instantiate() as Node2D
	if GameManager.has_saved_position:
		player.global_position = GameManager.consume_spawn_position()
	else:
		player.global_position = _player_spawn.global_position
	_player_container.add_child(player)
