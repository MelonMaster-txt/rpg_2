# character_appearance.gd
# Rendu procédural LPC-style — pas de sprites PNG requis.
# Chaque layer est un Node2D avec des draw calls (corps, tête, yeux, cheveux, tenue)
# Les couleurs sont fully customisables via l'API publique.
extends Node

const HFRAMES := 9
const VFRAMES := 4

const DIR_ROW := { "down": 0, "left": 1, "right": 2, "up": 3 }

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

var _draw_node: Node2D = null
var _layers_ready: bool = false
var _pending_data: Dictionary = {}

# Offset de marche pour animation
var _walk_offset: float = 0.0


func _ready() -> void:
	call_deferred("_build_layers_deferred")


func _build_layers_deferred() -> void:
	_draw_node = Node2D.new()
	_draw_node.set_script(preload("res://game/characters/shared/char_draw.gd"))
	get_parent().add_child(_draw_node)
	_draw_node._appearance = self
	_layers_ready = true
	if not _pending_data.is_empty():
		apply_appearance_data(_pending_data)
		_pending_data = {}
	_draw_node.queue_redraw()


# ════ API APPARENCE ════════════════════════════════════════════════

func set_gender(g: String) -> void:
	if g not in GENDERS: return
	_gender = g
	_redraw()

func set_outfit(o: String) -> void:
	if o not in OUTFITS: return
	_outfit = o
	_redraw()

func set_hair(h: String) -> void:
	if h not in HAIRS: return
	_hair = h
	_redraw()

func set_eye_style(s: String) -> void:
	if s not in EYE_STYLES: return
	_eye_style = s
	_redraw()


# ════ API COULEURS ══════════════════════════════════════════════════

func set_skin_color(c: Color) -> void:
	_color_skin = c
	_redraw()

func set_hair_color(c: Color) -> void:
	_color_hair = c
	_redraw()

func set_eyes_color(c: Color) -> void:
	_color_eyes = c
	_redraw()

func set_outfit_color(c: Color) -> void:
	_color_outfit = c
	_redraw()


# ════ API ANIMATION ══════════════════════════════════════════════════

func set_direction(dir: String) -> void:
	if dir not in DIR_ROW: return
	_direction = dir
	_redraw()

func set_walk_frame(f: int) -> void:
	_frame = clampi(f, 0, HFRAMES - 1)
	_walk_offset = sin(_frame * PI / 2.0) * 2.0
	_redraw()


# ════ API DATA ══════════════════════════════════════════════════════

func randomize_appearance() -> void:
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
		_gender = data["gender"]; _hair = data["hair"]
		_outfit = data["outfit"]; _eye_style = data["eye_style"]
		_color_skin = data["skin_color"]; _color_hair = data["hair_color"]
		_color_eyes = data["eyes_color"]; _color_outfit = data["outfit_color"]
		return
	apply_appearance_data(data)


func get_appearance_data() -> Dictionary:
	return {
		"gender": _gender, "outfit": _outfit, "hair": _hair,
		"eye_style": _eye_style, "skin_color": _color_skin,
		"hair_color": _color_hair, "eyes_color": _color_eyes,
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


# ════ INTERNE ═══════════════════════════════════════════════════════

func _redraw() -> void:
	if _layers_ready and _draw_node:
		_draw_node.queue_redraw()
