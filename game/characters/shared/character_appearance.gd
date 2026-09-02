# character_appearance.gd
# Gere les calques de sprites du personnage (joueur ET NPC).
#
# FORMAT DU SPRITESHEET : 720 x 352 px total
# Taille d'une frame    : 144 x 352 px
# Nombre de colonnes    : 5
# Nombre de lignes      : 1 (pour l'instant)
#
#   |<-144px->|<-144px->|<-144px->|<-144px->|<-144px->|
#   |  col 0  |  col 1  |  col 2  |  col 3  |  col 4  |
#   | (vide/  |  face   | profil  |   dos   | profil  |
#   | futur   |  down   |  right  |   up    |  left   |
#   | portrait|         |         |         |         |
#
# Col 0 = reserve pour portrait dialogue (futur)
# Col 1 = face (direction down)
# Col 2 = profil droit (direction right)
# Col 3 = dos (direction up)
# Col 4 = profil gauche (direction left)
#
# Chaque calque = un fichier PNG independant avec le meme layout.
extends Node

# -- Calques monde ----------------------------------------------------------------
@onready var _body:        Sprite2D = $BodySprite
@onready var _eyes:        Sprite2D = $EyesSprite
@onready var _hair:        Sprite2D = $HairSprite
@onready var _outfit:      Sprite2D = $OutfitSprite
@onready var _accessories: Sprite2D = $AccessoriesSprite

# -- Calque portrait (dialogue, futur) --------------------------------------------
@onready var _portrait: Sprite2D = $PortraitSprite

# -- Dimensions -------------------------------------------------------------------
const FRAME_W:     int = 144
const FRAME_H:     int = 352
const TOTAL_COLS:  int = 5
const TOTAL_ROWS:  int = 1

# Colonnes
const COL_PORTRAIT: int = 0
const COL_DOWN:     int = 1
const COL_RIGHT:    int = 2
const COL_UP:       int = 3
const COL_LEFT:     int = 4

const DIR_TO_COL: Dictionary = {
	"down":  COL_DOWN,
	"right": COL_RIGHT,
	"up":    COL_UP,
	"left":  COL_LEFT,
}

const ROW_IDLE: int = 0

# -- Options pour la generation aleatoire -----------------------------------------
const GENDERS:   Array[String] = ["male", "female"]
const HAIRS:     Array[String] = ["short", "long", "bald"]
const EYE_STYLES: Array[String] = ["normal", "sharp"]
const OUTFITS:   Array[String] = ["peasant", "warrior", "mage"]

# -- Chemins ----------------------------------------------------------------------
const BASE_PATH: String = "res://game/assets/sprites/characters/"

# -- Etat interne -----------------------------------------------------------------
var _direction:   String = "down"
var _current_row: int    = ROW_IDLE
var _gender:      String = "female"
var _walk_frame:  int    = 0

# Donnees d'apparence courantes (pour get_appearance_data)
var _appearance_data: Dictionary = {}


# -- Init -------------------------------------------------------------------------
func _ready() -> void:
	if is_instance_valid(_portrait):
		_portrait.visible = false
	_direction = "down"
	for spr: Sprite2D in [_body, _eyes, _hair, _outfit, _accessories]:
		if is_instance_valid(spr):
			spr.hframes = TOTAL_COLS
			spr.vframes = TOTAL_ROWS
			spr.frame   = COL_DOWN


# -- API publique -----------------------------------------------------------------

func apply_appearance(appearance: Dictionary) -> void:
	if appearance.is_empty():
		return
	_appearance_data = appearance.duplicate()
	_gender = appearance.get("gender", "female")

	_load_layer(_body,   "body",   "body_%s"   % _gender)
	_load_layer(_eyes,   "eyes",   "eyes_%s"   % appearance.get("eye_style", "normal"))
	_load_layer(_hair,   "hair",   "hair_%s"   % appearance.get("hair",      "short"))
	_load_layer(_outfit, "outfit", "outfit_%s" % appearance.get("outfit",    "peasant"))
	if is_instance_valid(_accessories):
		_accessories.visible = false

	_tint(_body,   appearance.get("skin_color",   Color.WHITE))
	_tint(_hair,   appearance.get("hair_color",   Color.WHITE))
	_tint(_eyes,   appearance.get("eyes_color",   Color.WHITE))
	_tint(_outfit, appearance.get("outfit_color", Color.WHITE))

	_refresh_frame()


## Alias utilise par random_npc.gd / npc_offline_sim via apply_appearance_data
func apply_appearance_data(data: Dictionary) -> void:
	apply_appearance(data)


## Genere une apparence aleatoire et l'applique.
## Appele par random_npc.gd lors de la randomization.
func randomize_appearance() -> void:
	var adat: Dictionary = {
		"gender":       GENDERS.pick_random(),
		"hair":         HAIRS.pick_random(),
		"eye_style":    EYE_STYLES.pick_random(),
		"outfit":       OUTFITS.pick_random(),
		"skin_color":   Color(randf_range(0.6, 1.0), randf_range(0.4, 0.8), randf_range(0.3, 0.6)),
		"hair_color":   Color(randf(), randf(), randf()),
		"eyes_color":   Color(randf_range(0.0, 0.5), randf_range(0.3, 0.8), randf_range(0.5, 1.0)),
		"outfit_color": Color(randf_range(0.2, 0.9), randf_range(0.2, 0.9), randf_range(0.2, 0.9)),
	}
	apply_appearance(adat)


## Retourne les donnees d'apparence courantes.
## Utilise par random_npc.gd apres randomize_appearance() pour lire le genre.
func get_appearance_data() -> Dictionary:
	return _appearance_data.duplicate()


func set_direction(dir: String) -> void:
	_direction = dir
	_refresh_frame()


func set_idle() -> void:
	_current_row = ROW_IDLE
	_refresh_frame()


## Appele par player.gd a chaque frame d'animation de marche.
## Quand TOTAL_ROWS == 1 : ignore la valeur, applique juste la direction.
func set_walk_frame(frame_index: int) -> void:
	_walk_frame = frame_index
	_refresh_frame()


func show_portrait(show: bool) -> void:
	if is_instance_valid(_portrait):
		_portrait.visible = show


func get_portrait_region() -> Dictionary:
	if is_instance_valid(_body) and _body.texture != null:
		return {
			"texture": _body.texture,
			"region":  Rect2(COL_PORTRAIT * FRAME_W, ROW_IDLE * FRAME_H, FRAME_W, FRAME_H)
		}
	return {}


# -- Interne ----------------------------------------------------------------------

func _load_layer(spr: Sprite2D, folder: String, filename: String) -> void:
	if not is_instance_valid(spr):
		return
	var path: String = "%s%s/%s.png" % [BASE_PATH, folder, filename]
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		spr.texture  = tex
		spr.hframes  = TOTAL_COLS
		spr.vframes  = TOTAL_ROWS
		spr.visible  = true
		if spr == _body:
			_update_portrait(tex)
	else:
		spr.visible = false
		push_warning("[CharacterAppearance] Sprite MANQUANT : " + path)


func _update_portrait(tex: Texture2D) -> void:
	if not is_instance_valid(_portrait):
		return
	_portrait.texture        = tex
	_portrait.region_enabled = true
	_portrait.region_rect    = Rect2(
		COL_PORTRAIT * FRAME_W,
		ROW_IDLE     * FRAME_H,
		FRAME_W,
		FRAME_H
	)
	_portrait.hframes = 1
	_portrait.vframes = 1


func _tint(spr: Sprite2D, col: Color) -> void:
	if is_instance_valid(spr):
		spr.modulate = col


func _refresh_frame() -> void:
	var col:   int = DIR_TO_COL.get(_direction, COL_DOWN)
	var frame: int = _current_row * TOTAL_COLS + col
	for spr: Sprite2D in [_body, _eyes, _hair, _outfit, _accessories]:
		if is_instance_valid(spr) and spr.visible:
			spr.frame = frame
