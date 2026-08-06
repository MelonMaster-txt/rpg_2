extends Control

signal regenerated

const MAP_SIZE: int = 256
const TILE_PIXEL: int = 2

@export var noise_scale: float = 50.0
@export var octaves: int = 4
@export var persistence: float = 0.5
@export var lacunarity: float = 2.0

@onready var _texture_rect: TextureRect = $TextureRect
@onready var _seed_input: SpinBox = $VBox/SeedInput
@onready var _regen_btn: Button = $VBox/RegenButton
@onready var _info_label: Label = $VBox/InfoLabel

var _noise: FastNoiseLite = FastNoiseLite.new()
var _current_seed: int = 0


func _ready() -> void:
	_regen_btn.pressed.connect(_on_regen_pressed)
	_generate(randi())


func _on_regen_pressed() -> void:
	_generate(int(_seed_input.value))


func _generate(seed_val: int) -> void:
	_current_seed = seed_val
	_noise.seed = seed_val
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_octaves = octaves
	_noise.fractal_gain = persistence
	_noise.fractal_lacunarity = lacunarity
	_noise.frequency = 1.0 / noise_scale
	_build_texture()
	regenerated.emit()
	_info_label.text = "Seed: %d" % seed_val


func _build_texture() -> void:
	var img: Image = Image.create(
		MAP_SIZE * TILE_PIXEL,
		MAP_SIZE * TILE_PIXEL,
		false,
		Image.FORMAT_RGB8
	)
	for y: int in range(MAP_SIZE):
		for x: int in range(MAP_SIZE):
			var val: float = (_noise.get_noise_2d(x, y) + 1.0) * 0.5
			var col: Color = _noise_to_color(val)
			for py: int in range(TILE_PIXEL):
				for px: int in range(TILE_PIXEL):
					img.set_pixel(
						x * TILE_PIXEL + px,
						y * TILE_PIXEL + py,
						col
					)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_texture_rect.texture = tex


func _noise_to_color(val: float) -> Color:
	if val < 0.3:
		return Color(0.1, 0.2, 0.7)
	if val < 0.45:
		return Color(0.8, 0.75, 0.5)
	if val < 0.7:
		return Color(0.2, 0.55, 0.15)
	if val < 0.85:
		return Color(0.35, 0.28, 0.2)
	return Color(0.95, 0.95, 0.95)
