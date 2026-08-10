# character_appearance.gd
# Gere les calques de sprites du personnage (joueur ET NPC).
#
# Ton spritesheet a 2 usages distincts sur la meme image :
#
#   col 0          | col 1       col 2        col 3
#   PORTRAIT       | PROFIL_G    DOS          PROFIL_D
#   (grand, usage  | (petit sprite in-game, 3 directions)
#    dialogues)    |
#
# => Le portrait (col 0) est charge dans un Sprite2D SEPARE (PortraitSprite)
#    Les sprites monde (col 1-3) sont affiches via _body, _hair etc.
#
# Pour les sprites monde on remplace hframes/vframes :
#   HFRAMES_WORLD  = 3  (3 colonnes : profil_g / dos / profil_d)
#   HFRAMES_PORTRAIT = 1 (1 colonne  : le portrait)
extends Node2D

# -- Calques monde (petits sprites in-game) ----------------------------------------
@onready var _body:        Sprite2D = $BodySprite
@onready var _eyes:        Sprite2D = $EyesSprite
@onready var _hair:        Sprite2D = $HairSprite
@onready var _outfit:      Sprite2D = $OutfitSprite
@onready var _accessories: Sprite2D = $AccessoriesSprite

# -- Calque portrait (dialogue) ---------------------------------------------------
# Noeud Sprite2D separe, plus grand, visible seulement pendant les dialogues
@onready var _portrait: Sprite2D = $PortraitSprite

# -- Grille monde (colonnes 1-3 de ton sheet) ------------------------------------
# Le spritesheet complet a 4 colonnes, mais pour les sprites monde
# on saute la col 0 (portrait). On utilise region_rect pour ca.
# => HFRAMES_WORLD = 3 directions : profil_g=0 / dos=1 / profil_d=2
const HFRAMES_WORLD := 3
const VFRAMES_WORLD := 1   # passe a 2+ quand tu ajoutes walk/attack

# -- Directions monde -------------------------------------------------------------
const COL_LEFT:  int = 0   # profil gauche  (col 1 du sheet original)
const COL_UP:    int = 1   # dos            (col 2 du sheet original)
const COL_RIGHT: int = 2   # profil droit   (col 3 du sheet original)
const COL_DOWN:  int = 0   # pas de face in-game -> utilise profil_g par defaut

const DIR_TO_COL: Dictionary = {
	"down":  COL_DOWN,
	"left":  COL_LEFT,
	"right": COL_RIGHT,
	"up":    COL_UP,
}

# -- Lignes (rows) ----------------------------------------------------------------
const ROW_IDLE:   int = 0
const ROW_WALK_A: int = 1
const ROW_WALK_B: int = 2
const ROW_ATTACK: int = 3
const ROW_WORK:   int = 4

# -- Chemins ----------------------------------------------------------------------
const BASE_PATH := "res://game/assets/sprites/characters/"

# -- Etat interne -----------------------------------------------------------------
var _direction:   String = "down"
var _current_row: int    = ROW_IDLE
var _gender:      String = "male"


# -- Init -------------------------------------------------------------------------
func _ready() -> void:
	_setup_world_layers()
	if is_instance_valid(_portrait):
		_portrait.visible = false


func _setup_world_layers() -> void:
	for spr: Sprite2D in [_body, _eyes, _hair, _outfit, _accessories]:
		if is_instance_valid(spr):
			spr.hframes = HFRAMES_WORLD
			spr.vframes = VFRAMES_WORLD


# -- API publique -----------------------------------------------------------------

## Charge textures + couleurs depuis GameState.player_appearance ou NPCData
func apply_appearance(appearance: Dictionary) -> void:
	if appearance.is_empty():
		return

	_gender = appearance.get("gender", "male")

	# Sprites monde  : fichiers "*_world_male.png" (3 colonnes, sans portrait)
	_load_world_layer(_body,   "body",   "body_world_%s"   % _gender)
	_load_world_layer(_eyes,   "eyes",   "eyes_world_%s"   % appearance.get("eye_style", "normal"))
	_load_world_layer(_hair,   "hair",   "hair_world_%s"   % appearance.get("hair",     "short"))
	_load_world_layer(_outfit, "outfit", "outfit_world_%s" % appearance.get("outfit",   "peasant"))

	# Portrait dialogue : fichier "body_portrait_male.png" (1 colonne, grand)
	_load_portrait_layer("body", "body_portrait_%s" % _gender)

	_tint(_body,    appearance.get("skin_color",   Color.WHITE))
	_tint(_hair,    appearance.get("hair_color",   Color.WHITE))
	_tint(_eyes,    appearance.get("eyes_color",   Color.WHITE))
	_tint(_outfit,  appearance.get("outfit_color", Color.WHITE))
	if is_instance_valid(_portrait):
		_portrait.modulate = appearance.get("skin_color", Color.WHITE)

	_refresh_frames()


## Affiche ou cache le portrait (appele par le systeme de dialogue)
func show_portrait(visible: bool) -> void:
	if is_instance_valid(_portrait):
		_portrait.visible = visible


## Retourne la texture du portrait (pour l'afficher dans la boite de dialogue)
func get_portrait_texture() -> Texture2D:
	if is_instance_valid(_portrait) and _portrait.texture != null:
		return _portrait.texture
	return null


## Direction du personnage in-game
func set_direction(dir: String) -> void:
	_direction = dir
	_refresh_frames()


## Walk frame (decommenter le corps quand tu as les lignes walk dans le sheet)
func set_walk_frame(_frame: int) -> void:
	pass
	# _current_row = ROW_WALK_A if (_frame % 2 == 0) else ROW_WALK_B
	# _refresh_frames()


func set_idle() -> void:
	_current_row = ROW_IDLE
	_refresh_frames()


func set_attack() -> void:
	if VFRAMES_WORLD > ROW_ATTACK:
		_current_row = ROW_ATTACK
		_refresh_frames()


func set_work() -> void:
	if VFRAMES_WORLD > ROW_WORK:
		_current_row = ROW_WORK
		_refresh_frames()


# -- Interne ----------------------------------------------------------------------

func _load_world_layer(spr: Sprite2D, folder: String, filename: String) -> void:
	if not is_instance_valid(spr):
		return
	var path: String = "%s%s/%s.png" % [BASE_PATH, folder, filename]
	if ResourceLoader.exists(path):
		spr.texture = load(path)
		spr.hframes = HFRAMES_WORLD
		spr.vframes = VFRAMES_WORLD
		spr.visible = true
	else:
		spr.visible = false
		push_warning("[CharacterAppearance] Sprite monde manquant : " + path)


func _load_portrait_layer(folder: String, filename: String) -> void:
	if not is_instance_valid(_portrait):
		return
	var path: String = "%s%s/%s.png" % [BASE_PATH, folder, filename]
	if ResourceLoader.exists(path):
		_portrait.texture = load(path)
		_portrait.hframes = 1
		_portrait.vframes = 1
		_portrait.frame   = 0
	else:
		push_warning("[CharacterAppearance] Portrait manquant : " + path)


func _tint(spr: Sprite2D, col: Color) -> void:
	if is_instance_valid(spr):
		spr.modulate = col


func _refresh_frames() -> void:
	var col: int   = DIR_TO_COL.get(_direction, COL_LEFT)
	var frame: int = _current_row * HFRAMES_WORLD + col
	for spr: Sprite2D in [_body, _eyes, _hair, _outfit, _accessories]:
		if is_instance_valid(spr) and spr.visible:
			spr.frame = frame
