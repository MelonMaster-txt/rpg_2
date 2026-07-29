# ground_painter.gd
# Peint le sol d'un chunk via des ColorRect tuiles de 32px
extends Node2D

const TILE_SIZE: int = 32

const GRASS_COLORS := [
	Color(0.22, 0.52, 0.15),
	Color(0.27, 0.58, 0.18),
	Color(0.18, 0.44, 0.12),
	Color(0.24, 0.55, 0.16),
	Color(0.20, 0.48, 0.14),
]
const ACCENT_COLORS := [
	Color(0.30, 0.62, 0.20),
	Color(0.55, 0.52, 0.18),
	Color(0.26, 0.56, 0.40),
]

func paint(chunk_coords: Vector2i, chunk_size: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(chunk_coords.x * 5381 + 1, chunk_coords.y * 9973 + 7))

	# Utilise des floats pour eviter le warning "Integer division"
	var cols: int = int(chunk_size / float(TILE_SIZE))
	var rows: int = int(chunk_size / float(TILE_SIZE))

	for row in rows:
		for col in cols:
			var rect := ColorRect.new()
			rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			rect.position = Vector2(col * TILE_SIZE, row * TILE_SIZE)
			var roll: float = rng.randf()
			if roll < 0.06:
				rect.color = ACCENT_COLORS[rng.randi() % ACCENT_COLORS.size()]
			else:
				rect.color = GRASS_COLORS[rng.randi() % GRASS_COLORS.size()]
			add_child(rect)
