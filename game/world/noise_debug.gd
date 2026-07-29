# noise_debug.gd
# Panel de debug pour régler ground_painter en temps réel
# Attache ce script à un CanvasLayer > PanelContainer
extends PanelContainer

@export var ground_painter_path: NodePath

var _painter: Node
var _preview: ColorRect
var _preview_size := 256

func _ready() -> void:
	_painter = get_node_or_null(ground_painter_path)
	_build_ui()

func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	add_child(vbox)

	# Titre
	var title := Label.new()
	title.text = "🌿 Ground Painter Debug"
	title.add_theme_color_override("font_color", Color(0.35, 0.76, 0.31))
	vbox.add_child(title)

	# Preview
	_preview = ColorRect.new()
	_preview.custom_minimum_size = Vector2(_preview_size, _preview_size)
	_preview.color = Color(0.1, 0.1, 0.1)
	vbox.add_child(_preview)

	# Sliders
	_add_slider(vbox, "Tile Size", 4, 64, 32, 2, "tile_size")
	_add_slider(vbox, "% Accent", 0, 40, 6, 1, "accent_pct")
	_add_color_row(vbox)

	# Bouton refresh
	var btn := Button.new()
	btn.text = "🔄 Rafraîchir preview"
	btn.pressed.connect(_refresh_preview)
	vbox.add_child(btn)

	_refresh_preview()

func _add_slider(parent: VBoxContainer, label_text: String, min_v: float, max_v: float, default_v: float, step_v: float, key: String) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size.x = 90
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.value = default_v
	slider.step = step_v
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.text = str(default_v)
	val_lbl.custom_minimum_size.x = 36
	row.add_child(val_lbl)

	slider.value_changed.connect(func(v: float) -> void:
		val_lbl.text = str(snapped(v, step_v))
		_on_param_changed(key, v)
	)

func _add_color_row(parent: VBoxContainer) -> void:
	var lbl := Label.new()
	lbl.text = "Couleurs herbe (5)"
	parent.add_child(lbl)
	var row := HBoxContainer.new()
	parent.add_child(row)

	# Couleurs par défaut de ground_painter.gd
	var defaults := [
		Color(0.22, 0.52, 0.15),
		Color(0.27, 0.58, 0.18),
		Color(0.18, 0.44, 0.12),
		Color(0.24, 0.55, 0.16),
		Color(0.20, 0.48, 0.14),
	]
	for i in defaults.size():
		var cp := ColorPickerButton.new()
		cp.color = defaults[i]
		cp.custom_minimum_size = Vector2(40, 32)
		cp.color_changed.connect(func(_c: Color) -> void: _refresh_preview())
		cp.name = "GrassColor" + str(i)
		row.add_child(cp)

func _on_param_changed(_key: String, _val: float) -> void:
	_refresh_preview()

func _refresh_preview() -> void:
	var img := Image.create(_preview_size, _preview_size, false, Image.FORMAT_RGB8)

	# Récupère tile_size depuis le slider
	var tile_size := 32
	var accent_pct := 0.06

	# Récupère les couleurs
	var grass_colors: Array[Color] = []
	var row_node := find_child("HBoxContainer", true, false)
	if row_node:
		for child in row_node.get_children():
			if child is ColorPickerButton:
				grass_colors.append(child.color)
	if grass_colors.is_empty():
		grass_colors = [
			Color(0.22, 0.52, 0.15),
			Color(0.27, 0.58, 0.18),
			Color(0.18, 0.44, 0.12),
		]

	# Parcourt les sliders pour tile_size et accent
	for child in get_children()[0].get_children():
		if child is HBoxContainer:
			var slider := child.get_child(1) if child.get_child_count() > 1 else null
			var lbl := child.get_child(0) if child.get_child_count() > 0 else null
			if slider is HSlider and lbl is Label:
				if lbl.text == "Tile Size":
					tile_size = int(slider.value)
				elif lbl.text == "% Accent":
					accent_pct = slider.value / 100.0

	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	for y in _preview_size:
		for x in _preview_size:
			rng.seed = hash(Vector2i(x / tile_size, y / tile_size)) + x * 31 + y * 17
			var roll := rng.randf()
			var col: Color
			if roll < accent_pct:
				col = Color(0.30, 0.62, 0.20)
			else:
				col = grass_colors[rng.randi() % grass_colors.size()]
			img.set_pixel(x, y, col)

	var tex := ImageTexture.create_from_image(img)
	_preview.material = null
	# Affiche via un TextureRect
	var tr := _preview.get_node_or_null("TR")
	if tr == null:
		tr = TextureRect.new()
		tr.name = "TR"
		tr.anchors_preset = Control.PRESET_FULL_RECT
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		_preview.add_child(tr)
	tr.texture = tex
