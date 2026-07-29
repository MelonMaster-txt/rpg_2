# noise_debug.gd — Panel de debug ground_painter avec contrôle total du noise
extends PanelContainer

const PREVIEW_SIZE := 256

# --- Noise Ground ---
var _g_seed        : int   = 42
var _g_type        : int   = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
var _g_freq        : float = 0.003
var _g_octaves     : int   = 4
var _g_lacunarity  : float = 2.0
var _g_gain        : float = 0.5
var _g_fbm         : int   = FastNoiseLite.FRACTAL_FBM
var _g_warp_amp    : float = 0.0   # 0 = désactivé

# --- Noise Detail (accent) ---
var _d_seed        : int   = 99
var _d_freq        : float = 0.008
var _d_octaves     : int   = 2
var _accent_thr    : float = 0.4   # seuil dans [-1..1]

# --- Seuils palette herbe (4 coupures pour 5 bandes) ---
var _thresholds: Array[float] = [0.3, 0.1, -0.1, -0.3]

# --- Couleurs ---
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

var _tex_rect : TextureRect
var _scroll   : ScrollContainer

const NOISE_TYPES := [
	["Simplex",        FastNoiseLite.TYPE_SIMPLEX],
	["Simplex Smooth", FastNoiseLite.TYPE_SIMPLEX_SMOOTH],
	["Cellular",       FastNoiseLite.TYPE_CELLULAR],
	["Perlin",         FastNoiseLite.TYPE_PERLIN],
	["Value Cubic",    FastNoiseLite.TYPE_VALUE_CUBIC],
	["Value",          FastNoiseLite.TYPE_VALUE],
]
const FRACTAL_TYPES := [
	["None",       FastNoiseLite.FRACTAL_NONE],
	["FBM",        FastNoiseLite.FRACTAL_FBM],
	["Ridged",     FastNoiseLite.FRACTAL_RIDGED],
	["Ping Pong",  FastNoiseLite.FRACTAL_PING_PONG],
]

func _ready() -> void:
	custom_minimum_size = Vector2(360, 0)
	_build_ui()
	_refresh()

func _build_ui() -> void:
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(360, 700)
	add_child(_scroll)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(vbox)

	_add_title(vbox, "Ground Painter — Noise Debug")

	# Preview
	_tex_rect = TextureRect.new()
	_tex_rect.custom_minimum_size = Vector2(PREVIEW_SIZE, PREVIEW_SIZE)
	_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	vbox.add_child(_tex_rect)

	# ---- NOISE GROUND ----
	_add_separator(vbox, "🌱 Noise Ground")
	_add_option(vbox, "Type", NOISE_TYPES, _g_type, func(i: int): _g_type = NOISE_TYPES[i][1]; _refresh())
	_add_option(vbox, "Fractal", FRACTAL_TYPES, _g_fbm, func(i: int): _g_fbm = FRACTAL_TYPES[i][1]; _refresh())
	_add_slider(vbox, "Seed",       0, 9999, _g_seed,       1,    func(v): _g_seed = int(v);       _refresh())
	_add_slider(vbox, "Frequency",  0.0005, 0.05, _g_freq,  0.0005, func(v): _g_freq = v;         _refresh())
	_add_slider(vbox, "Octaves",    1, 8, _g_octaves,       1,    func(v): _g_octaves = int(v);    _refresh())
	_add_slider(vbox, "Lacunarity", 1.0, 4.0, _g_lacunarity,0.05, func(v): _g_lacunarity = v;      _refresh())
	_add_slider(vbox, "Gain",       0.1, 1.0, _g_gain,      0.01, func(v): _g_gain = v;            _refresh())
	_add_slider(vbox, "Warp Amp",   0.0, 200.0, _g_warp_amp,1.0,  func(v): _g_warp_amp = v;        _refresh())

	# ---- SEUILS PALETTE ----
	_add_separator(vbox, "🎨 Seuils herbe (haut → bas)")
	var thr_labels := ["Seuil 1 (clair)", "Seuil 2", "Seuil 3", "Seuil 4 (foncé)"]
	for i in _thresholds.size():
		var idx := i
		_add_slider(vbox, thr_labels[i], -1.0, 1.0, _thresholds[i], 0.01,
			func(v): _thresholds[idx] = v; _refresh())

	# ---- COULEURS HERBE ----
	_add_separator(vbox, "🟩 Couleurs herbe")
	var labels_g := ["Très clair", "Clair", "Moyen", "Foncé", "Terre"]
	_add_color_row(vbox, _grass_colors, labels_g, func(i: int, c: Color): _grass_colors[i] = c; _refresh())

	# ---- NOISE DETAIL ----
	_add_separator(vbox, "✨ Noise Accent")
	_add_slider(vbox, "Seed",      0, 9999, _d_seed,    1,      func(v): _d_seed = int(v);    _refresh())
	_add_slider(vbox, "Frequency", 0.001, 0.05, _d_freq, 0.001, func(v): _d_freq = v;         _refresh())
	_add_slider(vbox, "Octaves",   1, 6, _d_octaves,    1,      func(v): _d_octaves = int(v); _refresh())
	_add_slider(vbox, "Seuil",     -1.0, 1.0, _accent_thr, 0.01, func(v): _accent_thr = v;   _refresh())

	# ---- COULEURS ACCENT ----
	_add_separator(vbox, "🟧 Couleurs accent")
	var labels_a := ["Vert vif", "Mousse", "Bleu-vert"]
	_add_color_row(vbox, _accent_colors, labels_a, func(i: int, c: Color): _accent_colors[i] = c; _refresh())

	# ---- BOUTONS ----
	_add_separator(vbox, "")
	var btn := Button.new()
	btn.text = "📋 Copier valeurs → Output"
	btn.pressed.connect(_print_values)
	vbox.add_child(btn)

func _add_title(parent: VBoxContainer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.4, 0.9, 0.3))
	parent.add_child(l)

func _add_separator(parent: VBoxContainer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	parent.add_child(l)

func _add_option(parent: VBoxContainer, label: String, items: Array, current_val: int, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size.x = 100
	row.add_child(lbl)
	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var selected_idx := 0
	for i in items.size():
		opt.add_item(items[i][0])
		if items[i][1] == current_val:
			selected_idx = i
	opt.selected = selected_idx
	opt.item_selected.connect(on_change)
	row.add_child(opt)

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
	val_lbl.custom_minimum_size.x = 48
	row.add_child(val_lbl)
	slider.value_changed.connect(func(v: float):
		val_lbl.text = str(snapped(v, step_v))
		on_change.call(v)
	)

func _add_color_row(parent: VBoxContainer, colors: Array[Color], labels: Array, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	for i in colors.size():
		var col := VBoxContainer.new()
		row.add_child(col)
		var lbl := Label.new()
		lbl.text = labels[i] if i < labels.size() else str(i)
		lbl.add_theme_font_size_override("font_size", 9)
		col.add_child(lbl)
		var cp := ColorPickerButton.new()
		cp.color = colors[i]
		cp.custom_minimum_size = Vector2(48, 28)
		var idx := i
		cp.color_changed.connect(func(c: Color): on_change.call(idx, c))
		col.add_child(cp)

func _refresh() -> void:
	var noise := FastNoiseLite.new()
	noise.noise_type     = _g_type
	noise.seed           = _g_seed
	noise.frequency      = _g_freq
	noise.fractal_type   = _g_fbm
	noise.fractal_octaves    = _g_octaves
	noise.fractal_lacunarity = _g_lacunarity
	noise.fractal_gain       = _g_gain
	if _g_warp_amp > 0.0:
		noise.domain_warp_enabled   = true
		noise.domain_warp_amplitude = _g_warp_amp
	else:
		noise.domain_warp_enabled = false

	var noise_d := FastNoiseLite.new()
	noise_d.noise_type        = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise_d.seed              = _d_seed
	noise_d.frequency         = _d_freq
	noise_d.fractal_octaves   = _d_octaves

	var img := Image.create(PREVIEW_SIZE, PREVIEW_SIZE, false, Image.FORMAT_RGB8)
	for y in PREVIEW_SIZE:
		for x in PREVIEW_SIZE:
			var vg: float = noise.get_noise_2d(x, y)
			var vd: float = noise_d.get_noise_2d(x, y)
			var col: Color
			if vd > _accent_thr:
				col = _accent_colors[abs(x * 3 + y) % _accent_colors.size()]
			else:
				col = _noise_to_color(vg)
			img.set_pixel(x, y, col)
	_tex_rect.texture = ImageTexture.create_from_image(img)

func _noise_to_color(v: float) -> Color:
	if   v > _thresholds[0]: return _grass_colors[0]
	elif v > _thresholds[1]: return _grass_colors[1]
	elif v > _thresholds[2]: return _grass_colors[2]
	elif v > _thresholds[3]: return _grass_colors[3]
	else:                    return _grass_colors[4]

func _print_values() -> void:
	print("\n=== Ground Painter — Valeurs à coller ===")
	print("# Noise Ground")
	print("noise_type:       ", _g_type)
	print("seed:             ", _g_seed)
	print("frequency:        ", _g_freq)
	print("fractal_type:     ", _g_fbm)
	print("octaves:          ", _g_octaves)
	print("lacunarity:       ", _g_lacunarity)
	print("gain:             ", _g_gain)
	print("warp_amplitude:   ", _g_warp_amp)
	print("# Seuils palette")
	print("thresholds:       ", _thresholds)
	print("# Noise Accent")
	print("detail_seed:      ", _d_seed)
	print("detail_frequency: ", _d_freq)
	print("detail_octaves:   ", _d_octaves)
	print("accent_threshold: ", _accent_thr)
	print("GRASS_COLORS:")
	for c in _grass_colors:
		print("  Color(", snapped(c.r,0.001), ", ", snapped(c.g,0.001), ", ", snapped(c.b,0.001), ")")
	print("ACCENT_COLORS:")
	for c in _accent_colors:
		print("  Color(", snapped(c.r,0.001), ", ", snapped(c.g,0.001), ", ", snapped(c.b,0.001), ")")
	print("=========================================\n")
