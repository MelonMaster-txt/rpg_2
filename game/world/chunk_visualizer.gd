@tool
extends Node2D

@export var chunk_coords: Vector2i = Vector2i(0, 0):
	set(value):
		chunk_coords = value
		if Engine.is_editor_hint():
			queue_redraw()

@export var chunk_size: int = 512:
	set(value):
		chunk_size = value
		if Engine.is_editor_hint():
			queue_redraw()

func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var top_left := Vector2(chunk_coords.x * chunk_size, chunk_coords.y * chunk_size)
	var rect := Rect2(top_left, Vector2(chunk_size, chunk_size))

	draw_rect(rect, Color(1.0, 0.0, 0.0, 0.08), true)
	draw_rect(rect, Color(1.0, 0.0, 0.0, 0.9), false, 2.0)

	var label_pos := top_left + Vector2(16, 24)
	var text := "Chunk " + str(chunk_coords)
	draw_string(
		ThemeDB.fallback_font,
		label_pos,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color(1, 1, 1, 1)
	)
