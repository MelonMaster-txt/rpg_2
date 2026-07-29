# ground_painter.gd
# Peint le sol d'un chunk via des ColorRect de 32px.
# Utilise le Perlin noise MONDIAL du ChunkGenerator pour une continuité
# parfaite entre chunks - plus aucune couture visible.
extends Node2D

const TILE_SIZE: int = 32

# Palette herbe indexée par valeur de bruit
# Index 0 = vert clair (hautes valeurs), index N = vert sombre / terre (basses valeurs)
const GRASS_COLORS := [
	Color(0.27, 0.58, 0.18),  # vert clair  (bruit > 0.3)
	Color(0.24, 0.55, 0.16),  # vert neutre (bruit 0.1..0.3)
	Color(0.22, 0.52, 0.15),  # vert moyen  (bruit -0.1..0.1)
	Color(0.18, 0.44, 0.12),  # vert fonce  (bruit -0.3..-0.1)
	Color(0.55, 0.38, 0.18),  # terre       (bruit < -0.3)
]

# Taches d'accent (mousses, fleurs) — déclenchées par bruit detail
const ACCENT_COLORS := [
	Color(0.30, 0.62, 0.20),  # vert brillant
	Color(0.55, 0.52, 0.18),  # brun-vert (mousse)
	Color(0.26, 0.56, 0.40),  # vert bleu
]


func paint(chunk_coords: Vector2i, chunk_size: int) -> void:
	var cg: Node = get_node("/root/ChunkGenerator")

	var cols: int = chunk_size / TILE_SIZE
	var rows: int = chunk_size / TILE_SIZE

	for row in rows:
		for col in cols:
			# Coordonnée MONDE de cette tile
			var wx: int = chunk_coords.x * cols + col
			var wy: int = chunk_coords.y * rows + row

			var v_ground: float  = cg.get_ground_noise(wx, wy)
			var v_detail: float  = cg.get_detail_noise(wx, wy)

			var rect := ColorRect.new()
			rect.size     = Vector2(TILE_SIZE, TILE_SIZE)
			rect.position = Vector2(col * TILE_SIZE, row * TILE_SIZE)

			# Tache d'accent si le bruit de détail est très haut (> 0.55)
			if v_detail > 0.55:
				rect.color = ACCENT_COLORS[abs(wx * 3 + wy) % ACCENT_COLORS.size()]
			else:
				rect.color = _noise_to_color(v_ground)

			add_child(rect)


# Convertit une valeur Perlin (-1..1) en couleur de la palette
func _noise_to_color(v: float) -> Color:
	if v > 0.3:
		return GRASS_COLORS[0]
	elif v > 0.1:
		return GRASS_COLORS[1]
	elif v > -0.1:
		return GRASS_COLORS[2]
	elif v > -0.3:
		return GRASS_COLORS[3]
	else:
		return GRASS_COLORS[4]


func clear_chunk() -> void:
	for child in get_children():
		child.queue_free()
