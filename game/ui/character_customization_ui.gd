# character_customization_ui.gd
extends Control

@onready var _btn_gender_prev  := $UI/Rows/GenderRow/BtnPrev  as Button
@onready var _btn_gender_next  := $UI/Rows/GenderRow/BtnNext  as Button
@onready var _lbl_gender       := $UI/Rows/GenderRow/Label    as Label
@onready var _btn_hair_prev    := $UI/Rows/HairRow/BtnPrev    as Button
@onready var _btn_hair_next    := $UI/Rows/HairRow/BtnNext    as Button
@onready var _lbl_hair         := $UI/Rows/HairRow/Label      as Label
@onready var _btn_eyes_prev    := $UI/Rows/EyesRow/BtnPrev    as Button
@onready var _btn_eyes_next    := $UI/Rows/EyesRow/BtnNext    as Button
@onready var _lbl_eyes         := $UI/Rows/EyesRow/Label      as Label
@onready var _btn_outfit_prev  := $UI/Rows/OutfitRow/BtnPrev  as Button
@onready var _btn_outfit_next  := $UI/Rows/OutfitRow/BtnNext  as Button
@onready var _lbl_outfit       := $UI/Rows/OutfitRow/Label    as Label

@onready var _presets_row  := $UI/Colors/SkinSection/PresetsRow as HBoxContainer
@onready var _picker_hair  := $UI/Colors/HairSection/HairPicker  as ColorPickerButton
@onready var _picker_eyes  := $UI/Colors/EyesSection/EyesPicker  as ColorPickerButton

@onready var _btn_confirm  := $UI/BtnConfirm as Button
@onready var _btn_back     := $UI/BtnBack    as Button
@onready var _btn_random   := $UI/BtnRandom  as Button

var _preview_rect: TextureRect = null

const BASE_PATH: String = "res://game/assets/sprites/characters/body/"
const POSE_W: int = 180
const POSE_H: int = 352

const SKIN_PRESETS: Array = [
	Color(1.00, 0.87, 0.74),
	Color(0.96, 0.76, 0.57),
	Color(0.89, 0.65, 0.44),
	Color(0.80, 0.55, 0.34),
	Color(0.67, 0.42, 0.24),
	Color(0.52, 0.30, 0.15),
	Color(0.36, 0.20, 0.10),
	Color(0.20, 0.11, 0.06),
]

const GENDERS:    Array = ["female", "male"]
const HAIRS:      Array = ["none", "short", "medium", "long", "bald"]
const EYE_STYLES: Array = ["none", "normal", "closed", "angry", "sad"]
const OUTFITS:    Array = ["none", "peasant", "guard", "mage", "farmer"]

var _idx_gender: int   = 0
var _idx_hair:   int   = 1
var _idx_eyes:   int   = 1
var _idx_outfit: int   = 1
var _skin_color: Color = SKIN_PRESETS[2]


func _ready() -> void:
	_setup_skin_presets()
	_connect_signals()
	_refresh_labels()
	# Le preview est cree apres un frame pour que la taille de la fenetre soit connue
	call_deferred("_build_preview_widget")


func _build_preview_widget() -> void:
	# On utilise un simple Control positionne avec position/size absolue
	# dans la moitie droite de l'ecran
	var screen_size: Vector2 = get_viewport_rect().size
	var preview_zone := Control.new()
	preview_zone.name = "PreviewZone"
	preview_zone.position = Vector2(screen_size.x * 0.35, screen_size.y * 0.05)
	preview_zone.size = Vector2(screen_size.x * 0.65, screen_size.y * 0.90)
	add_child(preview_zone)

	_preview_rect = TextureRect.new()
	_preview_rect.name = "BodyPreview"
	_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	# Centrer dans la zone
	_preview_rect.set_anchor_and_offset(SIDE_LEFT,   0.0, 0.0)
	_preview_rect.set_anchor_and_offset(SIDE_TOP,    0.0, 0.0)
	_preview_rect.set_anchor_and_offset(SIDE_RIGHT,  1.0, 0.0)
	_preview_rect.set_anchor_and_offset(SIDE_BOTTOM, 1.0, 0.0)
	preview_zone.add_child(_preview_rect)

	_refresh_preview()


func _setup_skin_presets() -> void:
	for i: int in SKIN_PRESETS.size():
		var col: Color = SKIN_PRESETS[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(30, 30)
		btn.tooltip_text = col.to_html()
		var style := StyleBoxFlat.new()
		style.bg_color = col
		style.corner_radius_top_left     = 4
		style.corner_radius_top_right    = 4
		style.corner_radius_bottom_left  = 4
		style.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("normal", style)
		_presets_row.add_child(btn)
		var captured_col: Color = col
		btn.pressed.connect(func() -> void:
			_skin_color = captured_col
			_refresh_preview()
		)


func _connect_signals() -> void:
	_btn_gender_prev.pressed.connect(func() -> void: _cycle("gender", -1))
	_btn_gender_next.pressed.connect(func() -> void: _cycle("gender",  1))
	_btn_hair_prev.pressed.connect(func()   -> void: _cycle("hair",   -1))
	_btn_hair_next.pressed.connect(func()   -> void: _cycle("hair",    1))
	_btn_eyes_prev.pressed.connect(func()   -> void: _cycle("eyes",   -1))
	_btn_eyes_next.pressed.connect(func()   -> void: _cycle("eyes",    1))
	_btn_outfit_prev.pressed.connect(func() -> void: _cycle("outfit", -1))
	_btn_outfit_next.pressed.connect(func() -> void: _cycle("outfit",  1))
	_btn_confirm.pressed.connect(_on_confirm)
	_btn_back.pressed.connect(_on_back)
	_btn_random.pressed.connect(_on_random)
	_picker_hair.color_changed.connect(func(_c: Color) -> void: _refresh_preview())
	_picker_eyes.color_changed.connect(func(_c: Color) -> void: _refresh_preview())


func _cycle(target: String, dir: int) -> void:
	match target:
		"gender":  _idx_gender = wrapi(_idx_gender + dir, 0, GENDERS.size())
		"hair":    _idx_hair   = wrapi(_idx_hair   + dir, 0, HAIRS.size())
		"eyes":    _idx_eyes   = wrapi(_idx_eyes   + dir, 0, EYE_STYLES.size())
		"outfit":  _idx_outfit = wrapi(_idx_outfit + dir, 0, OUTFITS.size())
	_refresh_labels()
	_refresh_preview()


func _refresh_labels() -> void:
	_lbl_gender.text = GENDERS[_idx_gender].capitalize()
	_lbl_hair.text   = HAIRS[_idx_hair].capitalize()
	_lbl_eyes.text   = EYE_STYLES[_idx_eyes].capitalize()
	_lbl_outfit.text = OUTFITS[_idx_outfit].capitalize()


func _refresh_preview() -> void:
	if not is_instance_valid(_preview_rect):
		return
	var gender: String = GENDERS[_idx_gender]
	var path: String = BASE_PATH + "body_%s.png" % gender
	if not ResourceLoader.exists(path):
		path = BASE_PATH + "body_female.png"
	if not ResourceLoader.exists(path):
		_preview_rect.texture = null
		push_warning("[Preview] Aucun sprite body trouve dans : " + BASE_PATH)
		return
	var full_tex: Texture2D = load(path)
	var atlas := AtlasTexture.new()
	atlas.atlas  = full_tex
	# Pose face = 1ere colonne, 180x352
	atlas.region = Rect2(0, 0, POSE_W, POSE_H)
	_preview_rect.texture  = atlas
	_preview_rect.modulate = _skin_color


func _build_data() -> Dictionary:
	return {
		"gender":       GENDERS[_idx_gender],
		"hair":         HAIRS[_idx_hair],
		"eye_style":    EYE_STYLES[_idx_eyes],
		"outfit":       OUTFITS[_idx_outfit],
		"skin_color":   _skin_color,
		"hair_color":   _picker_hair.color if is_instance_valid(_picker_hair) else Color.BROWN,
		"eyes_color":   _picker_eyes.color if is_instance_valid(_picker_eyes) else Color.BLUE,
		"outfit_color": Color(0.55, 0.38, 0.20),
	}


func _on_confirm() -> void:
	GameState.player_appearance = _build_data()
	get_tree().change_scene_to_file(GameState.OVERWORLD)


func _on_back() -> void:
	get_tree().change_scene_to_file("res://game/ui/menu/main_menu.tscn")


func _on_random() -> void:
	_idx_gender = randi() % GENDERS.size()
	_idx_hair   = randi() % HAIRS.size()
	_idx_eyes   = randi() % EYE_STYLES.size()
	_idx_outfit = randi() % OUTFITS.size()
	_skin_color = SKIN_PRESETS[randi() % SKIN_PRESETS.size()]
	if is_instance_valid(_picker_hair):
		_picker_hair.color = Color(randf_range(0.1, 0.9), randf_range(0.05, 0.6), randf_range(0.0, 0.3))
	if is_instance_valid(_picker_eyes):
		_picker_eyes.color = Color(randf_range(0.1, 1.0), randf_range(0.2, 1.0), randf_range(0.2, 1.0))
	_refresh_labels()
	_refresh_preview()
