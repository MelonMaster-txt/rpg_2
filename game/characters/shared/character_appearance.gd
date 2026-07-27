# character_appearance.gd
# ──────────────────────────────────────────────────────────────────────
# Système de layers visuels pour tout personnage (joueur, NPC, famille)
#
# LAYERS (ordre d'empilement, z_index croissant) :
#   0 - hair_back   (cheveux derrière — sous la tête)
#   1 - body        (corps nu masculin ou féminin)
#   2 - outfit      (tenue — épouse le corps)
#   3 - head        (tête / visage)
#   4 - eyes        (yeux — colorables séparément)
#   5 - hair_front  (bangs / dessus de tête — au-dessus du visage)
#
# COLORATION RGB :
#   Toutes les spritesheets sont dessinées en niveaux de gris (blanc = couleur max)
#   → set_skin_color(Color)  / set_hair_color(Color) / set_outfit_color(Color)
#   → set_eyes_color(Color)
#   Godot applique la teinte via Sprite2D.modulate
#
# FORMAT SPRITESHEET (LPC-compatible) :
#   576 × 256 px  — 9 cols × 4 rows
#   Rows : down(0) / left(1) / right(2) / up(3)
#   Cols : idle(0) / walk1..walk8(1-8)
# ──────────────────────────────────────────────────────────────────────
extends Node

const BASE := "res://game/characters/shared/sprites/"

# ── Constantes spritesheet ─────────────────────────────────────
const HFRAMES := 9
const VFRAMES := 4

# Mapping direction → row
const DIR_ROW := {
	"down":  0,
	"left":  1,
	"right": 2,
	"up":    3,
}

# ── Options disponibles ──────────────────────────────────────
const GENDERS    := ["male", "female"]
const OUTFITS    := ["peasant", "guard", "mage", "farmer"]
const HAIRS      := ["short", "medium", "long", "bald"]
const EYE_STYLES := ["normal", "closed", "angry", "sad"]

# ── State ──────────────────────────────────────────────────────────────
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

# ── Nodes Sprite2D ──────────────────────────────────────────────
var _s_hair_back:  Sprite2D
var _s_body:       Sprite2D
var _s_outfit:     Sprite2D
var _s_head:       Sprite2D
var _s_eyes:       Sprite2D
var _s_hair_front: Sprite2D

var _layers_ready: bool = false


# ════════════════════════════════════════════════════════════════════
#  INIT
# ════════════════════════════════════════════════════════════════════
func _ready() -> void:
	# On diffère la construction des layers au prochain frame
	# pour éviter "Parent node is busy setting up children"
	call_deferred("_build_layers_deferred")


func _build_layers_deferred() -> void:
	_s_hair_back  = _make_sprite(0)
	_s_body       = _make_sprite(1)
	_s_outfit     = _make_sprite(2)
	_s_head       = _make_sprite(3)
	_s_eyes       = _make_sprite(4)
	_s_hair_front = _make_sprite(5)
	_layers_ready = true
	_refresh_all_textures()
	_apply_frame()


func _make_sprite(z: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.z_index        = z
	s.centered       = true
	s.hframes        = HFRAMES
	s.vframes        = VFRAMES
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	get_parent().add_child(s)
	return s


# ════════════════════════════════════════════════════════════════════
#  API PUBLIQUE — APPARENCE
# ════════════════════════════════════════════════════════════════════

func set_gender(g: String) -> void:
	if g not in GENDERS: return
	_gender = g
	if not _layers_ready: return
	_reload_body()
	_reload_head()
	_apply_frame()


func set_outfit(o: String) -> void:
	if o not in OUTFITS: return
	_outfit = o
	if not _layers_ready: return
	_reload_outfit()
	_apply_frame()


func set_hair(h: String) -> void:
	if h not in HAIRS: return
	_hair = h
	if not _layers_ready: return
	_reload_hair()
	_apply_frame()


func set_eye_style(s: String) -> void:
	if s not in EYE_STYLES: return
	_eye_style = s
	if not _layers_ready: return
	_reload_eyes()
	_apply_frame()


# ════════════════════════════════════════════════════════════════════
#  API PUBLIQUE — COULEURS RGB
# ════════════════════════════════════════════════════════════════════

func set_skin_color(c: Color) -> void:
	_color_skin = c
	if not _layers_ready: return
	_s_body.modulate = c
	_s_head.modulate = c


func set_hair_color(c: Color) -> void:
	_color_hair = c
	if not _layers_ready: return
	_s_hair_back.modulate  = c
	_s_hair_front.modulate = c


func set_eyes_color(c: Color) -> void:
	_color_eyes = c
	if not _layers_ready: return
	_s_eyes.modulate = c


func set_outfit_color(c: Color) -> void:
	_color_outfit = c
	if not _layers_ready: return
	_s_outfit.modulate = c


# ════════════════════════════════════════════════════════════════════
#  API PUBLIQUE — ANIMATION
# ════════════════════════════════════════════════════════════════════

func set_direction(dir: String) -> void:
	if dir not in DIR_ROW: return
	_direction = dir
	if _layers_ready:
		_apply_frame()


func set_walk_frame(f: int) -> void:
	_frame = clampi(f, 0, HFRAMES - 1)
	if _layers_ready:
		_apply_frame()


# ════════════════════════════════════════════════════════════════════
#  API PUBLIQUE — RANDOM / DATA
# ════════════════════════════════════════════════════════════════════

func randomize_appearance() -> void:
	set_gender(GENDERS.pick_random())
	set_hair(HAIRS.pick_random())
	set_outfit(OUTFITS.pick_random())
	set_eye_style(EYE_STYLES.pick_random())
	set_skin_color(Color(randf_range(0.5,1.0), randf_range(0.35,0.8), randf_range(0.2,0.6)))
	set_hair_color(Color(randf_range(0.1,0.9), randf_range(0.05,0.6), randf_range(0.0,0.3)))
	set_eyes_color(Color(randf_range(0.1,1.0), randf_range(0.2,1.0), randf_range(0.2,1.0)))
	set_outfit_color(Color(randf_range(0.2,0.9), randf_range(0.2,0.9), randf_range(0.2,0.9)))


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


# ════════════════════════════════════════════════════════════════════
#  INTERNE — Chargement textures
# ════════════════════════════════════════════════════════════════════

func _refresh_all_textures() -> void:
	_reload_body()
	_reload_outfit()
	_reload_head()
	_reload_eyes()
	_reload_hair()
	set_skin_color(_color_skin)
	set_hair_color(_color_hair)
	set_eyes_color(_color_eyes)
	set_outfit_color(_color_outfit)


func _reload_body() -> void:
	var tex := _load("body_%s.png" % _gender)
	if _s_body: _s_body.texture = tex


func _reload_head() -> void:
	var tex := _load("head_%s.png" % _gender)
	if _s_head: _s_head.texture = tex


func _reload_eyes() -> void:
	var tex := _load("eyes_%s.png" % _eye_style)
	if _s_eyes: _s_eyes.texture = tex


func _reload_hair() -> void:
	var tb := _load("hair_back_%s.png"  % _hair)
	var tf := _load("hair_front_%s.png" % _hair)
	if _s_hair_back:  _s_hair_back.texture  = tb
	if _s_hair_front: _s_hair_front.texture = tf


func _reload_outfit() -> void:
	var tex := _load("outfit_%s.png" % _outfit)
	if _s_outfit: _s_outfit.texture = tex


func _load(filename: String) -> Texture2D:
	var path := BASE + filename
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("CharacterAppearance: texture manquante → " + path)
	return null


# ════════════════════════════════════════════════════════════════════
#  INTERNE — Frame courante
# ════════════════════════════════════════════════════════════════════

func _apply_frame() -> void:
	var row:  int = DIR_ROW.get(_direction, 0)
	var col:  int = _frame
	var fidx: int = row * HFRAMES + col
	for spr in [_s_hair_back, _s_body, _s_outfit, _s_head, _s_eyes, _s_hair_front]:
		if spr and spr.texture:
			spr.frame = fidx
