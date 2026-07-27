# character_appearance.gd
# Système de layers visuels pour tout personnage (joueur, NPC, famille)
#
# LAYERS (ordre d'empilement, z_index croissant) :
#   0 - hair_back   (cheveux derrière)
#   1 - body        (corps)
#   2 - outfit      (tenue)
#   3 - head        (tête / visage)
#   4 - eyes        (yeux)
#   5 - hair_front  (cheveux devant)
#
# ⚠ Si les sprites PNG sont absents du dossier res://game/characters/shared/sprites/
#   les layers s'affichent en rectangles de couleur unie (fallback visuel).
#   Ajoutez vos spritesheets LPC dans ce dossier pour activer le vrai rendu.
extends Node

const BASE    := "res://game/characters/shared/sprites/"
const HFRAMES := 9
const VFRAMES := 4

const DIR_ROW := {
	"down":  0,
	"left":  1,
	"right": 2,
	"up":    3,
}

const GENDERS    := ["male", "female"]
const OUTFITS    := ["peasant", "guard", "mage", "farmer"]
const HAIRS      := ["short", "medium", "long", "bald"]
const EYE_STYLES := ["normal", "closed", "angry", "sad"]

var _gender:    String = "male"
var _outfit:    String = "peasant"
var _hair:      String = "medium"
var _eye_style: String = "normal"

var _direction: String = "down"
var _frame:     int    = 0

var _color_skin:   Color = Color(0.85, 0.70, 0.55)
var _color_hair:   Color = Color(0.40, 0.25, 0.10)
var _color_eyes:   Color = Color(0.20, 0.50, 0.80)
var _color_outfit: Color = Color(0.65, 0.45, 0.25)

var _s_hair_back:  ColorRect
var _s_body:       ColorRect
var _s_outfit:     ColorRect
var _s_head:       ColorRect
var _s_eyes:       ColorRect
var _s_hair_front: ColorRect

var _layers_ready: bool = false

# Données en attente si randomize_full/apply appelé avant _ready
var _pending_data: Dictionary = {}


func _ready() -> void:
	call_deferred("_build_layers_deferred")


func _build_layers_deferred() -> void:
	_s_hair_back  = _make_rect(0, Color(0.3, 0.2, 0.1))
	_s_body       = _make_rect(1, _color_skin)
	_s_outfit     = _make_rect(2, _color_outfit)
	_s_head       = _make_rect(3, _color_skin)
	_s_eyes       = _make_rect(4, _color_eyes)
	_s_hair_front = _make_rect(5, _color_hair)
	_layers_ready = true
	# Appliquer les données en attente
	if not _pending_data.is_empty():
		apply_appearance_data(_pending_data)
		_pending_data = {}
	else:
		_refresh_colors()


func _make_rect(z: int, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.z_index = z
	r.size    = Vector2(32, 32)
	r.position = Vector2(-16, -16)
	r.color   = color
	get_parent().add_child(r)
	return r


# ════════════════════════════════════════════════════
#  API PUBLIQUE — APPARENCE
# ════════════════════════════════════════════════════

func set_gender(g: String) -> void:
	if g not in GENDERS: return
	_gender = g
	if _layers_ready: _refresh_colors()

func set_outfit(o: String) -> void:
	if o not in OUTFITS: return
	_outfit = o
	if _layers_ready: _refresh_colors()

func set_hair(h: String) -> void:
	if h not in HAIRS: return
	_hair = h
	if _layers_ready: _refresh_colors()

func set_eye_style(s: String) -> void:
	if s not in EYE_STYLES: return
	_eye_style = s
	if _layers_ready: _refresh_colors()


# ════════════════════════════════════════════════════
#  API PUBLIQUE — COULEURS RGB
# ════════════════════════════════════════════════════

func set_skin_color(c: Color) -> void:
	_color_skin = c
	if not _layers_ready: return
	if _s_body: _s_body.color = c
	if _s_head: _s_head.color = c

func set_hair_color(c: Color) -> void:
	_color_hair = c
	if not _layers_ready: return
	if _s_hair_back:  _s_hair_back.color  = c
	if _s_hair_front: _s_hair_front.color = c

func set_eyes_color(c: Color) -> void:
	_color_eyes = c
	if not _layers_ready: return
	if _s_eyes: _s_eyes.color = c

func set_outfit_color(c: Color) -> void:
	_color_outfit = c
	if not _layers_ready: return
	if _s_outfit: _s_outfit.color = c


# ════════════════════════════════════════════════════
#  API PUBLIQUE — ANIMATION
# ════════════════════════════════════════════════════

func set_direction(dir: String) -> void:
	if dir not in DIR_ROW: return
	_direction = dir

# Animation frame (no-op en mode ColorRect, prêt pour Sprite2D)
func set_walk_frame(_f: int) -> void:
	pass


# ════════════════════════════════════════════════════
#  API PUBLIQUE — RANDOM / DATA
# ════════════════════════════════════════════════════

func randomize_appearance() -> void:
	# Si pas encore prêt, on stocke et on applique dans _build_layers_deferred
	var data := {
		"gender":       GENDERS.pick_random(),
		"hair":         HAIRS.pick_random(),
		"outfit":       OUTFITS.pick_random(),
		"eye_style":    EYE_STYLES.pick_random(),
		"skin_color":   Color(randf_range(0.5,1.0), randf_range(0.35,0.8), randf_range(0.2,0.6)),
		"hair_color":   Color(randf_range(0.1,0.9), randf_range(0.05,0.6), randf_range(0.0,0.3)),
		"eyes_color":   Color(randf_range(0.1,1.0), randf_range(0.2,1.0), randf_range(0.2,1.0)),
		"outfit_color": Color(randf_range(0.2,0.9), randf_range(0.2,0.9), randf_range(0.2,0.9)),
	}
	if not _layers_ready:
		_pending_data = data
		# Stocker aussi dans les vars d'état pour get_appearance_data()
		_gender    = data["gender"]
		_hair      = data["hair"]
		_outfit    = data["outfit"]
		_eye_style = data["eye_style"]
		_color_skin   = data["skin_color"]
		_color_hair   = data["hair_color"]
		_color_eyes   = data["eyes_color"]
		_color_outfit = data["outfit_color"]
		return
	apply_appearance_data(data)


func get_appearance_data() -> Dictionary:
	return {
		"gender":       _gender,
		"outfit":       _outfit,
		"hair":         _hair,
		"eye_style":    _eye_style,
		"skin_color":   _color_skin,
		"hair_color":   _color_hair,
		"eyes_color":   _color_eyes,
		"outfit_color": _color_outfit,
	}


func apply_appearance_data(data: Dictionary) -> void:
	if data.has("gender"):       set_gender(data["gender"])
	if data.has("outfit"):       set_outfit(data["outfit"])
	if data.has("hair"):         set_hair(data["hair"])
	if data.has("eye_style"):    set_eye_style(data["eye_style"])
	if data.has("skin_color"):   set_skin_color(data["skin_color"])
	if data.has("hair_color"):   set_hair_color(data["hair_color"])
	if data.has("eyes_color"):   set_eyes_color(data["eyes_color"])
	if data.has("outfit_color"): set_outfit_color(data["outfit_color"])


# ════════════════════════════════════════════════════
#  INTERNE
# ════════════════════════════════════════════════════

func _refresh_colors() -> void:
	set_skin_color(_color_skin)
	set_hair_color(_color_hair)
	set_eyes_color(_color_eyes)
	set_outfit_color(_color_outfit)
