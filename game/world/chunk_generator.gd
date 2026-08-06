# chunk_generator.gd - Autoload
# Gère la seed mondiale et fournit le bruit Perlin GLOBAL
# Le même FastNoiseLite est utilisé pour TOUS les chunks → continuité parfaite
extends Node

var world_seed: int = 0

# Bruit principal pour les biomes de sol (herbe dense/clairsemée/terre)
var noise_ground: FastNoiseLite = null
# Bruit secondaire pour la densité des arbres
var noise_trees: FastNoiseLite = null
# Bruit tertiaire pour les détails (pierres, fleurs)
var noise_details: FastNoiseLite = null

func _ready() -> void:
	# Seed aléatoire à chaque partie
	world_seed = randi()
	_init_noises()

func set_world_seed(new_seed: int) -> void:
	world_seed = new_seed
	_init_noises()

func _init_noises() -> void:
	# --- Bruit de sol ---
	noise_ground = FastNoiseLite.new()
	noise_ground.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_ground.seed = world_seed
	noise_ground.frequency = 0.018      # Grandes zones cohérentes
	noise_ground.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_ground.fractal_octaves = 4
	noise_ground.fractal_lacunarity = 2.0
	noise_ground.fractal_gain = 0.5

	# --- Bruit d'arbres ---
	noise_trees = FastNoiseLite.new()
	noise_trees.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_trees.seed = world_seed + 1
	noise_trees.frequency = 0.03
	noise_trees.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_trees.fractal_octaves = 3
	noise_trees.fractal_gain = 0.4

	# --- Bruit de détails (pierres, fleurs) ---
	noise_details = FastNoiseLite.new()
	noise_details.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_details.seed = world_seed + 2
	noise_details.frequency = 0.06
	noise_details.fractal_type = FastNoiseLite.FRACTAL_NONE

# Retourne la valeur de bruit de sol en coordonnées MONDE (tile globale)
# Valeur entre -1.0 et 1.0
func get_ground_noise(world_tile_x: int, world_tile_y: int) -> float:
	return noise_ground.get_noise_2d(float(world_tile_x), float(world_tile_y))

func get_tree_noise(world_tile_x: int, world_tile_y: int) -> float:
	return noise_trees.get_noise_2d(float(world_tile_x), float(world_tile_y))

func get_detail_noise(world_tile_x: int, world_tile_y: int) -> float:
	return noise_details.get_noise_2d(float(world_tile_x), float(world_tile_y))

# Type de chunk selon position (inchangé)
func get_chunk_type(coords: Vector2i) -> String:
	if coords == Vector2i(0, 0):
		return "hut"
	return "forest"

# Nombre de chunks chargés (pour le debug menu)
func get_loaded_chunk_count() -> int:
	if has_node("/root/ChunkManager"):
		var cm: Node = get_node("/root/ChunkManager")
		if cm.has_method("get_loaded_count"):
			return cm.get_loaded_count()
	return 0
