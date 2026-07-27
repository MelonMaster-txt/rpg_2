# char_draw.gd
# Node2D qui dessine un personnage LPC-style en pur GDScript (draw calls)
# Attaché dynamiquement par character_appearance.gd
extends Node2D

var _appearance: Node = null  # référence vers character_appearance

# Dimensions de base (grille 32x32, personnage centré)
const W  := 10   # demi-largeur corps
const TW := 8    # demi-largeur tête
const TH := 9    # hauteur tête
const BH := 14   # hauteur corps
const LH := 6    # hauteur jambe
const FH := 4    # épaisseur pied
const AW := 5    # largeur bras
const AH := 10   # hauteur bras


func _draw() -> void:
	if _appearance == null:
		return

	var a    := _appearance
	var skin := a._color_skin
	var hair := a._color_hair
	var eyes := a._color_eyes
	var suit := a._color_outfit
	var wo   := a._walk_offset  # oscillation marche
	var dir  := a._direction

	# ——— Flip horizontal si direction left ———
	var flip := dir == "left"
	if flip:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	else:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 1))

	# ——— Jambes (oscillation gauche/droite) ———
	var leg_y := 6
	var lx    := -5 + (wo if dir in ["left","right","down"] else 0)
	var rx    :=  1 - (wo if dir in ["left","right","down"] else 0)
	# Jambe gauche
	draw_rect(Rect2(lx, leg_y, 4, LH), suit.darkened(0.3))
	draw_rect(Rect2(lx, leg_y + LH, 4, FH), skin.darkened(0.2))  # pied
	# Jambe droite
	draw_rect(Rect2(rx, leg_y, 4, LH), suit.darkened(0.3))
	draw_rect(Rect2(rx, leg_y + LH, 4, FH), skin.darkened(0.2))

	# ——— Corps / torse ———
	draw_rect(Rect2(-W, -4, W * 2, BH - LH - FH), suit)
	# Ceinture
	draw_rect(Rect2(-W, 3, W * 2, 2), suit.darkened(0.25))

	# ——— Bras (oscillation inverse des jambes) ———
	var arm_swing := -wo if dir in ["left","right","down"] else 0
	# Bras gauche
	draw_rect(Rect2(-W - AW, -4 + arm_swing, AW, AH), suit.darkened(0.1))
	draw_rect(Rect2(-W - AW, -4 + arm_swing + AH, AW, 3), skin)  # main
	# Bras droit
	draw_rect(Rect2(W, -4 - arm_swing, AW, AH), suit.darkened(0.1))
	draw_rect(Rect2(W, -4 - arm_swing + AH, AW, 3), skin)

	# ——— Cou ———
	draw_rect(Rect2(-3, -10, 6, 6), skin)

	# ——— Tête ———
	var head_y := -10 - TH
	draw_rect(Rect2(-TW, head_y, TW * 2, TH), skin)

	# ——— Yeux ———
	if dir != "up":  # pas d'yeux si on regarde vers le haut
		var eye_style := a._eye_style
		var ey := head_y + 3
		match eye_style:
			"normal":
				draw_rect(Rect2(-5, ey, 3, 3), eyes)
				draw_rect(Rect2( 2, ey, 3, 3), eyes)
			"closed":
				draw_line(Vector2(-5, ey+1), Vector2(-2, ey+1), eyes, 1.5)
				draw_line(Vector2( 2, ey+1), Vector2( 5, ey+1), eyes, 1.5)
			"angry":
				draw_rect(Rect2(-5, ey, 3, 2), eyes)
				draw_rect(Rect2( 2, ey, 3, 2), eyes)
				# sourcils froncés
				draw_line(Vector2(-6, ey-2), Vector2(-2, ey), hair, 1.5)
				draw_line(Vector2( 2, ey), Vector2( 6, ey-2), hair, 1.5)
			"sad":
				draw_rect(Rect2(-5, ey+1, 3, 3), eyes)
				draw_rect(Rect2( 2, ey+1, 3, 3), eyes)
				# larmes
				draw_line(Vector2(-3, ey+4), Vector2(-3, ey+7), Color(0.5,0.7,1.0), 1.0)
				draw_line(Vector2( 4, ey+4), Vector2( 4, ey+7), Color(0.5,0.7,1.0), 1.0)

	# ——— Bouche ———
	if dir != "up":
		draw_line(Vector2(-2, head_y + 7), Vector2(2, head_y + 7), skin.darkened(0.4), 1.0)

	# ——— Cheveux ———
	var hair_style := a._hair
	match hair_style:
		"short":
			draw_rect(Rect2(-TW, head_y - 2, TW * 2, 4), hair)
			draw_rect(Rect2(-TW, head_y, 3, TH / 2), hair)  # côté gauche
			draw_rect(Rect2(TW - 3, head_y, 3, TH / 2), hair)  # côté droit
		"medium":
			draw_rect(Rect2(-TW, head_y - 3, TW * 2, 5), hair)
			draw_rect(Rect2(-TW, head_y, 3, TH), hair)
			draw_rect(Rect2(TW - 3, head_y, 3, TH), hair)
			# mèches sur le front
			draw_rect(Rect2(-4, head_y + 1, 3, 3), hair)
		"long":
			draw_rect(Rect2(-TW, head_y - 3, TW * 2, 5), hair)
			draw_rect(Rect2(-TW - 1, head_y, 4, TH + 6), hair)  # tresses gauche
			draw_rect(Rect2(TW - 3, head_y, 4, TH + 6), hair)   # tresses droite
		"bald":
			pass  # crâne nu

	# ——— Détail tenue selon type ———
	match a._outfit:
		"guard":
			# Plastron métallique
			draw_rect(Rect2(-W + 2, -4, (W - 2) * 2, 6), Color(0.75, 0.75, 0.8))
			draw_rect(Rect2(-W + 2, 2, (W - 2) * 2, 1), Color(0.55, 0.55, 0.65))
		"mage":
			# Robe longue
			draw_rect(Rect2(-W, -4, W * 2, BH + 4), suit.darkened(0.1))
			# Étoiles magiques
			draw_circle(Vector2(-4, -1), 2.0, Color(1.0, 0.9, 0.2, 0.8))
			draw_circle(Vector2( 4, -1), 2.0, Color(1.0, 0.9, 0.2, 0.8))
		"farmer":
			# Salopette
			draw_rect(Rect2(-W + 1, -6, (W - 1) * 2, 4), suit.lightened(0.15))
			# Bretelles
			draw_line(Vector2(-5, -6), Vector2(-7, -10), suit.lightened(0.15), 1.5)
			draw_line(Vector2( 5, -6), Vector2( 7, -10), suit.lightened(0.15), 1.5)
