# ground_painter.gd
# Peint les tiles de sol d'un chunk en utilisant le Perlin noise MONDIAL
# du ChunkGenerator → continuité parfaite entre chunks, zéro couture visible.
#
# SEUILS DE SOL (valeur bruit -1..1) :
#   < -0.25  → terre nue        (atlas 0,2)
#   -0.25..0.05 → herbe clairsemée (atlas 0,1)
#   >= 0.05  → herbe dense      (atlas 0,0)
#
# Le peintre utilise les COORDONNÉES MONDE de chaque tile, pas des coords locales.
extends Node

# Taille d'un chunk en tiles
const CHUNK_SIZE: int = 16
# Taille d'une tile en pixels
const TILE_SIZE: int = 32

# IDs de tiles dans le TileSet (à ajuster selon ton atlas)
const TILE_GRASS_DENSE:   Vector2i = Vector2i(0, 0)
const TILE_GRASS_SPARSE:  Vector2i = Vector2i(0, 1)
const TILE_DIRT:          Vector2i = Vector2i(0, 2)
const TILE_LAYER: int = 0

# Référence au TileMapLayer du chunk parent
@export var tilemap: NodePath = NodePath("TileMapLayer")

var _tilemap_node: TileMapLayer

func _ready() -> void:
	_tilemap_node = get_node_or_null(tilemap)

# Peint toutes les tiles d'un chunk.
# chunk_coords : position du chunk dans la grille de chunks (ex: Vector2i(2,-1))
func paint_chunk(chunk_coords: Vector2i) -> void:
	if not _tilemap_node:
		push_error("GroundPainter: TileMapLayer introuvable sur '%s'" % tilemap)
		return

	var cg: Node = get_node("/root/ChunkGenerator")

	for local_y in CHUNK_SIZE:
		for local_x in CHUNK_SIZE:
			# Coordonnée MONDE de cette tile
			var wx: int = chunk_coords.x * CHUNK_SIZE + local_x
			var wy: int = chunk_coords.y * CHUNK_SIZE + local_y

			var v: float = cg.get_ground_noise(wx, wy)
			var atlas_coords: Vector2i = _noise_to_tile(v)

			_tilemap_node.set_cell(
				Vector2i(local_x, local_y),
				TILE_LAYER,
				atlas_coords
			)

# Convertit une valeur de bruit (-1..1) en coordonnées d'atlas
func _noise_to_tile(v: float) -> Vector2i:
	if v < -0.25:
		return TILE_DIRT
	elif v < 0.05:
		return TILE_GRASS_SPARSE
	else:
		return TILE_GRASS_DENSE

# Efface toutes les tiles du chunk (utile pour le pooling)
func clear_chunk() -> void:
	if _tilemap_node:
		_tilemap_node.clear()
