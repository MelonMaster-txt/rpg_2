extends Node2D

# Référence vers le Node character_appearance.gd qui contrôle cet affichage.
# Assignée par character_appearance._build_layers_deferred().
var _appearance: Node = null

# ─── EXPORTS (valeurs par défaut si pas d'appearance liée) ─────────────────────
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
	var c_skin: Color = body_color
	var c_eyes: Color = eye_color
	var c_hair: Color = hair_color
	var c_outfit: Color = shirt_color

	if _appearance != null:
		var data: Dictionary = _appearance.get_appearance_data()
		if data.has("skin_color"):
			c_skin = data["skin_color"]
		if data.has("eyes_color"):
			c_eyes = data["eyes_color"]
		if data.has("hair_color"):
			c_hair = data["hair_color"]
		if data.has("outfit_color"):
			c_outfit = data["outfit_color"]

	var half: float = tile_size / 2.0
	# Corps
	draw_rect(Rect2(-half / 2.0, -half, half, half), c_outfit)
	# Tête
	draw_circle(Vector2(0.0, -half - half / 2.0), half / 2.0, c_skin)
	# Yeux
	draw_circle(Vector2(-half / 6.0, -half - half / 2.0), 1.0, c_eyes)
	draw_circle(Vector2(half / 6.0, -half - half / 2.0), 1.0, c_eyes)
	# Cheveux (trait simple au-dessus de la tête)
	draw_rect(Rect2(-half / 2.0, -half * 2.0 - half / 4.0, half, half / 4.0), c_hair)
