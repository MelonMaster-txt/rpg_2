# character_appearance.gd
# Gere les calques de sprites du personnage (joueur ET NPC).
# A attacher sur un Node2D nomme "CharacterAppearance" enfant de CharacterBody2D.
#
# Arborescence attendue dans la scene :
# CharacterAppearance (Node2D) <- ce script
#   BodySprite       (Sprite2D)   z_index 0
#   EyesSprite       (Sprite2D)   z_index 1
#   HairSprite       (Sprite2D)   z_index 2
#   OutfitSprite     (Sprite2D)   z_index 3
#   AccessoriesSprite(Sprite2D)   z_index 4
#
# Convention spritesheet par calque : 4 colonnes (bas/gauche/droite/haut) x N lignes
# Chaque ligne = une animation (idle=0, walk=1, attack=2, work=3)
# Exemple pour walk 8 frames : Hframes=8, Vframes=4 (4 directions * 2 frames)
# Mais pour commencer, on fait simple : Hframes=4 (1 frame/direction), Vframes=4
extends Node2D

# ── Calques ────────────────────────────────────────────────────────────────────
@onready var _body:        Sprite2D = $BodySprite
@onready var _eyes:        Sprite2D = $EyesSprite
@onready var _hair:        Sprite2D = $HairSprite
@onready var _outfit:      Sprite2D = $OutfitSprite
@onready var _accessories: Sprite2D = $AccessoriesSprite

# ── Chemins des spritesheets ───────────────────────────────────────────────────
# Format : "res://game/assets/sprites/characters/{calque}/{valeur}_{genre}.png"
const BASE_PATH := "res://game/assets/sprites/characters/"

# Grille du spritesheet (a adapter selon tes fichiers)
# 4 colonnes = 4 directions : bas / gauche / droite / haut
# 2 lignes   = idle (0) / walk (1)
const HFRAMES := 4
const VFRAMES := 2

# ── Etat courant ───────────────────────────────────────────────────────────────
var _direction: String = "down"   # down / left / right / up
var _anim_row:  int    = 0        # 0=idle  1=walk  2=attack  3=work
var _walk_frame: int   = 0        # colonne dans la ligne walk (0..HFRAMES-1)
var _gender: String    = "male"

# Mapping direction -> colonne du spritesheet
const DIR_COL: Dictionary = {
	"down":  0,
	"left":  1,
	"right": 2,
	"up":    3,
}


# ── Initialisation ─────────────────────────────────────────────────────────────
func _ready() -> void:
	_setup_layers()


# Configure Hframes/Vframes sur chaque calque
func _setup_layers() -> void:
	for spr: Sprite2D in [_body, _eyes, _hair, _outfit, _accessories]:
		if is_instance_valid(spr):
			spr.hframes = HFRAMES
			spr.vframes = VFRAMES


# ── API publique ───────────────────────────────────────────────────────────────

## Charge l'apparence depuis un dictionnaire (GameState.player_appearance ou NPCData)
## appearance = { "gender", "hair", "eye_style", "outfit",
##                "skin_color", "hair_color", "eyes_color", "outfit_color" }
func apply_appearance(appearance: Dictionary) -> void:
	if appearance.is_empty():
		return

	_gender = appearance.get("gender", "male")

	_load_layer(_body,   "body",   "body_%s" % _gender)
	_load_layer(_eyes,   "eyes",   "eyes_%s" % appearance.get("eye_style", "normal"))
	_load_layer(_hair,   "hair",   "hair_%s" % appearance.get("hair",     "short"))
	_load_layer(_outfit, "outfit", "outfit_%s" % appearance.get("outfit",  "peasant"))

	# Teinture des calques
	if is_instance_valid(_body):
		_body.modulate   = appearance.get("skin_color",   Color.WHITE)
	if is_instance_valid(_hair):
		_hair.modulate   = appearance.get("hair_color",   Color.WHITE)
	if is_instance_valid(_eyes):
		_eyes.modulate   = appearance.get("eyes_color",   Color.WHITE)
	if is_instance_valid(_outfit):
		_outfit.modulate = appearance.get("outfit_color", Color.WHITE)


## Change la direction du personnage (appele par player.gd ou npc state machine)
func set_direction(dir: String) -> void:
	_direction = dir
	_anim_row  = 1  # walk
	_refresh_frames()


## Avance d'une frame de marche (appele par player.gd)
func set_walk_frame(frame: int) -> void:
	_walk_frame = frame % HFRAMES
	_refresh_frames()


## Repasse en idle (personnage immobile)
func set_idle() -> void:
	_anim_row   = 0
	_walk_frame = 0
	_refresh_frames()


## Joue l'animation attack
func set_attack() -> void:
	_anim_row   = 2
	_walk_frame = 0
	_refresh_frames()


## Joue l'animation work
func set_work() -> void:
	_anim_row   = 3
	_walk_frame = 0
	_refresh_frames()


# ── Interne ────────────────────────────────────────────────────────────────────

# Charge la texture d'un calque depuis les assets
# Si le fichier n'existe pas, cache simplement le calque
func _load_layer(spr: Sprite2D, folder: String, filename: String) -> void:
	if not is_instance_valid(spr):
		return
	var path: String = "%s%s/%s.png" % [BASE_PATH, folder, filename]
	if ResourceLoader.exists(path):
		spr.texture = load(path)
		spr.visible = true
		spr.hframes = HFRAMES
		spr.vframes = VFRAMES
	else:
		spr.visible = false


# Met a jour la frame affichee sur tous les calques selon direction + anim
func _refresh_frames() -> void:
	var col: int = DIR_COL.get(_direction, 0)
	# Pour walk, on oscille sur la colonne avec _walk_frame
	# Pour idle/attack/work, on reste sur la colonne de direction
	var actual_col: int = col
	if _anim_row == 1:  # walk : frame animate
		var half: int = HFRAMES / 4  # nb de frames walk par direction
		if half < 1:
			half = 1
		actual_col = (col * half + _walk_frame % half)

	var frame_index: int = _anim_row * HFRAMES + actual_col

	for spr: Sprite2D in [_body, _eyes, _hair, _outfit, _accessories]:
		if is_instance_valid(spr) and spr.visible:
			spr.frame = frame_index
