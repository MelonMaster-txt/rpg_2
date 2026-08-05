extends Node2D
# overworld.gd
# Le joueur N'EST PAS dans la scène en dur — il est instancié depuis
# res://game/player/player.tscn et ajouté dans PlayerContainer au _ready.

const PLAYER_SCENE: String = "res://game/player/player.tscn"

@onready var _chunk_manager:    Node   = $ChunkManager
@onready var _player_container: Node2D = $PlayerContainer
@onready var _farm_container:   Node2D = $FarmContainer
@onready var _hud:              CanvasLayer = $HUD

var _player: CharacterBody2D = null
var _farm_tiles: Dictionary  = {}


func _ready() -> void:
	_spawn_player()
	_restore_farm()


func _spawn_player() -> void:
	var packed: PackedScene = load(PLAYER_SCENE)
	if packed == null:
		push_error("Overworld: impossible de charger " + PLAYER_SCENE)
		return
	_player = packed.instantiate() as CharacterBody2D
	_player_container.add_child(_player)
	# Positionne au spawn marker si présent
	var spawn: Marker2D = get_node_or_null("PlayerSpawn")
	if spawn:
		_player.global_position = spawn.global_position
	# Donne la référence au HUD si celui-ci en a besoin
	if _hud and _hud.has_method("set_player"):
		_hud.set_player(_player)
	# Donne la référence au ChunkManager pour suivre le joueur
	if _chunk_manager and _chunk_manager.has_method("set_player"):
		_chunk_manager.set_player(_player)


func _restore_farm() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		return
	if gm.has_method("restore_farm_tiles"):
		gm.restore_farm_tiles(_farm_container, _farm_tiles)


func _exit_tree() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("save_farm_tiles"):
		gm.save_farm_tiles(_farm_tiles)
