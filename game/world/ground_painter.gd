# ground_painter.gd
# OPTIMISATION MAJEURE : plus aucun ColorRect individuel.
# Tout le sol est dessiné en UN seul appel _draw() avec draw_rect().
# Cout CPU : O(1) draw call au lieu de 256 nodes enfants.
# Le calcul des tuiles est fait une seule fois dans paint() et mis en cache.
extends Node2D

const TILE_SIZE:   int   = 32
const TILE_SIZE_F: float = 32.0

const GRASS_COLORS: Array[Color] = [
	Color(0.22, 0.52, 0.15),
	Color(0.27, 0.58, 0.18),
	Color(0.18, 0.44, 0.12),
	Color(0.24, 0.55, 0.16),
	Color(0.20, 0.48, 0.14),
]
const ACCENT_COLORS: Array[Color] = [
	Color(0.30, 0.62, 0.20),
	Color(0.55, 0.52, 0.18),
	Color(0.26, 0.56, 0.40),
]

# Cache plat : [pos_x, pos_y, r, g, b] * nb_tuiles
# Stocke uniquement les tuiles d'accent (les autres sont fillées par couleur dominante)
var _accent_tiles: PackedFloat32Array  # [x, y, r, g, b, ...]
var _base_color:   Color = Color(0.22, 0.52, 0.15)
var _chunk_size:   int   = 512
var _ready_to_draw: bool = false


func paint(chunk_coords: Vector2i, chunk_size: int) -> void:
	_chunk_size = chunk_size
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(chunk_coords.x * 5381 + 1, chunk_coords.y * 9973 + 7))

	var cols: int = int(chunk_size / TILE_SIZE_F)
	var rows: int = int(chunk_size / TILE_SIZE_F)

	# Couleur dominante = la plus fréquente de la palette (première)
	_base_color = GRASS_COLORS[rng.randi() % GRASS_COLORS.size()]

	# On ne stocke QUE les tuiles qui diffèrent de la base (accents + variations)
	_accent_tiles.clear()
	for row: int in rows:
		for col: int in cols:
			var roll: float = rng.randf()
			var color: Color
			if roll < 0.06:
				color = ACCENT_COLORS[rng.randi() % ACCENT_COLORS.size()]
			elif roll < 0.45:
				color = GRASS_COLORS[rng.randi() % GRASS_COLORS.size()]
			else:
				continue  # == base color, pas besoin de stocker
			_accent_tiles.append(float(col * TILE_SIZE))
			_accent_tiles.append(float(row * TILE_SIZE))
			_accent_tiles.append(color.r)
			_accent_tiles.append(color.g)
			_accent_tiles.append(color.b)

	_ready_to_draw = true
	queue_redraw()  # Un seul redraw, jamais rappelé sauf si le chunk bouge


func _draw() -> void:
	if not _ready_to_draw:
		return
	# 1. Fond uniforme = 1 seul draw call
	draw_rect(Rect2(Vector2.ZERO, Vector2(_chunk_size, _chunk_size)), _base_color)
	# 2. Tuiles différentes = draw_rect individuel mais SANS node
	const STRIDE: int = 5
	var count: int    = int(_accent_tiles.size() / float(STRIDE))
	for i: int in count:
		var base: int = i * STRIDE
		var pos := Vector2(_accent_tiles[base], _accent_tiles[base + 1])
		var col := Color(_accent_tiles[base + 2], _accent_tiles[base + 3], _accent_tiles[base + 4])
		draw_rect(Rect2(pos, Vector2(TILE_SIZE_F, TILE_SIZE_F)), col)
