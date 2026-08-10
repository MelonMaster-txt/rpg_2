# character_appearance.gd
# Gere les calques de sprites du personnage (joueur ET NPC).
#
# TAILLE DU PERSONNAGE : ~19x16px => cellules 16x32px (marge en hauteur)
#
# Structure du spritesheet (UN seul fichier par calque, 64x32px minimum) :
#
#   |<-16px->|<-16px->|<-16px->|<-16px->|
#   |col 0   |col 1   |col 2   |col 3   |
#   |PORTRAIT|PROFIL_G|  DOS   |PROFIL_D|  <- ligne 0 : idle
#   |        |        |        |        |  <- ligne 1 : walk A (a ajouter)
#   |        |        |        |        |  <- ligne 2 : walk B (a ajouter)
#
# Col 0 = portrait dialogue (via region_rect)
# Col 1-3 = sprites in-game (via hframes/vframes)
#
# Taille image finale : 64 x (32 * TOTAL_ROWS) px
extends Node2D

# -- Calques monde ----------------------------------------------------------------
@onready var _body:        Sprite2D = $BodySprite
@onready var _eyes:        Sprite2D = $EyesSprite
@onready var _hair:        Sprite2D = $HairSprite
@onready var _outfit:      Sprite2D = $OutfitSprite
@onready var _accessories: Sprite2D = $AccessoriesSprite

# -- Calque portrait (dialogue) ---------------------------------------------------
@onready var _portrait: Sprite2D = $PortraitSprite

# -- Taille cellule ---------------------------------------------------------------
const CELL_W: int = 16   # largeur  cellule px
const CELL_H: int = 32   # hauteur  cellule px

# Colonnes du sheet
const TOTAL_COLS: int = 4
const COL_PORTRAIT: int = 0
const COL_LEFT:     int = 1
const COL_UP:       int = 2
const COL_RIGHT:    int = 3
const COL_DOWN:     int = 1   # pas de face -> reutilise profil_g

const DIR_TO_COL: Dictionary = {
	"down":  COL_DOWN,
	"left":  COL_LEFT,
	"right": COL_RIGHT,
	"up":    COL_UP,
}

# Lignes
const ROW_IDLE:   int = 0
const ROW_WALK_A: int = 1
const ROW_WALK_B: int = 2
const ROW_ATTACK: int = 3
const ROW_WORK:   int = 4

# Nombre de lignes actuel (incrementer quand tu ajoutes des animations)
var total_rows: int = 1

# -- Chemins ----------------------------------------------------------------------
const BASE_PATH := "res://game/assets/sprites/characters/"

# -- Etat interne -----------------------------------------------------------------
var _direction:   String = "down"
var _current_row: int    = ROW_IDLE
var _gender:      String = "male"


# -- Init -------------------------------------------------------------------------
func _ready() -> void:
	if is_instance_valid(_portrait):
		_portrait.visible = false


# -- API publique -----------------------------------------------------------------

## Charge textures + couleurs. Appele depuis player.gd ou NPC.gd
func apply_appearance(appearance: Dictionary) -> void:
	if appearance.is_empty():
		return

	_gender = appearance.get("gender", "male")

	_load_layer(_body,   "body",   "body_%s"   % _gender)
	_load_layer(_eyes,   "eyes",   "eyes_%s"   % appearance.get("eye_style", "normal"))
	_load_layer(_hair,   "hair",   "hair_%s"   % appearance.get("hair",     "short"))
	_load_layer(_outfit, "outfit", "outfit_%s" % appearance.get("outfit",   "peasant"))
	if is_instance_valid(_accessories):
		_accessories.visible = false

	_tint(_body,   appearance.get("skin_color",   Color.WHITE))
	_tint(_hair,   appearance.get("hair_color",   Color.WHITE))
	_tint(_eyes,   appearance.get("eyes_color",   Color.WHITE))
	_tint(_outfit, appearance.get("outfit_color", Color.WHITE))

	_refresh_frames()


## Affiche/cache le portrait dans la scene (pas dans la UI)
func show_portrait(show: bool) -> void:
	if is_instance_valid(_portrait):
		_portrait.visible = show


## Retourne texture + region du portrait pour la boite de dialogue
## Usage : $DialogueBox/Portrait.texture = data.texture
##         $DialogueBox/Portrait.region_enabled = true
##         $DialogueBox/Portrait.region_rect = data.region
func get_portrait_region() -> Dictionary:
	if is_instance_valid(_body) and _body.texture != null:
		return {
			"texture": _body.texture,
			"region":  Rect2(COL_PORTRAIT * CELL_W, ROW_IDLE * CELL_H, CELL_W, CELL_H)
		}
	return {}


## Direction : "down" | "left" | "right" | "up"
func set_direction(dir: String) -> void:
	_direction = dir
	_refresh_frames()


## Walk frame — decommenter le corps quand les lignes walk sont dessinees
func set_walk_frame(_frame: int) -> void:
	pass
	# _current_row = ROW_WALK_A if (_frame % 2 == 0) else ROW_WALK_B
	# _refresh_frames()


func set_idle() -> void:
	_current_row = ROW_IDLE
	_refresh_frames()


func set_attack() -> void:
	if total_rows > ROW_ATTACK:
		_current_row = ROW_ATTACK
		_refresh_frames()


func set_work() -> void:
	if total_rows > ROW_WORK:
		_current_row = ROW_WORK
		_refresh_frames()


# -- Interne ----------------------------------------------------------------------

func _load_layer(spr: Sprite2D, folder: String, filename: String) -> void:
	if not is_instance_valid(spr):
		return
	var path: String = "%s%s/%s.png" % [BASE_PATH, folder, filename]
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		spr.texture = tex
		spr.hframes = TOTAL_COLS
		spr.vframes = total_rows
		spr.visible = true
		# Met a jour le portrait si c'est le calque body
		if spr == _body:
			_update_portrait(tex)
	else:
		spr.visible = false
		push_warning("[CharacterAppearance] Sprite manquant : " + path)


func _update_portrait(tex: Texture2D) -> void:
	if not is_instance_valid(_portrait):
		return
	# Meme texture que body, on prend juste la col 0 via region_rect
	_portrait.texture        = tex
	_portrait.region_enabled = true
	_portrait.region_rect    = Rect2(
		COL_PORTRAIT * CELL_W,
		ROW_IDLE     * CELL_H,
		CELL_W,
		CELL_H
	)
	_portrait.hframes = 1
	_portrait.vframes = 1


func _tint(spr: Sprite2D, col: Color) -> void:
	if is_instance_valid(spr):
		spr.modulate = col


func _refresh_frames() -> void:
	var col: int   = DIR_TO_COL.get(_direction, COL_LEFT)
	var frame: int = _current_row * TOTAL_COLS + col
	for spr: Sprite2D in [_body, _eyes, _hair, _outfit, _accessories]:
		if is_instance_valid(spr) and spr.visible:
			spr.frame = frame
