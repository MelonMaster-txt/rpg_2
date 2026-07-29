# ground_painter.gd
# Peint le sol d'un chunk via des ColorRect tuiles de 32px.
# OPTIMISATION : les ColorRect sont créés par petits paquets (BATCH_SIZE)
# via call_deferred pour ne pas bloquer le rendu en une seule frame.
extends Node2D

const TILE_SIZE: int = 32
## Nombre de tuiles créées par frame lors du batch painting
const BATCH_SIZE: int = 32

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

# Données précalculées pour le batch
var _pending_tiles: Array = []   # Array de [Vector2, Color]
var _batch_index: int = 0
var _painting_done: bool = false


func paint(chunk_coords: Vector2i, chunk_size: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(chunk_coords.x * 5381 + 1, chunk_coords.y * 9973 + 7))

	var cols: int = int(chunk_size / float(TILE_SIZE))
	var rows: int = int(chunk_size / float(TILE_SIZE))

	# Précalcule toutes les tuiles (positions + couleurs) sans créer de nodes
	_pending_tiles.clear()
	_batch_index = 0
	_painting_done = false

	for row in rows:
		for col in cols:
			var pos := Vector2(col * TILE_SIZE, row * TILE_SIZE)
			var color: Color
			if rng.randf() < 0.06:
				color = ACCENT_COLORS[rng.randi() % ACCENT_COLORS.size()]
			else:
				color = GRASS_COLORS[rng.randi() % GRASS_COLORS.size()]
			_pending_tiles.append([pos, color])

	# Lance le premier batch différé
	call_deferred("_paint_batch")


func _paint_batch() -> void:
	if _painting_done:
		return
	var end := mini(_batch_index + BATCH_SIZE, _pending_tiles.size())
	for i in range(_batch_index, end):
		var data: Array = _pending_tiles[i]
		var rect := ColorRect.new()
		rect.size = Vector2(TILE_SIZE, TILE_SIZE)
		rect.position = data[0]
		rect.color = data[1]
		add_child(rect)
	_batch_index = end
	if _batch_index >= _pending_tiles.size():
		_painting_done = true
		_pending_tiles.clear()
		return
	# Planifie le batch suivant à la prochaine frame
	call_deferred("_paint_batch")
