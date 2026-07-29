# ground_painter.gd
# Peint les tiles de sol d'un chunk en utilisant le Perlin noise MONDIAL
# du ChunkGenerator → continuité parfaite entre chunks, zéro couture visible.
#
# SEUILS DE SOL (valeur bruit -1..1) :
#   < -0.25  → terre nue        (atlas 0,2)
#   -0.25..0.05 → herbe clairsemée (atlas 0,1)
#   >= 0.05  → herbe dense      (atlas 0,0)
extends Node

const CHUNK_SIZE: int = 16
const TILE_LAYER: int = 0

const TILE_GRASS_DENSE:  Vector2i = Vector2i(0, 0)
const TILE_GRASS_SPARSE: Vector2i = Vector2i(0, 1)
const TILE_DIRT:         Vector2i = Vector2i(0, 2)


func paint_chunk(chunk_coords: Vector2i) -> void:
	# Cherche le TileMapLayer dans le parent ou ses enfants
	var tm: TileMapLayer = _find_tilemap()
	if not tm:
		push_error("GroundPainter: aucun TileMapLayer trouvé dans le chunk '%s'" % get_parent().name)
		return

	var cg: Node = get_node("/root/ChunkGenerator")

	for local_y in CHUNK_SIZE:
		for local_x in CHUNK_SIZE:
			var wx: int = chunk_coords.x * CHUNK_SIZE + local_x
			var wy: int = chunk_coords.y * CHUNK_SIZE + local_y
			var v: float = cg.get_ground_noise(wx, wy)
			tm.set_cell(Vector2i(local_x, local_y), TILE_LAYER, _noise_to_tile(v))


func _find_tilemap() -> TileMapLayer:
	var parent: Node = get_parent()
	if not parent:
		return null
	# Cas 1 : le parent lui-même est un TileMapLayer
	if parent is TileMapLayer:
		return parent as TileMapLayer
	# Cas 2 : cherche parmi les enfants directs du parent
	for child in parent.get_children():
		if child is TileMapLayer:
			return child as TileMapLayer
	# Cas 3 : cherche récursivement dans tout le sous-arbre
	return _find_tilemap_recursive(parent)


func _find_tilemap_recursive(node: Node) -> TileMapLayer:
	for child in node.get_children():
		if child is TileMapLayer:
			return child as TileMapLayer
		var result: TileMapLayer = _find_tilemap_recursive(child)
		if result:
			return result
	return null


func _noise_to_tile(v: float) -> Vector2i:
	if v < -0.25:
		return TILE_DIRT
	elif v < 0.05:
		return TILE_GRASS_SPARSE
	else:
		return TILE_GRASS_DENSE


func clear_chunk() -> void:
	var tm: TileMapLayer = _find_tilemap()
	if tm:
		tm.clear()
