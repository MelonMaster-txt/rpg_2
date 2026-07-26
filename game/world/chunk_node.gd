@tool
extends Node2D

const HUT_CHUNK_SCENE: PackedScene = preload("res://game/world/scenes/hut_chunk.tscn")
const FOREST_CHUNK_SCENE: PackedScene = preload("res://game/world/scenes/forest_chunk.tscn") # ADAPTE ICI

@export var chunk_coords: Vector2i = Vector2i.ZERO:
	set(value):
		chunk_coords = value
		update_editor_position()
		if Engine.is_editor_hint():
			queue_redraw()

@export var chunk_size: int = 512:
	set(value):
		chunk_size = value
		update_editor_position()
		if Engine.is_editor_hint():
			queue_redraw()

@export var chunk_type: String = "forest":
	set(value):
		chunk_type = value
		if Engine.is_editor_hint():
			queue_redraw()

@export var debug_draw_chunk_bounds: bool = true:
	set(value):
		debug_draw_chunk_bounds = value
		if Engine.is_editor_hint():
			queue_redraw()

@onready var content: Node2D = $Content

func _ready() -> void:
	update_editor_position()
	if Engine.is_editor_hint():
		queue_redraw()

func setup(coords: Vector2i, size: int, new_chunk_type: String) -> void:
	chunk_coords = coords
	chunk_size = size
	chunk_type = new_chunk_type

	position = Vector2(coords.x * size, coords.y * size)
	name = "ChunkNode_%s_%s_%s" % [coords.x, coords.y, chunk_type]

	load_content_scene()
	queue_redraw()

func update_editor_position() -> void:
	position = Vector2(chunk_coords.x * chunk_size, chunk_coords.y * chunk_size)

func clear_content() -> void:
	if content == null:
		push_error("ChunkNode has no child named 'Content'")
		return

	for child in content.get_children():
		child.queue_free()

func load_content_scene() -> void:
	if content == null:
		push_error("ChunkNode has no child named 'Content'")
		return

	clear_content()

	var scene_to_instance: PackedScene = null

	if chunk_type == "hut":
		scene_to_instance = HUT_CHUNK_SCENE
	else:
		scene_to_instance = FOREST_CHUNK_SCENE

	if scene_to_instance == null:
		push_error("No PackedScene for chunk_type = " + chunk_type)
		return

	var instance: Node = scene_to_instance.instantiate()
	if instance == null:
		push_error("Failed to instantiate scene for chunk_type = " + chunk_type)
		return

	instance.name = "ChunkContent_" + chunk_type
	content.add_child(instance)

	print("ChunkNode", chunk_coords, "added content instance:", instance.name, "children_in_content =", content.get_child_count())

	if instance.has_method("setup_chunk"):
		instance.call("setup_chunk", chunk_coords, chunk_size, chunk_type)

func _draw() -> void:
	if not debug_draw_chunk_bounds:
		return

	var rect := Rect2(Vector2.ZERO, Vector2(chunk_size, chunk_size))

	draw_rect(rect, Color(1.0, 0.0, 0.0, 0.04), true)
	draw_rect(rect, Color(1.0, 0.0, 0.0, 0.9), false, 2.0)

	var center := Vector2(chunk_size * 0.5, chunk_size * 0.5)
	draw_circle(center, 6.0, Color(1.0, 0.2, 0.2, 1.0))
	draw_line(center + Vector2(-20, 0), center + Vector2(20, 0), Color(1.0, 0.2, 0.2, 1.0), 2.0)
	draw_line(center + Vector2(0, -20), center + Vector2(0, 20), Color(1.0, 0.2, 0.2, 1.0), 2.0)

	var label := "Chunk " + str(chunk_coords) + " / " + chunk_type
	draw_string(
		ThemeDB.fallback_font,
		Vector2(16, 24),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color(1, 1, 1, 1)
	)
