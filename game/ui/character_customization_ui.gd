# character_customization_ui.gd
# Écran de personnalisation du joueur avant le lancement de la partie.
# S'affiche au démarrage, puis émet character_confirmed(data) quand le joueur valide.
# À connecter dans main.gd : CharacterCustomizationUI.character_confirmed.connect(_on_character_confirmed)
extends Control

signal character_confirmed(appearance_data: Dictionary)

# Référence au CharacterAppearance pour le preview live
@onready var _preview_appearance: Node = $PreviewPlayer/CharacterAppearance

# Boutons de navigation
@onready var _btn_gender_prev:  Button = $UI/Rows/GenderRow/BtnPrev
@onready var _btn_gender_next:  Button = $UI/Rows/GenderRow/BtnNext
@onready var _lbl_gender:       Label  = $UI/Rows/GenderRow/Label

@onready var _btn_hair_prev:    Button = $UI/Rows/HairRow/BtnPrev
@onready var _btn_hair_next:    Button = $UI/Rows/HairRow/BtnNext
@onready var _lbl_hair:         Label  = $UI/Rows/HairRow/Label

@onready var _btn_eyes_prev:    Button = $UI/Rows/EyesRow/BtnPrev
@onready var _btn_eyes_next:    Button = $UI/Rows/EyesRow/BtnNext
@onready var _lbl_eyes:         Label  = $UI/Rows/EyesRow/Label

@onready var _btn_outfit_prev:  Button = $UI/Rows/OutfitRow/BtnPrev
@onready var _btn_outfit_next:  Button = $UI/Rows/OutfitRow/BtnNext
@onready var _lbl_outfit:       Label  = $UI/Rows/OutfitRow/Label

# Sliders couleur
@onready var _slider_skin_r:    HSlider = $UI/Colors/SkinRow/R
@onready var _slider_skin_g:    HSlider = $UI/Colors/SkinRow/G
@onready var _slider_skin_b:    HSlider = $UI/Colors/SkinRow/B

@onready var _slider_hair_r:    HSlider = $UI/Colors/HairColorRow/R
@onready var _slider_hair_g:    HSlider = $UI/Colors/HairColorRow/G
@onready var _slider_hair_b:    HSlider = $UI/Colors/HairColorRow/B

@onready var _slider_eyes_r:    HSlider = $UI/Colors/EyeColorRow/R
@onready var _slider_eyes_g:    HSlider = $UI/Colors/EyeColorRow/G
@onready var _slider_eyes_b:    HSlider = $UI/Colors/EyeColorRow/B

@onready var _btn_confirm:      Button  = $UI/BtnConfirm
@onready var _btn_random:       Button  = $UI/BtnRandom

# Index courants
var _idx_gender: int  = 0
var _idx_hair:   int  = 0
var _idx_eyes:   int  = 0
var _idx_outfit: int  = 0

const GENDERS:  Array[String] = ["male", "female"]
const HAIRS:    Array[String] = ["short", "medium", "long", "bald"]
const EYE_STYLES: Array[String] = ["normal", "closed", "angry", "sad"]
const OUTFITS:  Array[String] = ["peasant", "guard", "mage", "farmer"]


func _ready() -> void:
	_connect_signals()
	_apply_preview()


func _connect_signals() -> void:
	_btn_gender_prev.pressed.connect(func() -> void: _cycle("gender", -1))
	_btn_gender_next.pressed.connect(func() -> void: _cycle("gender",  1))
	_btn_hair_prev.pressed.connect(func()   -> void: _cycle("hair",   -1))
	_btn_hair_next.pressed.connect(func()   -> void: _cycle("hair",    1))
	_btn_eyes_prev.pressed.connect(func()   -> void: _cycle("eyes",   -1))
	_btn_eyes_next.pressed.connect(func()   -> void: _cycle("eyes",    1))
	_btn_outfit_prev.pressed.connect(func() -> void: _cycle("outfit", -1))
	_btn_outfit_next.pressed.connect(func() -> void: _cycle("outfit",  1))

	for slider: HSlider in [_slider_skin_r, _slider_skin_g, _slider_skin_b,
							_slider_hair_r, _slider_hair_g, _slider_hair_b,
							_slider_eyes_r, _slider_eyes_g, _slider_eyes_b]:
		slider.value_changed.connect(func(_v: float) -> void: _apply_preview())

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
	_lbl_gender.text  = GENDERS[_idx_gender].capitalize()
	_lbl_hair.text    = HAIRS[_idx_hair].capitalize()
	_lbl_eyes.text    = EYE_STYLES[_idx_eyes].capitalize()
	_lbl_outfit.text  = OUTFITS[_idx_outfit].capitalize()

	var data: Dictionary = _build_data()
	if is_instance_valid(_preview_appearance):
		_preview_appearance.apply_appearance_data(data)


func _build_data() -> Dictionary:
	return {
		"gender":       GENDERS[_idx_gender],
		"hair":         HAIRS[_idx_hair],
		"eye_style":    EYE_STYLES[_idx_eyes],
		"outfit":       OUTFITS[_idx_outfit],
		"skin_color":   Color(_slider_skin_r.value, _slider_skin_g.value, _slider_skin_b.value),
		"hair_color":   Color(_slider_hair_r.value, _slider_hair_g.value, _slider_hair_b.value),
		"eyes_color":   Color(_slider_eyes_r.value, _slider_eyes_g.value, _slider_eyes_b.value),
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
	_slider_skin_r.value = randf_range(0.5, 1.0)
	_slider_skin_g.value = randf_range(0.35, 0.85)
	_slider_skin_b.value = randf_range(0.2, 0.6)
	_slider_hair_r.value = randf_range(0.1, 0.9)
	_slider_hair_g.value = randf_range(0.05, 0.6)
	_slider_hair_b.value = randf_range(0.0, 0.3)
	_slider_eyes_r.value = randf_range(0.1, 1.0)
	_slider_eyes_g.value = randf_range(0.1, 1.0)
	_slider_eyes_b.value = randf_range(0.2, 1.0)
	_apply_preview()
