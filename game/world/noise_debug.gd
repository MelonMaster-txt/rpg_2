# noise_debug.gd - Panel debug noise, toggle avec F2
extends PanelContainer

const SAVE_PATH    := "user://noise_settings.cfg"
const PREVIEW_SIZE := 256

var _g_seed        : int   = 42
var _g_type        : int   = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
var _g_freq        : float = 0.003
var _g_octaves     : int   = 4
var _g_lacunarity  : float = 2.0
var _g_gain        : float = 0.5
var _g_fbm         : int   = FastNoiseLite.FRACTAL_FBM
var _g_warp_amp    : float = 0.0

var _d_seed        : int   = 99
var _d_freq        : float = 0.008
var _d_octaves     : int   = 2
var _accent_thr    : float = 0.4

var _thresholds: Array[float]  = [0.3, 0.1, -0.1, -0.3]
var _grass_colors: Array[Color] = [
	Color(0.27, 0.58, 0.18), Color(0.24, 0.55, 0.16),
	Color(0.22, 0.52, 0.15), Color(0.18, 0.44, 0.12),
	Color(0.55, 0.38, 0.18),
]
var _accent_colors: Array[Color] = [
	Color(0.30, 0.62, 0.20), Color(0.55, 0.52, 0.18), Color(0.26, 0.56, 0.40),
]

var _tex_rect   : TextureRect
var _live_mode  : bool = false
var _status_lbl : Label

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
	# On met le groupe sur le CanvasLayer PARENT (le root de la scene noise_debug.tscn)
	# C'est lui qu'on toggle pour afficher/cacher tout le panel
	get_parent().add_to_group("noise_debug_root")
	custom_minimum_size = Vector2(370, 0)
	_load_cfg()
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(outer)

	_add_title(outer, "Ground Painter - Noise Debug  [F2]")

	_status_lbl = Label.new()
	_status_lbl.text = ""
	_status_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.3))
	outer.add_child(_status_lbl)

	var btn_row := HBoxContainer.new()
	outer.add_child(btn_row)

	var btn_save := Button.new()
	btn_save.text = "Sauvegarder"
	btn_save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_save.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	btn_save.pressed.connect(_save_cfg)
	btn_row.add_child(btn_save)

	var btn_repaint := Button.new()
	btn_repaint.text = "Repaint"
	btn_repaint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_repaint.pressed.connect(_repaint_all_chunks)
	btn_row.add_child(btn_repaint)

	var btn_load := Button.new()
	btn_load.text = "Recharger"
	btn_load.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_load.pressed.connect(func(): _load_cfg(); _refresh())
	btn_row.add_child(btn_load)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(370, 560)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	_tex_rect = TextureRect.new()
	_tex_rect.custom_minimum_size = Vector2(PREVIEW_SIZE, PREVIEW_SIZE)
	_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	vbox.add_child(_tex_rect)

	var live_row := HBoxContainer.new()
	vbox.add_child(live_row)
	var live_lbl := Label.new()
	live_lbl.text = "Repaint chunks live"
	live_lbl.custom_minimum_size.x = 180
	live_row.add_child(live_lbl)
	var live_toggle := CheckButton.new()
	live_toggle.toggled.connect(func(on: bool): _live_mode = on)
	live_row.add_child(live_toggle)

	_add_separator(vbox, "Noise Ground")
	_add_option(vbox, "Type",    NOISE_TYPES,   _g_type, func(i: int): _g_type = NOISE_TYPES[i][1] as int;    _refresh())
	_add_option(vbox, "Fractal", FRACTAL_TYPES, _g_fbm,  func(i: int): _g_fbm  = FRACTAL_TYPES[i][1] as int; _refresh())
	_add_slider(vbox, "Seed",       0,      9999, _g_seed,       1,      func(v: float): _g_seed = int(v);       _refresh())
	_add_slider(vbox, "Frequency",  0.0005, 0.05, _g_freq,       0.0005, func(v: float): _g_freq = v;            _refresh())
	_add_slider(vbox, "Octaves",    1,      8,    _g_octaves,    1,      func(v: float): _g_octaves = int(v);    _refresh())
	_add_slider(vbox, "Lacunarity", 1.0,    4.0,  _g_lacunarity, 0.05,   func(v: float): _g_lacunarity = v;      _refresh())
	_add_slider(vbox, "Gain",       0.1,    1.0,  _g_gain,       0.01,   func(v: float): _g_gain = v;            _refresh())
	_add_slider(vbox, "Warp Amp",   0.0,    200.0,_g_warp_amp,   1.0,    func(v: float): _g_warp_amp = v;        _refresh())

	_add_separator(vbox, "Seuils herbe")
	var thr_labels := ["Seuil 1 (clair)","Seuil 2","Seuil 3","Seuil 4 (fonce)"]
	for i in _thresholds.size():
		var idx := i
		_add_slider(vbox, thr_labels[i], -1.0, 1.0, _thresholds[i], 0.01,
			func(v: float): _thresholds[idx] = v; _refresh())

	_add_separator(vbox, "Couleurs herbe")
	var lg := ["Tres clair","Clair","Moyen","Fonce","Terre"]
	_add_color_row(vbox, _grass_colors, lg, func(i: int, c: Color): _grass_colors[i] = c; _refresh())

	_add_separator(vbox, "Noise Accent")
	_add_slider(vbox, "Seed",      0,     9999, _d_seed,     1,     func(v: float): _d_seed = int(v);    _refresh())
	_add_slider(vbox, "Frequency", 0.001, 0.05, _d_freq,     0.001, func(v: float): _d_freq = v;         _refresh())
	_add_slider(vbox, "Octaves",   1,     6,    _d_octaves,  1,     func(v: float): _d_octaves = int(v); _refresh())
	_add_slider(vbox, "Seuil",    -1.0,   1.0,  _accent_thr, 0.01,  func(v: float): _accent_thr = v;     _refresh())

	_add_separator(vbox, "Couleurs accent")
	var la := ["Vert vif","Mousse","Bleu-vert"]
	_add_color_row(vbox, _accent_colors, la, func(i: int, c: Color): _accent_colors[i] = c; _refresh())

func _refresh() -> void:
	var noise   := _build_ground_noise()
	var noise_d := _build_detail_noise()
	var img := Image.create(PREVIEW_SIZE, PREVIEW_SIZE, false, Image.FORMAT_RGB8)
	for y in PREVIEW_SIZE:
		for x in PREVIEW_SIZE:
			img.set_pixel(x, y, _sample_color(noise, noise_d, x, y))
	_tex_rect.texture = ImageTexture.create_from_image(img)
	if _live_mode:
		_repaint_all_chunks()

func _repaint_all_chunks() -> void:
	var noise   := _build_ground_noise()
	var noise_d := _build_detail_noise()
	for painter in get_tree().get_nodes_in_group("ground_painter"):
		if painter.has_method("repaint_with"):
			painter.call("repaint_with", noise, noise_d, _thresholds, _grass_colors, _accent_colors, _accent_thr)

func _save_cfg() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ground", "seed",       _g_seed)
	cfg.set_value("ground", "type",       _g_type)
	cfg.set_value("ground", "freq",       _g_freq)
	cfg.set_value("ground", "octaves",    _g_octaves)
	cfg.set_value("ground", "lacunarity", _g_lacunarity)
	cfg.set_value("ground", "gain",       _g_gain)
	cfg.set_value("ground", "fbm",        _g_fbm)
	cfg.set_value("ground", "warp_amp",   _g_warp_amp)
	cfg.set_value("accent", "seed",       _d_seed)
	cfg.set_value("accent", "freq",       _d_freq)
	cfg.set_value("accent", "octaves",    _d_octaves)
	cfg.set_value("accent", "threshold",  _accent_thr)
	for i in _thresholds.size():
		cfg.set_value("thresholds", "t" + str(i), _thresholds[i])
	for i in _grass_colors.size():
		cfg.set_value("grass_colors", "c" + str(i), _grass_colors[i])
	for i in _accent_colors.size():
		cfg.set_value("accent_colors", "c" + str(i), _accent_colors[i])
	var err := cfg.save(SAVE_PATH)
	_status_lbl.text = "OK -> " + SAVE_PATH if err == OK else "Erreur : " + str(err)

func _load_cfg() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK: return
	_g_seed       = cfg.get_value("ground", "seed",       _g_seed)
	_g_type       = cfg.get_value("ground", "type",       _g_type)
	_g_freq       = cfg.get_value("ground", "freq",       _g_freq)
	_g_octaves    = cfg.get_value("ground", "octaves",    _g_octaves)
	_g_lacunarity = cfg.get_value("ground", "lacunarity", _g_lacunarity)
	_g_gain       = cfg.get_value("ground", "gain",       _g_gain)
	_g_fbm        = cfg.get_value("ground", "fbm",        _g_fbm)
	_g_warp_amp   = cfg.get_value("ground", "warp_amp",   _g_warp_amp)
	_d_seed       = cfg.get_value("accent", "seed",       _d_seed)
	_d_freq       = cfg.get_value("accent", "freq",       _d_freq)
	_d_octaves    = cfg.get_value("accent", "octaves",    _d_octaves)
	_accent_thr   = cfg.get_value("accent", "threshold",  _accent_thr)
	for i in _thresholds.size():
		_thresholds[i] = cfg.get_value("thresholds", "t" + str(i), _thresholds[i])
	for i in _grass_colors.size():
		_grass_colors[i] = cfg.get_value("grass_colors", "c" + str(i), _grass_colors[i])
	for i in _accent_colors.size():
		_accent_colors[i] = cfg.get_value("accent_colors", "c" + str(i), _accent_colors[i])

func _build_ground_noise() -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type          = _g_type as FastNoiseLite.NoiseType
	n.seed                = _g_seed
	n.frequency           = _g_freq
	n.fractal_type        = _g_fbm as FastNoiseLite.FractalType
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
	var s := HSlider.new(); s.min_value = min_v; s.max_value = max_v; s.value = default_v; s.step = step_v
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(s)
	var vl := Label.new(); vl.text = str(snapped(default_v, step_v)); vl.custom_minimum_size.x = 48; row.add_child(vl)
	s.value_changed.connect(func(v: float): vl.text = str(snapped(v, step_v)); on_change.call(v))

func _add_color_row(p: VBoxContainer, colors: Array, labels: Array, on_change: Callable) -> void:
	var row := HBoxContainer.new(); p.add_child(row)
	for i in colors.size():
		var col := VBoxContainer.new(); row.add_child(col)
		var lbl := Label.new(); lbl.text = labels[i] if i < labels.size() else str(i)
		lbl.add_theme_font_size_override("font_size", 9); col.add_child(lbl)
		var cp := ColorPickerButton.new(); cp.color = colors[i]; cp.custom_minimum_size = Vector2(48, 28)
		var idx := i
		cp.color_changed.connect(func(c: Color): on_change.call(idx, c)); col.add_child(cp)
