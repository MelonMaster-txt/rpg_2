# ground_painter.gd
# Peint le sol d'un chunk via des ColorRect de 32px.
# Supporte repaint_with() pour le debug live depuis noise_debug.gd
extends Node2D

const TILE_SIZE: int = 32

const GRASS_COLORS := [
	Color(0.27, 0.58, 0.18),
	Color(0.24, 0.55, 0.16),
	Color(0.22, 0.52, 0.15),
	Color(0.18, 0.44, 0.12),
	Color(0.55, 0.38, 0.18),
]
const ACCENT_COLORS := [
	Color(0.30, 0.62, 0.20),
	Color(0.55, 0.52, 0.18),
	Color(0.26, 0.56, 0.40),
]
const ACCENT_THR   : float = 0.4
const THRESHOLDS   : Array = [0.3, 0.1, -0.1, -0.3]

var _chunk_coords : Vector2i
var _chunk_size   : int

func paint(chunk_coords: Vector2i, chunk_size: int) -> void:
	_chunk_coords = chunk_coords
	_chunk_size   = chunk_size
	add_to_group("ground_painter")
	var cg: Node = get_node("/root/ChunkGenerator")
	_do_paint(chunk_coords, chunk_size,
		cg.ground_noise, cg.detail_noise,
		THRESHOLDS, GRASS_COLORS, ACCENT_COLORS, ACCENT_THR)

## Appelé par noise_debug pour repaint live
func repaint_with(
	noise: FastNoiseLite,
	noise_d: FastNoiseLite,
	thresholds: Array,
	grass_colors: Array,
	accent_colors: Array,
	accent_thr: float
) -> void:
	for child in get_children():
		child.queue_free()
	_do_paint(_chunk_coords, _chunk_size, noise, noise_d, thresholds, grass_colors, accent_colors, accent_thr)


func _do_paint(
	chunk_coords: Vector2i,
	chunk_size: int,
	noise: FastNoiseLite,
	noise_d: FastNoiseLite,
	thresholds: Array,
	grass_colors: Array,
	accent_colors: Array,
	accent_thr: float
) -> void:
	var cols: int = chunk_size / TILE_SIZE
	var rows: int = chunk_size / TILE_SIZE
	for row in rows:
		for col in cols:
			var wx: int = chunk_coords.x * cols + col
			var wy: int = chunk_coords.y * rows + row
			var vg: float = noise.get_noise_2d(wx, wy)
			var vd: float = noise_d.get_noise_2d(wx, wy)
			var rect := ColorRect.new()
			rect.size     = Vector2(TILE_SIZE, TILE_SIZE)
			rect.position = Vector2(col * TILE_SIZE, row * TILE_SIZE)
			if vd > accent_thr:
				rect.color = accent_colors[abs(wx * 3 + wy) % accent_colors.size()]
			else:
				rect.color = _noise_to_color(vg, thresholds, grass_colors)
			add_child(rect)


func _noise_to_color(v: float, thresholds: Array, grass_colors: Array) -> Color:
	if   v > thresholds[0]: return grass_colors[0]
	elif v > thresholds[1]: return grass_colors[1]
	elif v > thresholds[2]: return grass_colors[2]
	elif v > thresholds[3]: return grass_colors[3]
	else:                   return grass_colors[4]


func clear_chunk() -> void:
	for child in get_children():
		child.queue_free()
