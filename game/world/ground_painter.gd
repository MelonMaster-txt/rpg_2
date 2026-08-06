@tool
extends Node2D

const SAVE_PATH: String = "user://noise_settings.cfg"

@export var tile_size: int = 32

@export_group("Noise Ground")
@export var g_noise_type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
@export var g_fractal_type: FastNoiseLite.FractalType = FastNoiseLite.FRACTAL_FBM
@export var g_seed:       int   = 42
@export var g_frequency:  float = 0.003
@export var g_octaves:    int   = 4
@export var g_lacunarity: float = 2.0
@export var g_gain:       float = 0.5
@export var g_warp_amp:   float = 0.0

@export_group("Palette Seuils")
@export var threshold_1: float =  0.3
@export var threshold_2: float =  0.1
@export var threshold_3: float = -0.1
@export var threshold_4: float = -0.3

@export_group("Couleurs Herbe")
@export var color_grass_0: Color = Color(0.27, 0.58, 0.18)
@export var color_grass_1: Color = Color(0.24, 0.55, 0.16)
@export var color_grass_2: Color = Color(0.22, 0.52, 0.15)
@export var color_grass_3: Color = Color(0.18, 0.44, 0.12)
@export var color_grass_4: Color = Color(0.55, 0.38, 0.18)

@export_group("Noise Accent")
@export var d_seed:          int   = 99
@export var d_frequency:     float = 0.06
@export var d_octaves:       int   = 2
@export var accent_threshold: float = 0.4

@export_group("Couleurs Accent")
@export var color_accent_0: Color = Color(0.30, 0.62, 0.20)
@export var color_accent_1: Color = Color(0.55, 0.52, 0.18)
@export var color_accent_2: Color = Color(0.26, 0.56, 0.40)

var _chunk_coords: Vector2i = Vector2i.ZERO
var _chunk_size:   int      = 512
var _noise_g:      FastNoiseLite = null
var _noise_d:      FastNoiseLite = null

func _validate_property(property: Dictionary) -> void:
	if Engine.is_editor_hint() and not property.is_empty():
		_build_noises()
		_repaint()

func _ready() -> void:
	if not Engine.is_editor_hint():
		_load_cfg()
	_build_noises()
	_repaint()

func paint(chunk_coords: Vector2i, chunk_size: int) -> void:
	_chunk_coords = chunk_coords
	_chunk_size   = chunk_size
	add_to_group("ground_painter")
	_load_cfg()
	_build_noises()
	_repaint()

func repaint_with(
	noise: FastNoiseLite,
	noise_d: FastNoiseLite,
	thresholds: Array[float],
	grass_colors: Array[Color],
	accent_colors: Array[Color],
	thr: float
) -> void:
	for child: Node in get_children():
		child.queue_free()
	_do_paint(
		_chunk_coords, _chunk_size,
		noise, noise_d,
		thresholds, grass_colors, accent_colors, thr
	)

func _load_cfg() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	g_seed         = cfg.get_value("ground", "seed",       g_seed)
	g_noise_type   = cfg.get_value(
		"ground", "type", g_noise_type
	) as FastNoiseLite.NoiseType
	g_frequency    = cfg.get_value("ground", "freq",       g_frequency)
	g_octaves      = cfg.get_value("ground", "octaves",    g_octaves)
	g_lacunarity   = cfg.get_value("ground", "lacunarity", g_lacunarity)
	g_gain         = cfg.get_value("ground", "gain",       g_gain)
	g_fractal_type = cfg.get_value(
		"ground", "fbm", g_fractal_type
	) as FastNoiseLite.FractalType
	g_warp_amp       = cfg.get_value("ground", "warp_amp",  g_warp_amp)
	d_seed           = cfg.get_value("accent", "seed",      d_seed)
	d_frequency      = cfg.get_value("accent", "freq",      d_frequency)
	d_octaves        = cfg.get_value("accent", "octaves",   d_octaves)
	accent_threshold = cfg.get_value("accent", "threshold", accent_threshold)
	threshold_1 = cfg.get_value("thresholds", "t0", threshold_1)
	threshold_2 = cfg.get_value("thresholds", "t1", threshold_2)
	threshold_3 = cfg.get_value("thresholds", "t2", threshold_3)
	threshold_4 = cfg.get_value("thresholds", "t3", threshold_4)
	color_grass_0  = cfg.get_value("grass_colors",  "c0", color_grass_0)
	color_grass_1  = cfg.get_value("grass_colors",  "c1", color_grass_1)
	color_grass_2  = cfg.get_value("grass_colors",  "c2", color_grass_2)
	color_grass_3  = cfg.get_value("grass_colors",  "c3", color_grass_3)
	color_grass_4  = cfg.get_value("grass_colors",  "c4", color_grass_4)
	color_accent_0 = cfg.get_value("accent_colors", "c0", color_accent_0)
	color_accent_1 = cfg.get_value("accent_colors", "c1", color_accent_1)
	color_accent_2 = cfg.get_value("accent_colors", "c2", color_accent_2)

func _build_noises() -> void:
	_noise_g = FastNoiseLite.new()
	_noise_g.noise_type          = g_noise_type
	_noise_g.seed                = g_seed
	_noise_g.frequency           = g_frequency
	_noise_g.fractal_type        = g_fractal_type
	_noise_g.fractal_octaves     = g_octaves
	_noise_g.fractal_lacunarity  = g_lacunarity
	_noise_g.fractal_gain        = g_gain
	_noise_g.domain_warp_enabled = g_warp_amp > 0.0
	if g_warp_amp > 0.0:
		_noise_g.domain_warp_amplitude = g_warp_amp
	_noise_d = FastNoiseLite.new()
	_noise_d.noise_type      = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_d.seed            = d_seed
	_noise_d.frequency       = d_frequency
	_noise_d.fractal_octaves = d_octaves

func _repaint() -> void:
	for child: Node in get_children():
		child.queue_free()
	var thresholds: Array[float]  = [threshold_1, threshold_2, threshold_3, threshold_4]
	var grass_colors: Array[Color] = [
		color_grass_0, color_grass_1, color_grass_2, color_grass_3, color_grass_4
	]
	var accent_colors: Array[Color] = [color_accent_0, color_accent_1, color_accent_2]
	_do_paint(
		_chunk_coords, _chunk_size,
		_noise_g, _noise_d,
		thresholds, grass_colors, accent_colors, accent_threshold
	)

func _do_paint(
	chunk_coords: Vector2i,
	chunk_size: int,
	noise: FastNoiseLite,
	noise_d: FastNoiseLite,
	thresholds: Array[float],
	grass_colors: Array[Color],
	accent_colors: Array[Color],
	thr: float
) -> void:
	var cols: int = floori(float(chunk_size) / float(tile_size))
	var rows: int = floori(float(chunk_size) / float(tile_size))
	for row: int in rows:
		for col: int in cols:
			var wx: int   = chunk_coords.x * cols + col
			var wy: int   = chunk_coords.y * rows + row
			var vg: float = noise.get_noise_2d(float(wx), float(wy))
			var vd: float = noise_d.get_noise_2d(float(wx), float(wy))
			var rect      := ColorRect.new()
			rect.size     = Vector2(tile_size, tile_size)
			rect.position = Vector2(col * tile_size, row * tile_size)
			if vd > thr:
				rect.color = accent_colors[
					abs(wx * 3 + wy) % accent_colors.size()
				]
			else:
				rect.color = _noise_to_color(vg, thresholds, grass_colors)
			add_child(rect)

func _noise_to_color(v: float, t: Array[float], c: Array[Color]) -> Color:
	if   v > t[0]: return c[0]
	if   v > t[1]: return c[1]
	if   v > t[2]: return c[2]
	if   v > t[3]: return c[3]
	return c[4]

func clear_chunk() -> void:
	for child: Node in get_children():
		child.queue_free()
