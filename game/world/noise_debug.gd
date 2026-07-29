# noise_debug.gd — Contrôle total du noise + repaint live sur les chunks
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
var _g_warp_amp    : float = 0.0

# --- Noise Detail ---
var _d_seed        : int   = 99
var _d_freq        : float = 0.008
var _d_octaves     : int   = 2
var _accent_thr    : float = 0.4

# --- Seuils palette ---
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

var _tex_rect  : TextureRect
var _live_mode : bool = false

const NOISE_TYPES := [
	["Simplex",        FastNoiseLite.TYPE_SIMPLEX],
	["Simplex Smooth", FastNoiseLite.TYPE_SIMPLEX_SMOOTH],
	["Cellular",       FastNoiseLite.TYPE_CELLULAR],
	["Perlin",         FastNoiseLite.TYPE_PERLIN],
	["Value Cubic",    FastNoiseLite.TYPE_VALUE_CUBIC],
	["Value",          FastNoiseLite.TYPE_VALUE],
]
const FRACTAL_TYPES := [
	["None",      FastNoiseLite.FRACTAL_NONE],
	["FBM",       FastNoiseLite.FRACTAL_FBM],
	["Ridged",    FastNoiseLite.FRACTAL_RIDGED],
	["Ping Pong", FastNoiseLite.FRACTAL_PING_PONG],
]

func _ready() -> void:
	custom_minimum_size = Vector2(370, 0)
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(370, 720)
	add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	_add_title(vbox, "Ground Painter — Noise Debug")

	# Preview
	_tex_rect = TextureRect.new()
	_tex_rect.custom_minimum_size = Vector2(PREVIEW_SIZE, PREVIEW_SIZE)
	_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	vbox.add_child(_tex_rect)

	# Toggle live
	var live_row := HBoxContainer.new()
	vbox.add_child(live_row)
	var live_lbl := Label.new()
	live_lbl.text = "🔴 Repaint chunks live"
	live_lbl.custom_minimum_size.x = 180
	live_row.add_child(live_lbl)
	var live_toggle := CheckButton.new()
	live_toggle.button_pressed = false
	live_toggle.toggled.connect(func(on: bool): _live_mode = on)
	live_row.add_child(live_toggle)

	# ---- NOISE GROUND ----
	_add_separator(vbox, "🌱 Noise Ground")
	_add_option(vbox, "Type",    NOISE_TYPES,   _g_type, func(i): _g_type = NOISE_TYPES[i][1];     _refresh())
	_add_option(vbox, "Fractal", FRACTAL_TYPES, _g_fbm,  func(i): _g_fbm  = FRACTAL_TYPES[i][1];  _refresh())
	_add_slider(vbox, "Seed",        0,      9999, _g_seed,       1,      func(v): _g_seed = int(v);       _refresh())
	_add_slider(vbox, "Frequency",   0.0005, 0.05, _g_freq,       0.0005, func(v): _g_freq = v;            _refresh())
	_add_slider(vbox, "Octaves",     1,      8,    _g_octaves,    1,      func(v): _g_octaves = int(v);    _refresh())
	_add_slider(vbox, "Lacunarity",  1.0,    4.0,  _g_lacunarity, 0.05,   func(v): _g_lacunarity = v;      _refresh())
	_add_slider(vbox, "Gain",        0.1,    1.0,  _g_gain,       0.01,   func(v): _g_gain = v;            _refresh())
	_add_slider(vbox, "Warp Amp",    0.0,    200.0,_g_warp_amp,   1.0,    func(v): _g_warp_amp = v;        _refresh())

	# ---- SEUILS ----
	_add_separator(vbox, "🎨 Seuils herbe")
	var thr_labels := ["Seuil 1 (clair)","Seuil 2","Seuil 3","Seuil 4 (foncé)"]
	for i in _thresholds.size():
		var idx := i
		_add_slider(vbox, thr_labels[i], -1.0, 1.0, _thresholds[i], 0.01,
			func(v): _thresholds[idx] = v; _refresh())

	# ---- COULEURS HERBE ----
	_add_separator(vbox, "🟩 Couleurs herbe")
	var lg := ["Très clair","Clair","Moyen","Foncé","Terre"]
	_add_color_row(vbox, _grass_colors, lg, func(i,c): _grass_colors[i]=c; _refresh())

	# ---- NOISE ACCENT ----
	_add_separator(vbox, "✨ Noise Accent")
	_add_slider(vbox, "Seed",      0,     9999, _d_seed,    1,     func(v): _d_seed = int(v);    _refresh())
	_add_slider(vbox, "Frequency", 0.001, 0.05, _d_freq,    0.001, func(v): _d_freq = v;         _refresh())
	_add_slider(vbox, "Octaves",   1,     6,    _d_octaves, 1,     func(v): _d_octaves = int(v); _refresh())
	_add_slider(vbox, "Seuil",    -1.0,   1.0,  _accent_thr,0.01,  func(v): _accent_thr = v;    _refresh())

	# ---- COULEURS ACCENT ----
	_add_separator(vbox, "🟧 Couleurs accent")
	var la := ["Vert vif","Mousse","Bleu-vert"]
	_add_color_row(vbox, _accent_colors, la, func(i,c): _accent_colors[i]=c; _refresh())

	# ---- BOUTONS ----
	_add_separator(vbox, "")
	var btn_repaint := Button.new()
	btn_repaint.text = "🔄 Repaint tous les chunks"
	btn_repaint.pressed.connect(_repaint_all_chunks)
	vbox.add_child(btn_repaint)

	var btn_copy := Button.new()
	btn_copy.text = "📋 Copier valeurs → Output"
	btn_copy.pressed.connect(_print_values)
	vbox.add_child(btn_copy)

# -------------------------------------------------------
# REFRESH : preview + repaint chunks si live mode actif
# -------------------------------------------------------
func _refresh() -> void:
	var noise   := _build_ground_noise()
	var noise_d := _build_detail_noise()

	# Preview
	var img := Image.create(PREVIEW_SIZE, PREVIEW_SIZE, false, Image.FORMAT_RGB8)
	for y in PREVIEW_SIZE:
		for x in PREVIEW_SIZE:
			img.set_pixel(x, y, _sample_color(noise, noise_d, x, y))
	_tex_rect.texture = ImageTexture.create_from_image(img)

	# Repaint live si activé
	if _live_mode:
		_repaint_all_chunks()

func _repaint_all_chunks() -> void:
	var noise   := _build_ground_noise()
	var noise_d := _build_detail_noise()
	# Trouve tous les ground_painter dans la scène
	var painters := get_tree().get_nodes_in_group("ground_painter")
	for painter in painters:
		if painter.has_method("repaint_with"):
			painter.call("repaint_with", noise, noise_d, _thresholds, _grass_colors, _accent_colors, _accent_thr)

func _build_ground_noise() -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type          = _g_type
	n.seed                = _g_seed
	n.frequency           = _g_freq
	n.fractal_type        = _g_fbm
	n.fractal_octaves     = _g_octaves
	n.fractal_lacunarity  = _g_lacunarity
	n.fractal_gain        = _g_gain
	n.domain_warp_enabled = _g_warp_amp > 0.0
	if _g_warp_amp > 0.0:
		n.domain_warp_amplitude = _g_warp_amp
	return n

func _build_detail_noise() -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type      = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.seed            = _d_seed
	n.frequency       = _d_freq
	n.fractal_octaves = _d_octaves
	return n

func _sample_color(noise: FastNoiseLite, noise_d: FastNoiseLite, x: int, y: int) -> Color:
	var vg: float = noise.get_noise_2d(x, y)
	var vd: float = noise_d.get_noise_2d(x, y)
	if vd > _accent_thr:
		return _accent_colors[abs(x * 3 + y) % _accent_colors.size()]
	return _noise_to_color(vg)

func _noise_to_color(v: float) -> Color:
	if   v > _thresholds[0]: return _grass_colors[0]
	elif v > _thresholds[1]: return _grass_colors[1]
	elif v > _thresholds[2]: return _grass_colors[2]
	elif v > _thresholds[3]: return _grass_colors[3]
	else:                    return _grass_colors[4]

# -------------------------------------------------------
# UI helpers
# -------------------------------------------------------
func _add_title(p: VBoxContainer, t: String) -> void:
	var l := Label.new(); l.text = t
	l.add_theme_color_override("font_color", Color(0.4,0.9,0.3)); p.add_child(l)

func _add_separator(p: VBoxContainer, t: String) -> void:
	var l := Label.new(); l.text = t
	l.add_theme_color_override("font_color", Color(0.9,0.75,0.3)); p.add_child(l)

func _add_option(p: VBoxContainer, label: String, items: Array, current_val: int, on_change: Callable) -> void:
	var row := HBoxContainer.new(); p.add_child(row)
	var lbl := Label.new(); lbl.text = label; lbl.custom_minimum_size.x = 100; row.add_child(lbl)
	var opt := OptionButton.new(); opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sel := 0
	for i in items.size():
		opt.add_item(items[i][0])
		if items[i][1] == current_val: sel = i
	opt.selected = sel
	opt.item_selected.connect(on_change); row.add_child(opt)

func _add_slider(p: VBoxContainer, label: String, min_v: float, max_v: float, default_v: float, step_v: float, on_change: Callable) -> void:
	var row := HBoxContainer.new(); p.add_child(row)
	var lbl := Label.new(); lbl.text = label; lbl.custom_minimum_size.x = 100; row.add_child(lbl)
	var s := HSlider.new(); s.min_value=min_v; s.max_value=max_v; s.value=default_v; s.step=step_v
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(s)
	var vl := Label.new(); vl.text = str(snapped(default_v,step_v)); vl.custom_minimum_size.x=48; row.add_child(vl)
	s.value_changed.connect(func(v:float): vl.text=str(snapped(v,step_v)); on_change.call(v))

func _add_color_row(p: VBoxContainer, colors: Array, labels: Array, on_change: Callable) -> void:
	var row := HBoxContainer.new(); p.add_child(row)
	for i in colors.size():
		var col := VBoxContainer.new(); row.add_child(col)
		var lbl := Label.new(); lbl.text = labels[i] if i < labels.size() else str(i)
		lbl.add_theme_font_size_override("font_size", 9); col.add_child(lbl)
		var cp := ColorPickerButton.new(); cp.color = colors[i]; cp.custom_minimum_size = Vector2(48,28)
		var idx := i
		cp.color_changed.connect(func(c:Color): on_change.call(idx,c)); col.add_child(cp)

func _print_values() -> void:
	print("\n=== Ground Painter — Valeurs ===")
	print("noise_type: ",_g_type," | seed: ",_g_seed," | freq: ",_g_freq)
	print("fractal: ",_g_fbm," | octaves: ",_g_octaves," | lacunarity: ",_g_lacunarity," | gain: ",_g_gain)
	print("warp_amp: ",_g_warp_amp)
	print("thresholds: ",_thresholds)
	print("detail: seed=",_d_seed," freq=",_d_freq," octaves=",_d_octaves," thr=",_accent_thr)
	print("GRASS:")
	for c in _grass_colors: print("  Color(",snapped(c.r,.001),",",snapped(c.g,.001),",",snapped(c.b,.001),")")
	print("ACCENT:")
	for c in _accent_colors: print("  Color(",snapped(c.r,.001),",",snapped(c.g,.001),",",snapped(c.b,.001),")")
	print("================================\n")
