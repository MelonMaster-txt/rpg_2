extends Node2D

const CHUNK_NODE_SCENE: PackedScene = preload("res://game/world/chunk_node.tscn")

@export var chunk_size: int = 512
@export var load_radius: int = 1
@export var preload_radius: int = 1
@export var debug_draw_chunks: bool = true
@export var debug_draw_player_chunk_text: bool = true

var loaded_chunks: Dictionary = {}
var player: Node2D = null
var last_player_chunk: Vector2i = Vector2i(999999, 999999)

func _ready() -> void:
	player = find_player()
	print("ChunkManager ready. player =", player, "chunk_size =", chunk_size, "load_radius =", load_radius)

	if player != null:
		var start_chunk := world_to_chunk(player.global_position)
		preload_chunks(start_chunk, preload_radius)

	update_chunks()
	queue_redraw()

func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = find_player()

	update_chunks()
	queue_redraw()

func find_player() -> Node2D:
	var direct_player: Node = get_node_or_null("../PlayerContainer/Player")
	if direct_player != null and direct_player is Node2D:
		return direct_player as Node2D

	var players: Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Node2D:
		return players[0] as Node2D

	return null

func preload_chunks(center_chunk: Vector2i, radius: int) -> void:
	for x in range(center_chunk.x - radius, center_chunk.x + radius + 1):
		for y in range(center_chunk.y - radius, center_chunk.y + radius + 1):
			var coords := Vector2i(x, y)
			if not loaded_chunks.has(coords):
				load_chunk(coords)

func update_chunks() -> void:
	if player == null:
		return

	var current_chunk := world_to_chunk(player.global_position)

	if current_chunk != last_player_chunk:
		print("Player chunk changed:", last_player_chunk, "->", current_chunk, "player_pos =", player.global_position)
		last_player_chunk = current_chunk

	var needed_chunks: Array[Vector2i] = []

	for x in range(current_chunk.x - load_radius, current_chunk.x + load_radius + 1):
		for y in range(current_chunk.y - load_radius, current_chunk.y + load_radius + 1):
			needed_chunks.append(Vector2i(x, y))

	for coords in needed_chunks:
		if not loaded_chunks.has(coords):
			load_chunk(coords)

	var to_unload: Array[Vector2i] = []
	for coords in loaded_chunks.keys():
		if not needed_chunks.has(coords):
			to_unload.append(coords)

	for coords in to_unload:
		unload_chunk(coords)

func world_to_chunk(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / chunk_size),
		floori(world_pos.y / chunk_size)
	)

func chunk_to_world_top_left(coords: Vector2i) -> Vector2:
	return Vector2(coords.x * chunk_size, coords.y * chunk_size)

func chunk_to_world_center(coords: Vector2i) -> Vector2:
	return Vector2(
		coords.x * chunk_size + chunk_size * 0.5,
		coords.y * chunk_size + chunk_size * 0.5
	)

func load_chunk(coords: Vector2i) -> void:
	var chunk: Node2D = CHUNK_NODE_SCENE.instantiate()
	var chunk_type: String = ChunkGenerator.get_chunk_type(coords)

	chunk.name = "Chunk_%s_%s" % [coords.x, coords.y]
	add_child(chunk)
	chunk.setup(coords, chunk_size, chunk_type)
	loaded_chunks[coords] = chunk

	print("LOAD chunk", coords, "type =", chunk_type)

func unload_chunk(coords: Vector2i) -> void:
	if not loaded_chunks.has(coords):
		return

	var chunk: Node = loaded_chunks[coords]
	if is_instance_valid(chunk):
		chunk.queue_free()

	loaded_chunks.erase(coords)
	print("DELOAD chunk", coords)

func _draw() -> void:
	if not debug_draw_chunks:
		return

	for coords in loaded_chunks.keys():
		var top_left := chunk_to_world_top_left(coords)
		var rect := Rect2(top_left, Vector2(chunk_size, chunk_size))

		draw_rect(rect, Color(0.0, 1.0, 0.0, 0.05), true)
		draw_rect(rect, Color(0.0, 1.0, 0.0, 0.9), false, 2.0)

		var center := chunk_to_world_center(coords)
		draw_circle(center, 5.0, Color(1.0, 0.2, 0.2, 1.0))

		# Dans _draw(), remplace la ligne problématique :
		var chunk_type := "unknown"
		if Engine.has_singleton("ChunkGenerator"):
			chunk_type = ChunkGenerator.get_chunk_type(coords)

		var label := "Chunk " + str(coords) + " / " + chunk_type
		draw_string(
			ThemeDB.fallback_font,
			top_left + Vector2(16, 24),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			16,
			Color(1, 1, 1, 1)
		)

	if debug_draw_player_chunk_text and player != null:
		var player_chunk := world_to_chunk(player.global_position)
		var text := "Player chunk: " + str(player_chunk) + " | pos: " + str(player.global_position)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(20, 20),
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			18,
			Color(1.0, 0.9, 0.2, 1.0)
		)
