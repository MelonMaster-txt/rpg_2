# character_appearance.gd
# Gere les calques de sprites du personnage (joueur ET NPC).
# A attacher sur un Node2D "CharacterAppearance" enfant de CharacterBody2D.
#
# Structure du spritesheet ACTUELLE (evoluera avec les animations) :
#
#         col0      col1       col2      col3
#         FACE    PROFIL_G    DOS     PROFIL_D
# ligne0 [idle↓]  [idle←]   [idle↑]   [idle→]    <- ce que tu as maintenant
#
# Quand tu ajoutes la marche, tu ajoutes des lignes :
# ligne1  walkA x4 directions
# ligne2  walkB x4 directions
# ligne3  attack x4 directions
# ligne4  work   x4 directions
# => et tu changes juste VFRAMES = 5 ci-dessous
extends Node2D

# -- Calques -----------------------------------------------------------------------
@onready var _body:        Sprite2D = $BodySprite
@onready var _eyes:        Sprite2D = $EyesSprite
@onready var _hair:        Sprite2D = $HairSprite
@onready var _outfit:      Sprite2D = $OutfitSprite
@onready var _accessories: Sprite2D = $AccessoriesSprite

# -- Grille -----------------------------------------------------------------------
# ADAPTER quand tu ajoutes des animations !
const HFRAMES := 4   # 4 colonnes = 4 directions
const VFRAMES := 1   # 1 ligne pour l'instant (juste idle)

# Indices des lignes (a utiliser quand VFRAMES > 1)
const ROW_IDLE:   int = 0
const ROW_WALK_A: int = 1
const ROW_WALK_B: int = 2
const ROW_ATTACK: int = 3
const ROW_WORK:   int = 4

# Colonnes : ordre de ton spritesheet actuel
# face=0, profil_gauche=1, dos=2, profil_droit=3
const COL_DOWN:  int = 0   # face
const COL_LEFT:  int = 1   # profil gauche
const COL_UP:    int = 2   # dos
const COL_RIGHT: int = 3   # profil droit

const DIR_TO_COL: Dictionary = {
	"down":  COL_DOWN,
	"left":  COL_LEFT,
	"right": COL_RIGHT,
	"up":    COL_UP,
}

# -- Chemin de base ---------------------------------------------------------------
const BASE_PATH := "res://game/assets/sprites/characters/"

# -- Etat interne -----------------------------------------------------------------
var _direction:   String = "down"
var _current_row: int    = ROW_IDLE
var _gender:      String = "male"


# -- Init -------------------------------------------------------------------------
func _ready() -> void:
	_setup_layers()


func _setup_layers() -> void:
	for spr: Sprite2D in [_body, _eyes, _hair, _outfit, _accessories]:
		if is_instance_valid(spr):
			spr.hframes = HFRAMES
			spr.vframes = VFRAMES


# -- API publique -----------------------------------------------------------------

## Charge textures + couleurs depuis GameState.player_appearance ou NPCData
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


## Appele par player.gd quand le joueur bouge
func set_direction(dir: String) -> void:
	_direction = dir
	_refresh_frames()


## Appele par player.gd : pour l'instant sans effet (pas d'anim walk)
## Quand tu ajoutes walkA/walkB, decommenter le bloc ci-dessous
func set_walk_frame(frame: int) -> void:
	pass
	## A decommenter quand VFRAMES >= 3 :
	# _current_row = ROW_WALK_A if (frame % 2 == 0) else ROW_WALK_B
	# _refresh_frames()


func set_idle() -> void:
	_current_row = ROW_IDLE
	_refresh_frames()


func set_attack() -> void:
	if VFRAMES > ROW_ATTACK:
		_current_row = ROW_ATTACK
		_refresh_frames()


func set_work() -> void:
	if VFRAMES > ROW_WORK:
		_current_row = ROW_WORK
		_refresh_frames()


# -- Interne ----------------------------------------------------------------------

func _load_layer(spr: Sprite2D, folder: String, filename: String) -> void:
	if not is_instance_valid(spr):
		return
	var path: String = "%s%s/%s.png" % [BASE_PATH, folder, filename]
	if ResourceLoader.exists(path):
		spr.texture = load(path)
		spr.hframes = HFRAMES
		spr.vframes = VFRAMES
		spr.visible = true
	else:
		spr.visible = false
		push_warning("[CharacterAppearance] Sprite manquant : " + path)


func _tint(spr: Sprite2D, col: Color) -> void:
	if is_instance_valid(spr):
		spr.modulate = col


func _refresh_frames() -> void:
	var col: int   = DIR_TO_COL.get(_direction, COL_DOWN)
	var frame: int = _current_row * HFRAMES + col
	for spr: Sprite2D in [_body, _eyes, _hair, _outfit, _accessories]:
		if is_instance_valid(spr) and spr.visible:
			spr.frame = frame
