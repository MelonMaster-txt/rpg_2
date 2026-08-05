# resource_node.gd
# Nœud de ressource générique. Supporte tous les types de ressources forêt.
# Respawn dans un rayon aléatoire autour de l'origine (pas au même endroit).
extends Area2D

const TYPE_COLORS := {
	"wood":     Color(0.20, 0.50, 0.15),
	"berry":    Color(0.55, 0.10, 0.60),
	"stone":    Color(0.55, 0.55, 0.55),
	"mushroom": Color(0.65, 0.35, 0.10),
	"flint":    Color(0.45, 0.45, 0.50),
	"herb":     Color(0.20, 0.70, 0.30),
	"resin":    Color(0.75, 0.55, 0.15),
	"bone":     Color(0.90, 0.88, 0.80),
}
const DEFAULT_COLOR := Color(0.6, 0.4, 0.2)
# Correspondances type -> clef inventaire
const TYPE_TO_KEY := {
	"wood": "wood",     "bois": "wood",     "tree": "wood",
	"berry": "berries", "baies": "berries", "berries": "berries",
	"stone": "stone",   "pierre": "stone",  "rock": "stone",
	"rocks": "stone",
	"mushroom": "mushroom", "champignon": "mushroom",
	"flint": "flint",   "silex": "flint",
	"herb": "herb",     "herbe": "herb",
	"resin": "resin",   "resine": "resin",
	"bone": "bone",     "os": "bone",
}

@export var resource_name: String  = "Ressource"
@export var resource_type: String  = "generic"
@export var max_health: int        = 3
@export var gather_amount: int     = 1
@export var respawn_time: float    = 12.0
@export var respawn_scatter: float = 40.0

var _visual: Node2D              = null
var _color_rect: ColorRect       = null
var _label: Label                = null
var _gather_shape: CollisionShape2D  = null
var _blocker_shape: CollisionShape2D = null
var _respawn_timer: Timer        = null

var current_health: int  = 0
var is_depleted: bool    = false
var player_in_area: bool = false
var _origin_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	current_health   = max_health
	_origin_position = position
	add_to_group("resource_nodes")

	_visual        = get_node_or_null("Visual")
	_label         = get_node_or_null("Label") as Label
	_gather_shape  = get_node_or_null("GatherShape") as CollisionShape2D
	_blocker_shape = get_node_or_null("Blocker/BlockerShape") as CollisionShape2D
	_respawn_timer = get_node_or_null("RespawnTimer") as Timer

	if _visual != null:
		var sprite := _visual as Sprite2D
		if sprite != null and sprite.texture == null:
			_build_color_rect()

	if _label != null:
		_label.text    = "[E] " + resource_name
		_label.visible = false

	if _respawn_timer != null:
		_respawn_timer.timeout.connect(_on_respawn)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func _build_color_rect() -> void:
	var color: Color = TYPE_COLORS.get(resource_type, DEFAULT_COLOR)
	_color_rect       = ColorRect.new()
	_color_rect.color = color
	var sz: Vector2
	match resource_type:
		"wood":     sz = Vector2(20, 28)
		"berry":    sz = Vector2(12, 12)
		"stone":    sz = Vector2(22, 16)
		"mushroom": sz = Vector2(10, 14)
		"flint":    sz = Vector2(14, 10)
		"herb":     sz = Vector2(10, 14)
		"resin":    sz = Vector2(10, 10)
		"bone":     sz = Vector2(18, 8)
		_:          sz = Vector2(16, 16)
	_color_rect.size     = sz
	_color_rect.position = -sz / 2.0
	if _visual != null:
		_visual.add_child(_color_rect)
	else:
		add_child(_color_rect)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_in_area and not is_depleted:
		get_viewport().set_input_as_handled()
		_do_gather()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not is_depleted:
		player_in_area = true
		if _label != null:
			_label.visible = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		if _label != null:
			_label.visible = false


func _resource_type_to_key(rtype: String) -> String:
	return TYPE_TO_KEY.get(rtype, rtype)


func _do_gather() -> void:
	current_health -= 1
	var inv_key: String = _resource_type_to_key(resource_type)
	GameManager.add_item(inv_key, gather_amount)
	_spawn_gather_feedback()
	if current_health <= 0:
		_deplete()


func _deplete() -> void:
	is_depleted    = true
	player_in_area = false
	if _label != null:
		_label.visible = false
	if _gather_shape  != null:
		_gather_shape.set_deferred("disabled", true)
	if _blocker_shape != null:
		_blocker_shape.set_deferred("disabled", true)
	if _color_rect != null:
		_color_rect.modulate.a = 0.25
	elif _visual != null and _visual is CanvasItem:
		(_visual as CanvasItem).modulate.a = 0.3
	if _respawn_timer != null:
		var variation: float = respawn_time * randf_range(0.7, 1.3)
		_respawn_timer.start(variation)
	else:
		queue_free()


func _on_respawn() -> void:
	if respawn_scatter > 0.0:
		var angle: float = randf() * TAU
		var dist: float  = randf_range(0.0, respawn_scatter)
		position = _origin_position + Vector2(cos(angle), sin(angle)) * dist

	is_depleted    = false
	current_health = max_health
	if _gather_shape  != null:
		_gather_shape.set_deferred("disabled", false)
	if _blocker_shape != null:
		_blocker_shape.set_deferred("disabled", false)
	if _color_rect != null:
		_color_rect.modulate.a = 1.0
	elif _visual != null and _visual is CanvasItem:
		(_visual as CanvasItem).modulate.a = 1.0


func _spawn_gather_feedback() -> void:
	var lbl := Label.new()
	lbl.text     = "+%d %s" % [gather_amount, resource_name]
	lbl.position = Vector2(-20, -50)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -30), 0.8)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw.tween_callback(lbl.queue_free)
