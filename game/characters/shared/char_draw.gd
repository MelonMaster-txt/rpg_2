extends Node2D

# ─── EXPORTS ──────────────────────────────────────────────────────────────────
@export var body_color: Color = Color(0.8, 0.6, 0.4)
@export var hair_color: Color = Color(0.3, 0.2, 0.1)
@export var shirt_color: Color = Color(0.5, 0.3, 0.1)
@export var pants_color: Color = Color(0.2, 0.2, 0.5)
@export var eye_color: Color = Color(0.1, 0.1, 0.1)
@export var skin_tone: int = 0
@export var hair_style: int = 0
@export var tile_size: int = 16

func _draw() -> void:
	_draw_character()

func refresh() -> void:
	queue_redraw()

func _draw_character() -> void:
	var half: int = tile_size / 2
	# Corps
	draw_rect(Rect2(-half / 2, -half, half, half), body_color)
	# Tête
	draw_circle(Vector2(0, -half - half / 2), half / 2, body_color)
	# Yeux
	draw_circle(Vector2(-half / 6, -half - half / 2), 1.0, eye_color)
	draw_circle(Vector2(half / 6, -half - half / 2), 1.0, eye_color)
