# noise_debug.gd
# Panel de debug pour visualiser et régler ground_painter en temps réel.
# Instancie-le dans ta scène principale via : add_child(preload("res://game/world/noise_debug.tscn").instantiate())
extends PanelContainer

const PREVIEW_SIZE := 200

# Valeurs par défaut calquées sur ground_painter.gd
var _tile_size   : int   = 32
var _accent_thr  : float = 0.55
var _grass_colors: Array[Color] = [
	Color(0.27, 0.58, 0.18),
	Color(0.24, 0.55, 0.16),
	Color(0.22, 0.52, 0.15),
	Color(0.18, 0.44, 0.12),
	Color(0.55, 0.38, 0.18),
]
var _accent_colors: Array[Color] = [
	Color(0.30, 0.62, 0.20),
	Color(0.55, 0.52, 0.18),
	Color(0.26, 0.56, 0.40),
]

var _tex_rect: TextureRect

func _ready() -> void:
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	add_child(vbox)

	var title := Label.new()
	title.text = "Ground Painter Preview"
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 0.3))
	vbox.add_child(title)

	# Preview
	_tex_rect = TextureRect.new()
	_tex_rect.custom_minimum_size = Vector2(PREVIEW_SIZE, PREVIEW_SIZE)
	_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	vbox.add_child(_tex_rect)

	# Slider tile size
	_add_slider(vbox, "Tile Size", 4, 64, _tile_size, 2, func(v: float):
		_tile_size = int(v)
		_refresh()
	)
	# Slider seuil accent
	_add_slider(vbox, "Accent seuil", 0.0, 1.0, _accent_thr, 0.01, func(v: float):
		_accent_thr = v
		_refresh()
	)

	# Couleurs herbe
	var lbl_grass := Label.new()
	lbl_grass.text = "Couleurs herbe"
	vbox.add_child(lbl_grass)
	var row_grass := HBoxContainer.new()
	row_grass.name = "RowGrass"
	vbox.add_child(row_grass)
	for i in _grass_colors.size():
		var cp := ColorPickerButton.new()
		cp.color = _grass_colors[i]
		cp.custom_minimum_size = Vector2(36, 28)
		var idx := i
		cp.color_changed.connect(func(c: Color):
			_grass_colors[idx] = c
			_refresh()
		)
		row_grass.add_child(cp)

	# Couleurs accent
	var lbl_acc := Label.new()
	lbl_acc.text = "Couleurs accent"
	vbox.add_child(lbl_acc)
	var row_acc := HBoxContainer.new()
	vbox.add_child(row_acc)
	for i in _accent_colors.size():
		var cp := ColorPickerButton.new()
		cp.color = _accent_colors[i]
		cp.custom_minimum_size = Vector2(36, 28)
		var idx := i
		cp.color_changed.connect(func(c: Color):
			_accent_colors[idx] = c
			_refresh()
		)
		row_acc.add_child(cp)

	# Bouton copier valeurs
	var btn := Button.new()
	btn.text = "Copier valeurs (Output)"
	btn.pressed.connect(_print_values)
	vbox.add_child(btn)

func _add_slider(parent: VBoxContainer, label: String, min_v: float, max_v: float, default_v: float, step_v: float, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size.x = 100
	row.add_child(lbl)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.value = default_v
	slider.step = step_v
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var val_lbl := Label.new()
	val_lbl.text = str(snapped(default_v, step_v))
	val_lbl.custom_minimum_size.x = 42
	row.add_child(val_lbl)
	slider.value_changed.connect(func(v: float):
		val_lbl.text = str(snapped(v, step_v))
		on_change.call(v)
	)

func _refresh() -> void:
	var img := Image.create(PREVIEW_SIZE, PREVIEW_SIZE, false, Image.FORMAT_RGB8)
	var noise := FastNoiseLite.new()
	noise.seed = 42
	noise.frequency = 1.0 / (float(_tile_size) * 4.0)
	var noise_detail := FastNoiseLite.new()
	noise_detail.seed = 99
	noise_detail.frequency = 1.0 / (float(_tile_size) * 2.0)

	for y in PREVIEW_SIZE:
		for x in PREVIEW_SIZE:
			var v_ground: float = noise.get_noise_2d(x, y)
			var v_detail: float = noise_detail.get_noise_2d(x, y)
			var col: Color
			if v_detail > _accent_thr - 1.0:  # FastNoiseLite retourne -1..1, on normalise
				col = _accent_colors[abs(x * 3 + y) % _accent_colors.size()]
			else:
				col = _noise_to_color(v_ground)
			img.set_pixel(x, y, col)

	_tex_rect.texture = ImageTexture.create_from_image(img)

func _noise_to_color(v: float) -> Color:
	if v > 0.3:   return _grass_colors[0]
	elif v > 0.1: return _grass_colors[1]
	elif v > -0.1: return _grass_colors[2]
	elif v > -0.3: return _grass_colors[3]
	else:          return _grass_colors[4]

func _print_values() -> void:
	print("=== Ground Painter Values ===")
	print("TILE_SIZE: ", _tile_size)
	print("ACCENT seuil: ", _accent_thr)
	print("GRASS_COLORS:")
	for c in _grass_colors:
		print("  Color(", snapped(c.r,0.01), ", ", snapped(c.g,0.01), ", ", snapped(c.b,0.01), ")")
	print("ACCENT_COLORS:")
	for c in _accent_colors:
		print("  Color(", snapped(c.r,0.01), ", ", snapped(c.g,0.01), ", ", snapped(c.b,0.01), ")")
