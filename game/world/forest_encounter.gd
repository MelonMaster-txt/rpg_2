# forest_encounter.gd
# A attacher sur une scene foret
extends Node

@export var encounter_interval: float = 15.0
@export var encounter_chance:   float = 0.40
@export var spawn_radius:       float = 200.0
@export var group_size_min:     int   = 1
@export var group_size_max:     int   = 3

var _timer:  float = 0.0
var _player: Node  = null


func _ready() -> void:
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]


func _process(delta: float) -> void:
	if not _player:
		return
	_timer += delta
	if _timer >= encounter_interval:
		_timer = 0.0
		_roll_encounter()


func _roll_encounter() -> void:
	if randf() > encounter_chance:
		return
	var count := randi_range(group_size_min, group_size_max)
	NpcSpawner.spawn_random_around(_player.global_position, spawn_radius, count)


func clear_encounters() -> void:
	NpcSpawner.despawn_all()
