@tool
# ground_painter.gd
# @tool = tourne dans l'éditeur Godot.
# Règle les @export dans l'Inspector → le sol se redessine en temps réel
# et les valeurs sont sauvegardées automatiquement dans la scène.
extends Node2D

# --- Tile ---
@export var tile_size: int = 32 :
	set(v): tile_size = v; _dirty = true; queue_redraw()

# --- Noise Ground ---
@export_group("Noise Ground")
@export var g_seed        : int   = 42       : set(v): g_seed        = v; _dirty=true; queue_redraw()
@export var g_frequency   : float = 0.018    : set(v): g_frequency   = v; _dirty=true; queue_redraw()
@export var g_octaves     : int   = 4        : set(v): g_octaves     = v; _dirty=true; queue_redraw()
@export var g_lacunarity  : float = 2.0      : set(v): g_lacunarity  = v; _dirty=true; queue_redraw()
@export var g_gain        : float = 0.5      : set(v): g_gain        = v; _dirty=true; queue_redraw()
@export var g_warp_amp    : float = 0.0      : set(v): g_warp_amp    = v; _dirty=true; queue_redraw()
@export var g_noise_type  : FastNoiseLite.NoiseType   = FastNoiseLite.TYPE_PERLIN : set(v): g_noise_type=v; _dirty=true; queue_redraw()
@export var g_fractal_type: FastNoiseLite.FractalType = FastNoiseLite.FRACTAL_FBM : set(v): g_fractal_type=v; _dirty=true; queue_redraw()

# --- Seuils palette (haut -> bas) ---
@export_group("Palette Seuils")
@export var threshold_1: float =  0.3  : set(v): threshold_1=v; _dirty=true; queue_redraw()
@export var threshold_2: float =  0.1  : set(v): threshold_2=v; _dirty=true; queue_redraw()
@export var threshold_3: float = -0.1  : set(v): threshold_3=v; _dirty=true; queue_redraw()
@export var threshold_4: float = -0.3  : set(v): threshold_4=v; _dirty=true; queue_redraw()

# --- Couleurs herbe ---
@export_group("Couleurs Herbe")
@export var color_grass_0: Color = Color(0.27, 0.58, 0.18) : set(v): color_grass_0=v; _dirty=true; queue_redraw()
@export var color_grass_1: Color = Color(0.24, 0.55, 0.16) : set(v): color_grass_1=v; _dirty=true; queue_redraw()
@export var color_grass_2: Color = Color(0.22, 0.52, 0.15) : set(v): color_grass_2=v; _dirty=true; queue_redraw()
@export var color_grass_3: Color = Color(0.18, 0.44, 0.12) : set(v): color_grass_3=v; _dirty=true; queue_redraw()
@export var color_grass_4: Color = Color(0.55, 0.38, 0.18) : set(v): color_grass_4=v; _dirty=true; queue_redraw()

# --- Noise Accent ---
@export_group("Noise Accent")
@export var d_seed     : int   = 99    : set(v): d_seed    =v; _dirty=true; queue_redraw()
@export var d_frequency: float = 0.06  : set(v): d_frequency=v; _dirty=true; queue_redraw()
@export var d_octaves  : int   = 2     : set(v): d_octaves =v; _dirty=true; queue_redraw()
@export var accent_threshold: float = 0.4 : set(v): accent_threshold=v; _dirty=true; queue_redraw()

@export_group("Couleurs Accent")
@export var color_accent_0: Color = Color(0.30, 0.62, 0.20) : set(v): color_accent_0=v; _dirty=true; queue_redraw()
@export var color_accent_1: Color = Color(0.55, 0.52, 0.18) : set(v): color_accent_1=v; _dirty=true; queue_redraw()
@export var color_accent_2: Color = Color(0.26, 0.56, 0.40) : set(v): color_accent_2=v; _dirty=true; queue_redraw()

# --- Coords (set par forest_chunk_base) ---
var _chunk_coords : Vector2i = Vector2i.ZERO
var _chunk_size   : int      = 512
var _dirty        : bool     = true
var _noise_g      : FastNoiseLite
var _noise_d      : FastNoiseLite

func _ready() -> void:
	_build_noises()
	_repaint()

func _draw() -> void:
	if Engine.is_editor_hint() and _dirty:
		_build_noises()
		_repaint()
		_dirty = false

# Appelé par forest_chunk_base au runtime
func paint(chunk_coords: Vector2i, chunk_size: int) -> void:
	_chunk_coords = chunk_coords
	_chunk_size   = chunk_size
	add_to_group("ground_painter")
	_build_noises()
	_repaint()

# Appelé par noise_debug (panel in-game optionnel) pour repaint live
func repaint_with(
	noise: FastNoiseLite, noise_d: FastNoiseLite,
	thresholds: Array, grass_colors: Array,
	accent_colors: Array, thr: float
) -> void:
	for child in get_children(): child.queue_free()
	_do_paint(_chunk_coords, _chunk_size, noise, noise_d, thresholds, grass_colors, accent_colors, thr)

func _build_noises() -> void:
	_noise_g = FastNoiseLite.new()
	_noise_g.noise_type         = g_noise_type
	_noise_g.seed               = g_seed
	_noise_g.frequency          = g_frequency
	_noise_g.fractal_type       = g_fractal_type
	_noise_g.fractal_octaves    = g_octaves
	_noise_g.fractal_lacunarity = g_lacunarity
	_noise_g.fractal_gain       = g_gain
	_noise_g.domain_warp_enabled = g_warp_amp > 0.0
	if g_warp_amp > 0.0:
		_noise_g.domain_warp_amplitude = g_warp_amp
	_noise_d = FastNoiseLite.new()
	_noise_d.noise_type      = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise_d.seed            = d_seed
	_noise_d.frequency       = d_frequency
	_noise_d.fractal_octaves = d_octaves

func _repaint() -> void:
	for child in get_children(): child.queue_free()
	var thresholds   : Array = [threshold_1, threshold_2, threshold_3, threshold_4]
	var grass_colors : Array = [color_grass_0, color_grass_1, color_grass_2, color_grass_3, color_grass_4]
	var accent_colors: Array = [color_accent_0, color_accent_1, color_accent_2]
	_do_paint(_chunk_coords, _chunk_size, _noise_g, _noise_d, thresholds, grass_colors, accent_colors, accent_threshold)

func _do_paint(
	chunk_coords: Vector2i, chunk_size: int,
	noise: FastNoiseLite, noise_d: FastNoiseLite,
	thresholds: Array, grass_colors: Array,
	accent_colors: Array, thr: float
) -> void:
	var cols: int = chunk_size / tile_size
	var rows: int = chunk_size / tile_size
	for row in rows:
		for col in cols:
			var wx: int = chunk_coords.x * cols + col
			var wy: int = chunk_coords.y * rows + row
			var vg: float = noise.get_noise_2d(float(wx), float(wy))
			var vd: float = noise_d.get_noise_2d(float(wx), float(wy))
			var rect := ColorRect.new()
			rect.size     = Vector2(tile_size, tile_size)
			rect.position = Vector2(col * tile_size, row * tile_size)
			if vd > thr:
				rect.color = accent_colors[abs(wx * 3 + wy) % accent_colors.size()]
			else:
				rect.color = _noise_to_color(vg, thresholds, grass_colors)
			add_child(rect)

func _noise_to_color(v: float, t: Array, c: Array) -> Color:
	if   v > t[0]: return c[0]
	elif v > t[1]: return c[1]
	elif v > t[2]: return c[2]
	elif v > t[3]: return c[3]
	else:          return c[4]

func clear_chunk() -> void:
	for child in get_children(): child.queue_free()
