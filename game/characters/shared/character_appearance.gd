# character_appearance.gd
# Gere les calques de sprites du personnage (joueur ET NPC).
# A attacher sur un Node2D "CharacterAppearance" enfant de CharacterBody2D.
#
# Structure du spritesheet attendue (meme grille pour TOUS les calques) :
#
#         col0     col1     col2     col3
# ligne0  idle_bas idle_g   idle_d   idle_h      ROW_IDLE
# ligne1  walkA_b  walkA_g  walkA_d  walkA_h     ROW_WALK_A  (pied gauche)
# ligne2  walkB_b  walkB_g  walkB_d  walkB_h     ROW_WALK_B  (pied droit)
# ligne3  atk_b    atk_g    atk_d    atk_h       ROW_ATTACK
# ligne4  work_b   work_g   work_d   work_h      ROW_WORK
#
# Taille recommandee : cellule 32x32px => image 128x160px par calque
extends Node2D

# -- Calques -----------------------------------------------------------------------
@onready var _body:        Sprite2D = $BodySprite
@onready var _eyes:        Sprite2D = $EyesSprite
@onready var _hair:        Sprite2D = $HairSprite
@onready var _outfit:      Sprite2D = $OutfitSprite
@onready var _accessories: Sprite2D = $AccessoriesSprite

# -- Grille du spritesheet ---------------------------------------------------------
# ADAPTER ces valeurs a ton spritesheet !
const HFRAMES := 4   # 4 colonnes  = 4 directions (bas / gauche / droite / haut)
const VFRAMES := 5   # 5 lignes    = idle / walkA / walkB / attack / work

# Indices des lignes (rows)
const ROW_IDLE:   int = 0
const ROW_WALK_A: int = 1   # pied gauche
const ROW_WALK_B: int = 2   # pied droit
const ROW_ATTACK: int = 3
const ROW_WORK:   int = 4

# Indices des colonnes (directions)
const COL_DOWN:  int = 0
const COL_LEFT:  int = 1
const COL_RIGHT: int = 2
const COL_UP:    int = 3

const DIR_TO_COL: Dictionary = {
	"down":  COL_DOWN,
	"left":  COL_LEFT,
	"right": COL_RIGHT,
	"up":    COL_UP,
}

# -- Chemin de base des spritesheets -----------------------------------------------
const BASE_PATH := "res://game/assets/sprites/characters/"

# -- Etat interne ------------------------------------------------------------------
var _direction:   String = "down"
var _current_row: int    = ROW_IDLE
var _walk_toggle: bool   = false   # alterne walkA / walkB
var _gender:      String = "male"


# -- Init --------------------------------------------------------------------------
func _ready() -> void:
	_setup_layers()


func _setup_layers() -> void:
	for spr: Sprite2D in [_body, _eyes, _hair, _outfit, _accessories]:
		if is_instance_valid(spr):
			spr.hframes = HFRAMES
			spr.vframes = VFRAMES


# -- API publique ------------------------------------------------------------------

## Charge les textures + couleurs depuis un dictionnaire d'apparence.
## Cles attendues : gender, hair, eye_style, outfit,
##                  skin_color, hair_color, eyes_color, outfit_color
func apply_appearance(appearance: Dictionary) -> void:
	if appearance.is_empty():
		return

	_gender = appearance.get("gender", "male")

	_load_layer(_body,   "body",   "body_%s"    % _gender)
	_load_layer(_eyes,   "eyes",   "eyes_%s"    % appearance.get("eye_style", "normal"))
	_load_layer(_hair,   "hair",   "hair_%s"    % appearance.get("hair",      "short"))
	_load_layer(_outfit, "outfit", "outfit_%s"  % appearance.get("outfit",    "peasant"))
	# accessories : non implemente pour l'instant
	if is_instance_valid(_accessories):
		_accessories.visible = false

	# Teinture
	_tint(_body,   appearance.get("skin_color",   Color.WHITE))
	_tint(_hair,   appearance.get("hair_color",   Color.WHITE))
	_tint(_eyes,   appearance.get("eyes_color",   Color.WHITE))
	_tint(_outfit, appearance.get("outfit_color", Color.WHITE))

	_refresh_frames()


## Direction du personnage : "down" | "left" | "right" | "up"
## Appele par player.gd et la State Machine NPC
func set_direction(dir: String) -> void:
	_direction   = dir
	_current_row = ROW_WALK_A   # passe en mode walk, la frame A/B est geree par set_walk_frame
	_refresh_frames()


## Avance la frame de marche. Appele par player.gd a chaque pas.
## frame est un compteur libre, on prend juste son bit de parite pour alterner A/B
func set_walk_frame(frame: int) -> void:
	_walk_toggle = (frame % 2 == 0)
	_current_row = ROW_WALK_A if _walk_toggle else ROW_WALK_B
	_refresh_frames()


## Pose idle (joueur immobile, NPC en attente)
func set_idle() -> void:
	_current_row = ROW_IDLE
	_refresh_frames()


## Pose attaque
func set_attack() -> void:
	_current_row = ROW_ATTACK
	_refresh_frames()


## Pose travail
func set_work() -> void:
	_current_row = ROW_WORK
	_refresh_frames()


# -- Interne -----------------------------------------------------------------------

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
