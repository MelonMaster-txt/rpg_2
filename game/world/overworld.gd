extends Node2D

# ─── ONREADY ──────────────────────────────────────────────────────────────────
@onready var _chunk_manager: Node = $ChunkManager
@onready var _player: CharacterBody2D = $Player
@onready var _hud: CanvasLayer = $HUD
@onready var _farm_container: Node2D = $FarmTiles

# ─── VARS ─────────────────────────────────────────────────────────────────────
var _farm_tiles: Dictionary = {}

func _ready() -> void:
	GameManager.restore_farm_tiles(_farm_container, _farm_tiles)

func _exit_tree() -> void:
	GameManager.save_farm_tiles(_farm_tiles)
