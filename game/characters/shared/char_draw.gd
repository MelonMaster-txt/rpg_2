# char_draw.gd
# Node2D qui dessine un personnage LPC-style en pur GDScript (draw calls)
extends Node2D

var _appearance: Node = null

const W  := 10
const TW := 8
const TH := 9
const BH := 14
const LH := 6
const FH := 4
const AW := 5
const AH := 10


func _draw() -> void:
	if _appearance == null:
		return

	var a := _appearance
	var skin:   Color  = a._color_skin
	var hair:   Color  = a._color_hair
	var eyes:   Color  = a._color_eyes
	var suit:   Color  = a._color_outfit
	var wo:     float  = a._walk_offset
	var dir:    String = a._direction

	var flip: bool = dir == "left"
	if flip:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	else:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 1))

	# —— Jambes ——
	var leg_y: int = 6
	var lx: float  = -5.0 + (wo if dir in ["left", "right", "down"] else 0.0)
	var rx: float  =  1.0 - (wo if dir in ["left", "right", "down"] else 0.0)
	draw_rect(Rect2(lx, leg_y, 4, LH), suit.darkened(0.3))
	draw_rect(Rect2(lx, leg_y + LH, 4, FH), skin.darkened(0.2))
	draw_rect(Rect2(rx, leg_y, 4, LH), suit.darkened(0.3))
	draw_rect(Rect2(rx, leg_y + LH, 4, FH), skin.darkened(0.2))

	# —— Corps ——
	draw_rect(Rect2(-W, -4, W * 2, BH - LH - FH), suit)
	draw_rect(Rect2(-W, 3, W * 2, 2), suit.darkened(0.25))

	# —— Bras ——
	var arm_swing: float = -wo if dir in ["left", "right", "down"] else 0.0
	draw_rect(Rect2(-W - AW, -4.0 + arm_swing, AW, AH), suit.darkened(0.1))
	draw_rect(Rect2(-W - AW, -4.0 + arm_swing + float(AH), AW, 3), skin)
	draw_rect(Rect2(W, -4.0 - arm_swing, AW, AH), suit.darkened(0.1))
	draw_rect(Rect2(W, -4.0 - arm_swing + float(AH), AW, 3), skin)

	# —— Cou ——
	draw_rect(Rect2(-3, -10, 6, 6), skin)

	# —— Tête ——
	var head_y: int = -10 - TH
	draw_rect(Rect2(-TW, head_y, TW * 2, TH), skin)

	# —— Yeux ——
	if dir != "up":
		var ey: int = head_y + 3
		match a._eye_style:
			"normal":
				draw_rect(Rect2(-5, ey, 3, 3), eyes)
				draw_rect(Rect2( 2, ey, 3, 3), eyes)
			"closed":
				draw_line(Vector2(-5, ey + 1), Vector2(-2, ey + 1), eyes, 1.5)
				draw_line(Vector2( 2, ey + 1), Vector2( 5, ey + 1), eyes, 1.5)
			"angry":
				draw_rect(Rect2(-5, ey, 3, 2), eyes)
				draw_rect(Rect2( 2, ey, 3, 2), eyes)
				draw_line(Vector2(-6, ey - 2), Vector2(-2, ey), hair, 1.5)
				draw_line(Vector2( 2, ey),     Vector2( 6, ey - 2), hair, 1.5)
			"sad":
				draw_rect(Rect2(-5, ey + 1, 3, 3), eyes)
				draw_rect(Rect2( 2, ey + 1, 3, 3), eyes)
				draw_line(Vector2(-3, ey + 4), Vector2(-3, ey + 7), Color(0.5, 0.7, 1.0), 1.0)
				draw_line(Vector2( 4, ey + 4), Vector2( 4, ey + 7), Color(0.5, 0.7, 1.0), 1.0)

	# —— Bouche ——
	if dir != "up":
		draw_line(Vector2(-2, head_y + 7), Vector2(2, head_y + 7), skin.darkened(0.4), 1.0)

	# —— Cheveux ——
	match a._hair:
		"short":
			draw_rect(Rect2(-TW, head_y - 2, TW * 2, 4), hair)
			# cast float pour éviter integer division sur TH / 2
			draw_rect(Rect2(-TW, head_y, 3, float(TH) / 2.0), hair)
			draw_rect(Rect2(TW - 3, head_y, 3, float(TH) / 2.0), hair)
		"medium":
			draw_rect(Rect2(-TW, head_y - 3, TW * 2, 5), hair)
			draw_rect(Rect2(-TW, head_y, 3, TH), hair)
			draw_rect(Rect2(TW - 3, head_y, 3, TH), hair)
			draw_rect(Rect2(-4, head_y + 1, 3, 3), hair)
		"long":
			draw_rect(Rect2(-TW, head_y - 3, TW * 2, 5), hair)
			draw_rect(Rect2(-TW - 1, head_y, 4, TH + 6), hair)
			draw_rect(Rect2(TW - 3, head_y, 4, TH + 6), hair)
		"bald":
			pass

	# —— Détail tenue ——
	match a._outfit:
		"guard":
			draw_rect(Rect2(-W + 2, -4, (W - 2) * 2, 6), Color(0.75, 0.75, 0.8))
			draw_rect(Rect2(-W + 2,  2, (W - 2) * 2, 1), Color(0.55, 0.55, 0.65))
		"mage":
			draw_rect(Rect2(-W, -4, W * 2, BH + 4), suit.darkened(0.1))
			draw_circle(Vector2(-4, -1), 2.0, Color(1.0, 0.9, 0.2, 0.8))
			draw_circle(Vector2( 4, -1), 2.0, Color(1.0, 0.9, 0.2, 0.8))
		"farmer":
			draw_rect(Rect2(-W + 1, -6, (W - 1) * 2, 4), suit.lightened(0.15))
			draw_line(Vector2(-5, -6), Vector2(-7, -10), suit.lightened(0.15), 1.5)
			draw_line(Vector2( 5, -6), Vector2( 7, -10), suit.lightened(0.15), 1.5)
