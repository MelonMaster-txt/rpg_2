# forest_chunk_base.gd
# Génère les ressources d'un chunk forêt de manière naturelle :
#  - Champignons apparaissent près des arbres (zone humide/ombragée)
#  - Silex dans les clusters rocheux
#  - Herbes dans les clairières (loin des arbres)
#  - Résine sur les arbres (même position, récoltable séparément)
#  - Os dispersés aléatoirement (faible densité)
#  - Anti-overlap : distance minimale entre toutes les ressources
#  - Zone protégée autour de la cahute (chunk 0,0)
#  - Spawn différé : 1 ressource par frame pour ne pas freezer
extends Node2D

@export var tree_count_min:     int = 5
@export var tree_count_max:     int = 12
@export var berry_count_min:    int = 1
@export var berry_count_max:    int = 4
@export var stone_count_min:    int = 1
@export var stone_count_max:    int = 3
@export var mushroom_count_min: int = 0
@export var mushroom_count_max: int = 3
@export var flint_count_min:    int = 0
@export var flint_count_max:    int = 2
@export var herb_count_min:     int = 0
@export var herb_count_max:     int = 3
@export var resin_count_min:    int = 0
@export var resin_count_max:    int = 2
@export var bone_count_min:     int = 0
@export var bone_count_max:     int = 1

const TREE_SCENE     := "res://game/world/scenes/resources_node/tree_node.tscn"
const BERRY_SCENE    := "res://game/world/scenes/resources_node/berry_node.tscn"
const STONE_SCENE    := "res://game/world/scenes/resources_node/stone_node.tscn"
const GENERIC_SCENE  := "res://game/world/scenes/resources_node/resource_node.tscn"
const GROUND_SCRIPT  := "res://game/world/ground_painter.gd"

# Distance minimale entre deux ressources (pixels)
const MIN_RESOURCE_DIST: float = 36.0
# Distance minimale entre une ressource et le bord du chunk
const BORDER_MARGIN: float = 48.0
# Rayon protégé autour du centre du chunk (0,0) = cahute
const HUT_PROTECTION_RADIUS: float = 160.0
# Rayon max autour d'un arbre pour spawner un champignon / résine
const MUSHROOM_TREE_RADIUS: float = 60.0
# Distance minimale d'un champignon par rapport aux clairières (doit être proche arbre)
const MUSHROOM_MIN_TREE_DIST: float = 20.0
# Distance minimale d'une herbe par rapport aux arbres (clairière)
const HERB_MIN_CLEAR_DIST: float = 50.0

var _chunk_coords: Vector2i = Vector2i.ZERO
var _chunk_size:   int      = 512
var _spawn_queue:  Array    = []
# Positions occupées pour anti-overlap [Vector2, ...]
var _occupied: Array        = []

static var _tree_scene_cache:    PackedScene = null
static var _berry_scene_cache:   PackedScene = null
static var _stone_scene_cache:   PackedScene = null
static var _generic_scene_cache: PackedScene = null


func setup(coords: Vector2i, size: int) -> void:
	_chunk_coords = coords
	_chunk_size   = size
	_ensure_scene_cache()
	_paint_ground()
	_build_spawn_queue()
	call_deferred("_spawn_next")


static func _ensure_scene_cache() -> void:
	if _tree_scene_cache    == null: _tree_scene_cache    = load(TREE_SCENE)    as PackedScene
	if _berry_scene_cache   == null: _berry_scene_cache   = load(BERRY_SCENE)   as PackedScene
	if _stone_scene_cache   == null: _stone_scene_cache   = load(STONE_SCENE)   as PackedScene
	if _generic_scene_cache == null:
		if ResourceLoader.exists(GENERIC_SCENE):
			_generic_scene_cache = load(GENERIC_SCENE) as PackedScene


func _paint_ground() -> void:
	var script: GDScript = load(GROUND_SCRIPT) as GDScript
	if script == null:
		push_error("forest_chunk_base: ground_painter.gd introuvable")
		return
	var painter := Node2D.new()
	painter.set_script(script)
	painter.name    = "Ground"
	painter.z_index = -10
	add_child(painter)
	painter.paint(_chunk_coords, _chunk_size)


# ─── HELPERS POSITIONNEMENT ────────────────────────────────────────────────────

# Vérifie qu'une position ne chevauche pas les positions déjà occupées
func _is_position_free(pos: Vector2, min_dist: float = MIN_RESOURCE_DIST) -> bool:
	for occ in _occupied:
		if pos.distance_to(occ) < min_dist:
			return false
	return true

# Vérifie que la position n'est pas dans la zone protégée de la cahute
func _is_outside_hut_zone(pos: Vector2) -> bool:
	if _chunk_coords != Vector2i(0, 0):
		return true
	var center: Vector2 = Vector2(_chunk_size * 0.5, _chunk_size * 0.5)
	return pos.distance_to(center) > HUT_PROTECTION_RADIUS

# Tente de trouver une position libre aléatoire dans le chunk
# Retourne Vector2(-1,-1) si aucune position libre trouvée après max_tries
func _random_free_pos(rng: RandomNumberGenerator, max_tries: int = 20,
		min_dist: float = MIN_RESOURCE_DIST) -> Vector2:
	var margin: float = BORDER_MARGIN
	for _i in max_tries:
		var pos := Vector2(
			rng.randf_range(margin, _chunk_size - margin),
			rng.randf_range(margin, _chunk_size - margin)
		)
		if _is_position_free(pos, min_dist) and _is_outside_hut_zone(pos):
			return pos
	return Vector2(-1.0, -1.0)

# Tente de trouver une position libre proche d'un des points anchor (ex: arbres)
func _random_near_anchor(rng: RandomNumberGenerator, anchors: Array,
		radius: float, min_dist: float = MIN_RESOURCE_DIST,
		max_tries: int = 20) -> Vector2:
	if anchors.is_empty():
		return Vector2(-1.0, -1.0)
	for _i in max_tries:
		var anchor: Vector2 = anchors[rng.randi() % anchors.size()]
		var angle: float    = rng.randf() * TAU
		var dist: float     = rng.randf_range(MUSHROOM_MIN_TREE_DIST, radius)
		var pos: Vector2    = anchor + Vector2(cos(angle), sin(angle)) * dist
		# Garder dans les limites du chunk
		pos.x = clamp(pos.x, BORDER_MARGIN, _chunk_size - BORDER_MARGIN)
		pos.y = clamp(pos.y, BORDER_MARGIN, _chunk_size - BORDER_MARGIN)
		if _is_position_free(pos, min_dist) and _is_outside_hut_zone(pos):
			return pos
	return Vector2(-1.0, -1.0)

# Tente de trouver une position en clairière (loin de tous les arbres)
func _random_clearing_pos(rng: RandomNumberGenerator, tree_positions: Array,
		min_tree_dist: float = HERB_MIN_CLEAR_DIST,
		max_tries: int = 25) -> Vector2:
	var margin: float = BORDER_MARGIN
	for _i in max_tries:
		var pos := Vector2(
			rng.randf_range(margin, _chunk_size - margin),
			rng.randf_range(margin, _chunk_size - margin)
		)
		if not _is_outside_hut_zone(pos):
			continue
		if not _is_position_free(pos):
			continue
		# Vérifier distance à tous les arbres
		var far_enough: bool = true
		for tp in tree_positions:
			if pos.distance_to(tp) < min_tree_dist:
				far_enough = false
				break
		if far_enough:
			return pos
	return Vector2(-1.0, -1.0)


# ─── CONSTRUCTION DE LA FILE DE SPAWN ─────────────────────────────────────────

func _build_spawn_queue() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(_chunk_coords.x * 73856093, _chunk_coords.y * 19349663))

	_spawn_queue.clear()
	_occupied.clear()

	# ── 1. ARBRES (base de tout l'écosystème) ──────────────────────────────────
	var tree_count:  int = rng.randi_range(tree_count_min, tree_count_max)
	var tree_positions: Array = []

	for _i in tree_count:
		var pos: Vector2 = _random_free_pos(rng, 30, MIN_RESOURCE_DIST * 1.5)
		if pos.x < 0.0:
			continue
		tree_positions.append(pos)
		_occupied.append(pos)
		_spawn_queue.append({"scene": _tree_scene_cache, "pos": pos,
			"type": "", "name": ""})

	# ── 2. BAIES (petits arbustes, milieu densité) ─────────────────────────────
	var berry_count: int = rng.randi_range(berry_count_min, berry_count_max)
	for _i in berry_count:
		var pos: Vector2 = _random_free_pos(rng)
		if pos.x < 0.0:
			continue
		_occupied.append(pos)
		_spawn_queue.append({"scene": _berry_scene_cache, "pos": pos,
			"type": "", "name": ""})

	# ── 3. PIERRES (clusters rocheux, légèrement regroupées) ───────────────────
	var stone_count: int  = rng.randi_range(stone_count_min, stone_count_max)
	var stone_positions: Array = []
	var cluster_center: Vector2 = _random_free_pos(rng, 15, MIN_RESOURCE_DIST * 3)
	if cluster_center.x >= 0.0:
		for _i in stone_count:
			# Les pierres se regroupent en cluster (rayon 80px)
			var angle: float = rng.randf() * TAU
			var dist: float  = rng.randf_range(0.0, 80.0)
			var pos: Vector2 = cluster_center + Vector2(cos(angle), sin(angle)) * dist
			pos.x = clamp(pos.x, BORDER_MARGIN, _chunk_size - BORDER_MARGIN)
			pos.y = clamp(pos.y, BORDER_MARGIN, _chunk_size - BORDER_MARGIN)
			if not _is_position_free(pos) or not _is_outside_hut_zone(pos):
				continue
			stone_positions.append(pos)
			_occupied.append(pos)
			_spawn_queue.append({"scene": _stone_scene_cache, "pos": pos,
				"type": "", "name": ""})

	# ── 4. CHAMPIGNONS (près des arbres, zones humides/ombragées) ──────────────
	if not tree_positions.is_empty():
		var mushroom_count: int = rng.randi_range(mushroom_count_min, mushroom_count_max)
		for _i in mushroom_count:
			var pos: Vector2 = _random_near_anchor(rng, tree_positions,
					MUSHROOM_TREE_RADIUS, MIN_RESOURCE_DIST * 0.8)
			if pos.x < 0.0:
				continue
			_occupied.append(pos)
			_spawn_queue.append({"scene": _generic_scene_cache, "pos": pos,
				"type": "mushroom", "name": "Champignon"})

	# ── 5. SILEX (près des clusters de pierres) ────────────────────────────────
	var flint_count: int = rng.randi_range(flint_count_min, flint_count_max)
	if not stone_positions.is_empty():
		for _i in flint_count:
			var pos: Vector2 = _random_near_anchor(rng, stone_positions,
					55.0, MIN_RESOURCE_DIST * 0.8)
			if pos.x < 0.0:
				continue
			_occupied.append(pos)
			_spawn_queue.append({"scene": _generic_scene_cache, "pos": pos,
				"type": "flint", "name": "Silex"})
	else:
		# Pas de pierres : silex en position libre
		for _i in flint_count:
			var pos: Vector2 = _random_free_pos(rng)
			if pos.x < 0.0:
				continue
			_occupied.append(pos)
			_spawn_queue.append({"scene": _generic_scene_cache, "pos": pos,
				"type": "flint", "name": "Silex"})

	# ── 6. HERBES (clairières, loin des arbres) ────────────────────────────────
	var herb_count: int = rng.randi_range(herb_count_min, herb_count_max)
	for _i in herb_count:
		var pos: Vector2
		if not tree_positions.is_empty():
			pos = _random_clearing_pos(rng, tree_positions)
		else:
			pos = _random_free_pos(rng)
		if pos.x < 0.0:
			continue
		_occupied.append(pos)
		_spawn_queue.append({"scene": _generic_scene_cache, "pos": pos,
			"type": "herb", "name": "Herbe Médicinale"})

	# ── 7. RÉSINE (directement sur/près des arbres) ────────────────────────────
	var resin_count: int = rng.randi_range(resin_count_min, resin_count_max)
	if not tree_positions.is_empty():
		for _i in resin_count:
			# Résine très proche de l'arbre (rayon 25px)
			var pos: Vector2 = _random_near_anchor(rng, tree_positions,
					25.0, MIN_RESOURCE_DIST * 0.5, 15)
			if pos.x < 0.0:
				continue
			_occupied.append(pos)
			_spawn_queue.append({"scene": _generic_scene_cache, "pos": pos,
				"type": "resin", "name": "Résine"})

	# ── 8. OS (dispersés, faible densité — restes d'animaux) ──────────────────
	var bone_count: int = rng.randi_range(bone_count_min, bone_count_max)
	for _i in bone_count:
		var pos: Vector2 = _random_free_pos(rng, 15)
		if pos.x < 0.0:
			continue
		_occupied.append(pos)
		_spawn_queue.append({"scene": _generic_scene_cache, "pos": pos,
			"type": "bone", "name": "Os"})


# ─── SPAWN DIFFÉRÉ (1 ressource par frame) ────────────────────────────────────

func _spawn_next() -> void:
	if _spawn_queue.is_empty():
		_occupied.clear()  # Libère la mémoire une fois le spawn terminé
		return

	var data: Dictionary   = _spawn_queue.pop_front()
	var scene: PackedScene = data["scene"]
	var pos: Vector2       = data["pos"]
	var rtype: String      = data["type"]
	var rname: String      = data["name"]

	if scene != null:
		var inst := scene.instantiate() as Node2D
		inst.position = pos
		# Pour les ressources génériques, configurer le type et le nom
		if rtype != "" and inst.has_method("set"):
			if "resource_type" in inst:
				inst.set("resource_type", rtype)
			if "resource_name" in inst and rname != "":
				inst.set("resource_name", rname)
			# Paramètres par type
			_apply_type_params(inst, rtype)
		add_child(inst)

	if not _spawn_queue.is_empty():
		call_deferred("_spawn_next")
	else:
		_occupied.clear()


# Applique les paramètres spécifiques à chaque type de ressource
func _apply_type_params(inst: Node2D, rtype: String) -> void:
	match rtype:
		"mushroom":
			if "max_health"     in inst: inst.set("max_health",     1)
			if "gather_amount"  in inst: inst.set("gather_amount",  1)
			if "respawn_time"   in inst: inst.set("respawn_time",   20.0)
			if "respawn_scatter" in inst: inst.set("respawn_scatter", 30.0)
		"flint":
			if "max_health"     in inst: inst.set("max_health",     2)
			if "gather_amount"  in inst: inst.set("gather_amount",  1)
			if "respawn_time"   in inst: inst.set("respawn_time",   60.0)
			if "respawn_scatter" in inst: inst.set("respawn_scatter", 20.0)
		"herb":
			if "max_health"     in inst: inst.set("max_health",     1)
			if "gather_amount"  in inst: inst.set("gather_amount",  2)
			if "respawn_time"   in inst: inst.set("respawn_time",   30.0)
			if "respawn_scatter" in inst: inst.set("respawn_scatter", 50.0)
		"resin":
			if "max_health"     in inst: inst.set("max_health",     2)
			if "gather_amount"  in inst: inst.set("gather_amount",  1)
			if "respawn_time"   in inst: inst.set("respawn_time",   45.0)
			if "respawn_scatter" in inst: inst.set("respawn_scatter", 15.0)
		"bone":
			if "max_health"     in inst: inst.set("max_health",     1)
			if "gather_amount"  in inst: inst.set("gather_amount",  1)
			if "respawn_time"   in inst: inst.set("respawn_time",   90.0)
			if "respawn_scatter" in inst: inst.set("respawn_scatter", 80.0)
