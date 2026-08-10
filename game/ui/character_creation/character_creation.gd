# character_creation.gd
# Ecran de creation/customisation du personnage.
# Remplit GameData.player_appearance puis lance le jeu.
extends Control

# -- Refs UI ----------------------------------------------------------------------
@onready var _preview:      Node          = $PreviewContainer/CharacterPreview/CharacterAppearance
@onready var _btn_confirm:  Button        = $ConfirmButton
@onready var _btn_gender:   Button        = $PanelContainer/VBox/GenderRow/BtnGender
@onready var _btn_hair_l:   Button        = $PanelContainer/VBox/HairRow/BtnHairLeft
@onready var _btn_hair_r:   Button        = $PanelContainer/VBox/HairRow/BtnHairRight
@onready var _lbl_hair:     Label         = $PanelContainer/VBox/HairRow/LblHair
@onready var _btn_eyes_l:   Button        = $PanelContainer/VBox/EyesRow/BtnEyesLeft
@onready var _btn_eyes_r:   Button        = $PanelContainer/VBox/EyesRow/BtnEyesRight
@onready var _lbl_eyes:     Label         = $PanelContainer/VBox/EyesRow/LblEyes
@onready var _btn_outfit_l: Button        = $PanelContainer/VBox/OutfitRow/BtnOutfitLeft
@onready var _btn_outfit_r: Button        = $PanelContainer/VBox/OutfitRow/BtnOutfitRight
@onready var _lbl_outfit:   Label         = $PanelContainer/VBox/OutfitRow/LblOutfit
@onready var _skin_picker:  ColorPickerButton = $PanelContainer/VBox/SkinRow/SkinPicker
@onready var _hair_picker:  ColorPickerButton = $PanelContainer/VBox/HairColorRow/HairPicker

# -- Options disponibles ----------------------------------------------------------
const HAIR_STYLES:   Array[String] = ["none", "short", "medium", "long"]
const EYE_STYLES:    Array[String] = ["normal", "angry", "sad", "closed"]
const OUTFIT_STYLES: Array[String] = ["none", "peasant", "guard", "farmer"]

# -- Etat courant -----------------------------------------------------------------
var _gender:       String = "male"
var _hair_idx:     int    = 1
var _eyes_idx:     int    = 0
var _outfit_idx:   int    = 1
var _skin_color:   Color  = Color("f5c5a3")
var _hair_color:   Color  = Color("3b1f0e")


# -- Init -------------------------------------------------------------------------
func _ready() -> void:
	_btn_confirm.pressed.connect(_on_confirm)
	_btn_gender.pressed.connect(_toggle_gender)
	_btn_hair_l.pressed.connect(func(): _cycle("hair", -1))
	_btn_hair_r.pressed.connect(func(): _cycle("hair",  1))
	_btn_eyes_l.pressed.connect(func(): _cycle("eyes", -1))
	_btn_eyes_r.pressed.connect(func(): _cycle("eyes",  1))
	_btn_outfit_l.pressed.connect(func(): _cycle("outfit", -1))
	_btn_outfit_r.pressed.connect(func(): _cycle("outfit",  1))
	_skin_picker.color_changed.connect(func(c): _skin_color = c; _refresh_preview())
	_hair_picker.color_changed.connect(func(c): _hair_color = c; _refresh_preview())
	_skin_picker.color = _skin_color
	_hair_picker.color = _hair_color
	_refresh_preview()


# -- Logique ----------------------------------------------------------------------

func _toggle_gender() -> void:
	_gender = "female" if _gender == "male" else "male"
	_btn_gender.text = _gender.capitalize()
	_refresh_preview()


func _cycle(what: String, dir: int) -> void:
	match what:
		"hair":
			_hair_idx = wrapi(_hair_idx + dir, 0, HAIR_STYLES.size())
			_lbl_hair.text = HAIR_STYLES[_hair_idx].capitalize()
		"eyes":
			_eyes_idx = wrapi(_eyes_idx + dir, 0, EYE_STYLES.size())
			_lbl_eyes.text = EYE_STYLES[_eyes_idx].capitalize()
		"outfit":
			_outfit_idx = wrapi(_outfit_idx + dir, 0, OUTFIT_STYLES.size())
			_lbl_outfit.text = OUTFIT_STYLES[_outfit_idx].capitalize()
	_refresh_preview()


func _refresh_preview() -> void:
	if not is_instance_valid(_preview):
		return
	_preview.apply_appearance(_build_appearance())


func _build_appearance() -> Dictionary:
	return {
		"gender":      _gender,
		"hair":        HAIR_STYLES[_hair_idx],
		"eye_style":   EYE_STYLES[_eyes_idx],
		"outfit":      OUTFIT_STYLES[_outfit_idx],
		"skin_color":  _skin_color,
		"hair_color":  _hair_color,
		"eyes_color":  Color.WHITE,
		"outfit_color":Color.WHITE,
	}


func _on_confirm() -> void:
	# Sauvegarde dans GameData (Autoload)
	GameData.player_appearance = _build_appearance()
	# Charge la scene de jeu
	get_tree().change_scene_to_file("res://game/scenes/world/world.tscn")
