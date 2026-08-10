# berry_bush.gd
# Buisson de baies avec 3 étapes de croissance + 3 états de baies
# Sprite sheet : 6 frames de 32x32 côte à côte
# Frame 0-2 : croissance (pousse → mi-poussée → plein)
# Frame 3 : plein + vide | Frame 4 : quelques baies | Frame 5 : plein de baies
extends Node2D

signal berries_harvested(amount: int)
signal fully_grown
signal depleted

enum GrowthStage { SPROUT, HALF, FULL }
enum BerryStage { EMPTY, FEW, FULL }

const FRAME_MAP: Dictionary = {
	GrowthStage.SPROUT: 0,
	GrowthStage.HALF:   1,
	GrowthStage.FULL:   2,
}
const BERRY_FRAME_MAP: Dictionary = {
	BerryStage.EMPTY: 2,
	BerryStage.FEW:   3,
	BerryStage.FULL:  4,
}

@export var growth_time: float       = 30.0
@export var berry_regrow_time: float = 45.0
@export var berry_yield_min: int     = 1
@export var berry_yield_max: int     = 4
@export var start_fully_grown: bool  = false

var _growth_stage: GrowthStage = GrowthStage.SPROUT
var _berry_stage: BerryStage   = BerryStage.FULL
var _growth_timer: float       = 0.0
var _berry_timer: float        = 0.0
var _berry_growing: bool       = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_setup_frames()
	if start_fully_grown:
		_growth_stage = GrowthStage.FULL
		_berry_stage  = BerryStage.FULL
	_update_frame()


func _process(delta: float) -> void:
	if _growth_stage != GrowthStage.FULL:
		_growth_timer += delta
		if _growth_timer >= growth_time:
			_growth_timer = 0.0
			_advance_growth()
		return
	if _berry_growing:
		_berry_timer += delta
		if _berry_timer >= berry_regrow_time / 2.0:
			_berry_stage = BerryStage.FEW
			_update_frame()
		if _berry_timer >= berry_regrow_time:
			_berry_stage   = BerryStage.FULL
			_berry_growing = false
			_berry_timer   = 0.0
			_update_frame()


func harvest() -> void:
	if _growth_stage != GrowthStage.FULL or _berry_stage == BerryStage.EMPTY:
		return
	var amount: int = randi_range(berry_yield_min, berry_yield_max)
	if _berry_stage == BerryStage.FEW:
		amount = maxi(1, amount / 2)
	if ResourceManager.has_method("add_resource"):
		ResourceManager.add_resource("food", amount)
	_berry_stage   = BerryStage.EMPTY
	_berry_growing = true
	_berry_timer   = 0.0
	_update_frame()
	berries_harvested.emit(amount)
	depleted.emit()


func is_harvestable() -> bool:
	return _growth_stage == GrowthStage.FULL and _berry_stage != BerryStage.EMPTY


func _advance_growth() -> void:
	match _growth_stage:
		GrowthStage.SPROUT:
			_growth_stage = GrowthStage.HALF
		GrowthStage.HALF:
			_growth_stage = GrowthStage.FULL
			_berry_stage  = BerryStage.FULL
			fully_grown.emit()
	_update_frame()


func _update_frame() -> void:
	if not is_instance_valid(_sprite):
		return
	var frame_index: int
	if _growth_stage == GrowthStage.FULL:
		frame_index = BERRY_FRAME_MAP.get(_berry_stage, 2) as int
	else:
		frame_index = FRAME_MAP.get(_growth_stage, 0) as int
	_sprite.frame = frame_index


func _setup_frames() -> void:
	if not is_instance_valid(_sprite):
		return
	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 1.0)
	frames.set_animation_loop("default", false)
	var texture: Texture2D = load("res://game/assets/sprites/world/vegetation/bush_spritesheet.png")
	if texture == null:
		push_error("BerryBush: impossible de charger bush_spritesheet.png")
		return
	for i: int in range(6):
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas  = texture
		atlas.region = Rect2(i * 32, 0, 32, 32)
		frames.add_frame("default", atlas)
	_sprite.sprite_frames = frames
	_sprite.animation = "default"
	_sprite.frame     = 0
	_sprite.stop()
