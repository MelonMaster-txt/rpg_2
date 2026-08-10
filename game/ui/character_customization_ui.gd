# character_customization_ui.gd
# Ecran de personnalisation du joueur avant le lancement de la partie.
# Emet character_confirmed(data) quand le joueur valide.
extends Control

signal character_confirmed(appearance_data: Dictionary)

# ─── PREVIEW ───────────────────────────────────────────────────────────────────
@onready var _preview_appearance := $PreviewPlayer/CharacterAppearance

# ─── NAVIGATION GENRE / COIFFURE / YEUX / TENUE ────────────────────────────────
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

# ─── COLOR PICKER (ColorPickerButton) ──────────────────────────────────────────
@onready var _picker_skin  := $UI/Colors/SkinSection/SkinPicker   as ColorPickerButton
@onready var _picker_hair  := $UI/Colors/HairSection/HairPicker   as ColorPickerButton
@onready var _picker_eyes  := $UI/Colors/EyesSection/EyesPicker   as ColorPickerButton

# ─── BOUTONS ───────────────────────────────────────────────────────────────────
@onready var _btn_confirm  := $UI/BtnConfirm as Button
@onready var _btn_random   := $UI/BtnRandom  as Button

# ─── PRESETS COULEUR DE PEAU (8 nuances classiques) ────────────────────────────
const SKIN_PRESETS: Array = [
	Color(1.00, 0.87, 0.74),  # Tres claire
	Color(0.96, 0.76, 0.57),  # Claire
	Color(0.89, 0.65, 0.44),  # Peche
	Color(0.80, 0.55, 0.34),  # Beige dore
	Color(0.67, 0.42, 0.24),  # Hale
	Color(0.52, 0.30, 0.15),  # Brun chaud
	Color(0.36, 0.20, 0.10),  # Sombre
	Color(0.20, 0.11, 0.06),  # Tres sombre
]

# ─── DONNEES ───────────────────────────────────────────────────────────────────
const GENDERS:    Array = ["male", "female"]
const HAIRS:      Array = ["short", "medium", "long", "bald"]
const EYE_STYLES: Array = ["normal", "closed", "angry", "sad"]
const OUTFITS:    Array = ["peasant", "guard", "mage", "farmer"]

var _idx_gender: int = 0
var _idx_hair:   int = 0
var _idx_eyes:   int = 0
var _idx_outfit: int = 0


func _ready() -> void:
	_setup_skin_presets()
	_connect_signals()
	_apply_preview()


# Cree les boutons de preset de peau dynamiquement
func _setup_skin_presets() -> void:
	var container := $UI/Colors/SkinSection/PresetsRow as HBoxContainer
	for i in SKIN_PRESETS.size():
		var col: Color = SKIN_PRESETS[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(28, 28)
		var style := StyleBoxFlat.new()
		style.bg_color = col
		style.corner_radius_top_left    = 4
		style.corner_radius_top_right   = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("normal", style)
		btn.tooltip_text = col.to_html()
		container.add_child(btn)
		# Capture locale de la couleur pour le lambda
		var captured_col: Color = col
		btn.pressed.connect(func() -> void:
			_picker_skin.color = captured_col
			_apply_preview()
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
	_picker_skin.color_changed.connect(func(_c: Color) -> void: _apply_preview())
	_picker_hair.color_changed.connect(func(_c: Color) -> void: _apply_preview())
	_picker_eyes.color_changed.connect(func(_c: Color) -> void: _apply_preview())
	_btn_confirm.pressed.connect(_on_confirm)
	_btn_random.pressed.connect(_on_random)


func _cycle(target: String, dir: int) -> void:
	match target:
		"gender":
			_idx_gender = wrapi(_idx_gender + dir, 0, GENDERS.size())
		"hair":
			_idx_hair   = wrapi(_idx_hair   + dir, 0, HAIRS.size())
		"eyes":
			_idx_eyes   = wrapi(_idx_eyes   + dir, 0, EYE_STYLES.size())
		"outfit":
			_idx_outfit = wrapi(_idx_outfit + dir, 0, OUTFITS.size())
	_apply_preview()


func _apply_preview() -> void:
	_lbl_gender.text = GENDERS[_idx_gender].capitalize()
	_lbl_hair.text   = HAIRS[_idx_hair].capitalize()
	_lbl_eyes.text   = EYE_STYLES[_idx_eyes].capitalize()
	_lbl_outfit.text = OUTFITS[_idx_outfit].capitalize()
	if is_instance_valid(_preview_appearance):
		_preview_appearance.apply_appearance_data(_build_data())


func _build_data() -> Dictionary:
	return {
		"gender":       GENDERS[_idx_gender],
		"hair":         HAIRS[_idx_hair],
		"eye_style":    EYE_STYLES[_idx_eyes],
		"outfit":       OUTFITS[_idx_outfit],
		"skin_color":   _picker_skin.color,
		"hair_color":   _picker_hair.color,
		"eyes_color":   _picker_eyes.color,
		"outfit_color": Color(0.55, 0.38, 0.20),
	}


func _on_confirm() -> void:
	GameData.player_appearance = _build_data()
	character_confirmed.emit(GameData.player_appearance)
	queue_free()


func _on_random() -> void:
	_idx_gender = randi() % GENDERS.size()
	_idx_hair   = randi() % HAIRS.size()
	_idx_eyes   = randi() % EYE_STYLES.size()
	_idx_outfit = randi() % OUTFITS.size()
	_picker_skin.color  = SKIN_PRESETS[randi() % SKIN_PRESETS.size()]
	_picker_hair.color  = Color(randf_range(0.1, 0.9), randf_range(0.05, 0.6), randf_range(0.0, 0.3))
	_picker_eyes.color  = Color(randf_range(0.1, 1.0), randf_range(0.2, 1.0), randf_range(0.2, 1.0))
	_apply_preview()
