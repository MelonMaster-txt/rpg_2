@tool
extends Node2D

const HUT_CHUNK_SCENE: PackedScene    = preload("res://game/world/scenes/hut_chunk.tscn")
const FOREST_CHUNK_SCENE: PackedScene = preload("res://game/world/scenes/forest_chunk.tscn")

@export var chunk_coords: Vector2i = Vector2i.ZERO:
	set(value):
		chunk_coords = value
		_sync_position()
		if Engine.is_editor_hint(): queue_redraw()

@export var chunk_size: int = 512:
	set(value):
		chunk_size = value
		_sync_position()
		if Engine.is_editor_hint(): queue_redraw()

@export var chunk_type: String = "forest":
	set(value):
		chunk_type = value
		if Engine.is_editor_hint(): queue_redraw()

## Affiche les bordures de chunk — désactiver en production
@export var debug_draw_chunk_bounds: bool = false:
	set(value):
		debug_draw_chunk_bounds = value
		queue_redraw()


func _ready() -> void:
	_sync_position()


func setup(coords: Vector2i, size: int, ctype: String) -> void:
	chunk_coords = coords
	chunk_size   = size
	chunk_type   = ctype
	name = "ChunkNode_%d_%d_%s" % [coords.x, coords.y, ctype]
	_sync_position()
	_load_content()


func _sync_position() -> void:
	position = Vector2(chunk_coords.x * chunk_size, chunk_coords.y * chunk_size)


func _load_content() -> void:
	var content: Node2D = get_node_or_null("Content")
	if content == null:
		push_error("ChunkNode: nœud 'Content' manquant")
		return

	for child: Node in content.get_children():
		child.queue_free()

	var scene: PackedScene = HUT_CHUNK_SCENE if chunk_type == "hut" else FOREST_CHUNK_SCENE
	if scene == null:
		push_error("ChunkNode: aucune scène pour chunk_type = " + chunk_type)
		return

	var inst: Node = scene.instantiate()
	inst.name = "ChunkContent_" + chunk_type
	content.add_child(inst)

	if inst.has_method("setup"):
		inst.call("setup", chunk_coords, chunk_size)


func _draw() -> void:
	if not debug_draw_chunk_bounds:
		return
	var rect := Rect2(Vector2.ZERO, Vector2(chunk_size, chunk_size))
	draw_rect(rect, Color(1.0, 0.0, 0.0, 0.06), true)
	draw_rect(rect, Color(1.0, 0.0, 0.0, 0.9), false, 2.0)
	var center := Vector2(chunk_size * 0.5, chunk_size * 0.5)
	draw_circle(center, 5.0, Color(1.0, 0.2, 0.2))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(12, 20),
		"%s [%d,%d]" % [chunk_type, chunk_coords.x, chunk_coords.y],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color.WHITE
	)
