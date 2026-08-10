extends Node2D

# Référence vers character_appearance.gd
var _appearance: Node = null

@export var tile_size: int = 16

func _draw() -> void:
	_draw_character()

func refresh() -> void:
	queue_redraw()

func _draw_character() -> void:
	# Récupère les couleurs depuis appearance ou valeurs par défaut
	var c_skin:   Color = Color(0.85, 0.70, 0.55)
	var c_eyes:   Color = Color(0.20, 0.50, 0.80)
	var c_hair:   Color = Color(0.30, 0.18, 0.08)
	var c_outfit: Color = Color(0.55, 0.38, 0.20)
	var hair_style: String = "short"
	var eye_style:  String = "normal"

	if _appearance != null:
		var data: Dictionary = _appearance.get_appearance_data()
		if data.has("skin_color"):  c_skin   = data["skin_color"]
		if data.has("eyes_color"):  c_eyes   = data["eyes_color"]
		if data.has("hair_color"):  c_hair   = data["hair_color"]
		if data.has("outfit_color"): c_outfit = data["outfit_color"]
		if data.has("hair"):        hair_style = data["hair"]
		if data.has("eye_style"):   eye_style  = data["eye_style"]

	var s: float = float(tile_size)
	var c_outline: Color = Color(0.08, 0.05, 0.03)
	var c_shadow:  Color = Color(c_skin.r * 0.75, c_skin.g * 0.75, c_skin.b * 0.75)
	var c_outfit_dark: Color = Color(c_outfit.r * 0.7, c_outfit.g * 0.7, c_outfit.b * 0.7)

	# ── JAMBES ──────────────────────────────────────────────────────────
	var pants: Color = Color(c_outfit.r * 0.6, c_outfit.g * 0.55, c_outfit.b * 0.8)
	# Jambe gauche
	draw_rect(Rect2(-s * 0.35, s * 0.15, s * 0.28, s * 0.55), pants)
	draw_rect(Rect2(-s * 0.35, s * 0.15, s * 0.28, s * 0.04), c_outline)
	# Jambe droite
	draw_rect(Rect2(s * 0.07, s * 0.15, s * 0.28, s * 0.55), pants)
	draw_rect(Rect2(s * 0.07, s * 0.15, s * 0.28, s * 0.04), c_outline)
	# Pieds
	draw_rect(Rect2(-s * 0.38, s * 0.65, s * 0.32, s * 0.12), c_skin)
	draw_rect(Rect2(s * 0.06, s * 0.65, s * 0.32, s * 0.12), c_skin)

	# ── CORPS / TORSE ───────────────────────────────────────────────────
	draw_rect(Rect2(-s * 0.38, -s * 0.22, s * 0.76, s * 0.40), c_outfit)
	# Ligne verticale centrale (ombre)
	draw_rect(Rect2(-s * 0.04, -s * 0.22, s * 0.08, s * 0.40), c_outfit_dark)
	# Contour bas du torse
	draw_rect(Rect2(-s * 0.38, s * 0.15, s * 0.76, s * 0.03), c_outline)

	# ── BRAS ────────────────────────────────────────────────────────────
	# Bras gauche
	draw_rect(Rect2(-s * 0.55, -s * 0.22, s * 0.18, s * 0.42), c_skin)
	draw_rect(Rect2(-s * 0.55, -s * 0.22, s * 0.18, s * 0.03), c_outline)
	# Main gauche
	draw_rect(Rect2(-s * 0.57, s * 0.17, s * 0.20, s * 0.12), c_skin)
	# Bras droit
	draw_rect(Rect2(s * 0.37, -s * 0.22, s * 0.18, s * 0.42), c_skin)
	draw_rect(Rect2(s * 0.37, -s * 0.22, s * 0.18, s * 0.03), c_outline)
	# Main droite
	draw_rect(Rect2(s * 0.37, s * 0.17, s * 0.20, s * 0.12), c_skin)

	# ── COU ─────────────────────────────────────────────────────────────
	draw_rect(Rect2(-s * 0.12, -s * 0.38, s * 0.24, s * 0.18), c_skin)

	# ── TÊTE ────────────────────────────────────────────────────────────
	var head_rect: Rect2 = Rect2(-s * 0.35, -s * 0.95, s * 0.70, s * 0.58)
	draw_rect(head_rect, c_skin)
	# Ombre latérale tête
	draw_rect(Rect2(-s * 0.35, -s * 0.95, s * 0.06, s * 0.58), c_shadow)
	draw_rect(Rect2(s * 0.29, -s * 0.95, s * 0.06, s * 0.58), c_shadow)
	# Contour tête
	draw_rect(Rect2(-s * 0.35, -s * 0.95, s * 0.70, s * 0.03), c_outline)
	draw_rect(Rect2(-s * 0.35, -s * 0.40, s * 0.70, s * 0.03), c_outline)
	draw_rect(Rect2(-s * 0.35, -s * 0.95, s * 0.03, s * 0.58), c_outline)
	draw_rect(Rect2(s * 0.32, -s * 0.95, s * 0.03, s * 0.58), c_outline)

	# ── YEUX ────────────────────────────────────────────────────────────
	var eye_y: float = -s * 0.65
	if eye_style == "closed":
		# Trait horizontal
		draw_rect(Rect2(-s * 0.22, eye_y, s * 0.14, s * 0.03), c_outline)
		draw_rect(Rect2(s * 0.08,  eye_y, s * 0.14, s * 0.03), c_outline)
	elif eye_style == "angry":
		# Œil plissé + sourcil incliné
		draw_rect(Rect2(-s * 0.22, eye_y, s * 0.14, s * 0.08), c_eyes)
		draw_rect(Rect2(s * 0.08,  eye_y, s * 0.14, s * 0.08), c_eyes)
		draw_rect(Rect2(-s * 0.24, eye_y - s * 0.07, s * 0.16, s * 0.03), c_outline)
		draw_rect(Rect2(s * 0.08,  eye_y - s * 0.07, s * 0.16, s * 0.03), c_outline)
	elif eye_style == "sad":
		draw_rect(Rect2(-s * 0.22, eye_y, s * 0.14, s * 0.10), c_eyes)
		draw_rect(Rect2(s * 0.08,  eye_y, s * 0.14, s * 0.10), c_eyes)
		# Larme
		draw_rect(Rect2(-s * 0.18, eye_y + s * 0.10, s * 0.05, s * 0.08), Color(0.5, 0.7, 1.0, 0.8))
	else:
		# Normal : blanc + iris + pupille
		draw_rect(Rect2(-s * 0.22, eye_y - s * 0.02, s * 0.14, s * 0.13), Color.WHITE)
		draw_rect(Rect2(s * 0.08,  eye_y - s * 0.02, s * 0.14, s * 0.13), Color.WHITE)
		draw_rect(Rect2(-s * 0.19, eye_y, s * 0.10, s * 0.09), c_eyes)
		draw_rect(Rect2(s * 0.09,  eye_y, s * 0.10, s * 0.09), c_eyes)
		draw_rect(Rect2(-s * 0.16, eye_y + s * 0.02, s * 0.05, s * 0.05), c_outline)
		draw_rect(Rect2(s * 0.11,  eye_y + s * 0.02, s * 0.05, s * 0.05), c_outline)
		# Reflet
		draw_rect(Rect2(-s * 0.13, eye_y + s * 0.01, s * 0.03, s * 0.03), Color.WHITE)
		draw_rect(Rect2(s * 0.14,  eye_y + s * 0.01, s * 0.03, s * 0.03), Color.WHITE)

	# ── CHEVEUX ─────────────────────────────────────────────────────────
	var hair_top: float = -s * 0.97
	match hair_style:
		"bald":
			pass  # Rien
		"short":
			draw_rect(Rect2(-s * 0.35, hair_top, s * 0.70, s * 0.18), c_hair)
			draw_rect(Rect2(-s * 0.38, hair_top + s * 0.10, s * 0.08, s * 0.18), c_hair)
			draw_rect(Rect2(s * 0.30,  hair_top + s * 0.10, s * 0.08, s * 0.18), c_hair)
		"medium":
			draw_rect(Rect2(-s * 0.35, hair_top, s * 0.70, s * 0.18), c_hair)
			draw_rect(Rect2(-s * 0.38, hair_top + s * 0.10, s * 0.08, s * 0.45), c_hair)
			draw_rect(Rect2(s * 0.30,  hair_top + s * 0.10, s * 0.08, s * 0.45), c_hair)
			draw_rect(Rect2(-s * 0.35, hair_top + s * 0.50, s * 0.70, s * 0.10), c_hair)
		"long":
			draw_rect(Rect2(-s * 0.35, hair_top, s * 0.70, s * 0.18), c_hair)
			draw_rect(Rect2(-s * 0.40, hair_top + s * 0.10, s * 0.10, s * 0.90), c_hair)
			draw_rect(Rect2(s * 0.30,  hair_top + s * 0.10, s * 0.10, s * 0.90), c_hair)
			draw_rect(Rect2(-s * 0.35, hair_top + s * 0.90, s * 0.70, s * 0.10), c_hair)
