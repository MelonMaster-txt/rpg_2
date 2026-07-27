# CharacterAppearance.gd
# Composant à attacher sur tout personnage (joueur, NPC, famille)
# Gère les layers visuels : body / outfit / head
# Usage: appearance.set_skin("light") / .set_hair("brown") / .set_outfit("peasant")
extends Node

# ─── CONSTANTES ───────────────────────────────────────────────
const BASE_PATH := "res://game/characters/shared/sprites/"

const SKINS   := ["light", "medium", "dark"]
const HAIRS   := ["black", "brown", "auburn", "blond", "red", "grey", "bald"]
const OUTFITS := ["peasant", "guard", "mage", "farmer"]

# Layout spritesheet : 16 frames (4 directions × 4 frames)
# [down×4, up×4, right×4, left×4]
const FRAME_W  := 16
const FRAME_H  := 24
const COLS     := 16

# Mapping direction → colonne de départ dans la spritesheet
const DIR_COL := {
	"down":  0,
	"up":    4,
	"right": 8,
	"left":  12,
}

# ─── NODES ENFANTS ───────────────────────────────────────────────
# Le système crée 3 Sprite2D empilés (z_index croissant)
var _layer_body:   Sprite2D
var _layer_outfit: Sprite2D
var _layer_head:   Sprite2D

# État courant
var _skin:    String = "light"
var _hair:    String = "brown"
var _outfit:  String = "peasant"
var _dir:     String = "down"
var _frame:   int    = 0

# Références aux textures chargées (cache)
var _tex_body:   Texture2D = null
var _tex_outfit: Texture2D = null
var _tex_head:   Texture2D = null

# ─── INIT ─────────────────────────────────────────────────────
func _ready() -> void:
	_build_layers()
	_reload_all_textures()
	_apply_frame()


func _build_layers() -> void:
	_layer_body   = _make_sprite(0)
	_layer_outfit = _make_sprite(1)
	_layer_head   = _make_sprite(2)


func _make_sprite(z: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.z_index          = z
	s.centered         = true
	s.hframes          = COLS
	s.vframes          = 1
	get_parent().add_child(s)
	return s


# ─── API PUBLIQUE ───────────────────────────────────────────────
func set_skin(skin: String) -> void:
	if skin not in SKINS:
		push_warning("CharacterAppearance: skin '%s' inconnu" % skin)
		return
	_skin = skin
	_reload_body()
	_reload_head()
	_apply_frame()


func set_hair(hair: String) -> void:
	if hair not in HAIRS:
		push_warning("CharacterAppearance: hair '%s' inconnu" % hair)
		return
	_hair = hair
	_reload_head()
	_apply_frame()


func set_outfit(outfit: String) -> void:
	if outfit not in OUTFITS:
		push_warning("CharacterAppearance: outfit '%s' inconnu" % outfit)
		return
	_outfit = outfit
	_reload_outfit()
	_apply_frame()


func set_direction(dir: String) -> void:
	if dir not in DIR_COL:
		return
	_dir = dir
	_apply_frame()


func set_walk_frame(frame: int) -> void:
	# frame : 0=idle, 1-3=walk
	_frame = clampi(frame, 0, 3)
	_apply_frame()


func randomize_appearance() -> void:
	set_skin(SKINS.pick_random())
	set_hair(HAIRS.pick_random())
	set_outfit(OUTFITS.pick_random())


func get_appearance_data() -> Dictionary:
	return {"skin": _skin, "hair": _hair, "outfit": _outfit}


func apply_appearance_data(data: Dictionary) -> void:
	if data.has("skin"):   set_skin(data["skin"])
	if data.has("hair"):   set_hair(data["hair"])
	if data.has("outfit"): set_outfit(data["outfit"])


# ─── INTERNE ─────────────────────────────────────────────────────
func _reload_all_textures() -> void:
	_reload_body()
	_reload_outfit()
	_reload_head()


func _reload_body() -> void:
	_tex_body = load(BASE_PATH + "body_%s.png" % _skin)
	if _layer_body:
		_layer_body.texture = _tex_body


func _reload_outfit() -> void:
	_tex_outfit = load(BASE_PATH + "outfit_%s.png" % _outfit)
	if _layer_outfit:
		_layer_outfit.texture = _tex_outfit


func _reload_head() -> void:
	_tex_head = load(BASE_PATH + "head_%s_%s.png" % [_skin, _hair])
	if _layer_head:
		_layer_head.texture = _tex_head


func _apply_frame() -> void:
	var col := DIR_COL.get(_dir, 0) + _frame
	if _layer_body:   _layer_body.frame   = col
	if _layer_outfit: _layer_outfit.frame = col
	if _layer_head:   _layer_head.frame   = col
