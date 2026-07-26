# resource_node.gd
# Area2D avec enfants :
#   Sprite2D, CollisionShape2D, Label (InteractHint), Timer (RespawnTimer)
extends Node2D

enum ResourceType { BOIS, BAIES }

@export var resource_type: int = ResourceType.BOIS
@export var amount_min: int = 1
@export var amount_max: int = 3
@export var respawn_time: float = 30.0
@export var interact_radius: float = 80.0

@onready var sprite = $Sprite2D
@onready var interact_hint = $InteractHint
@onready var respawn_timer = $RespawnTimer

var is_depleted: bool = false
var player_nearby: bool = false
var _player: Node2D = null

func _ready() -> void:
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_on_respawn)
	interact_hint.visible = false

	if resource_type == ResourceType.BOIS:
		interact_hint.text = "[E] Couper le bois"
	else:
		interact_hint.text = "[E] Cueillir des baies"

	print("[ResourceNode] Pret - type: ", resource_type)

func _process(_delta: float) -> void:
	# Trouver le joueur dynamiquement s'il n'est pas encore connu
	if _player == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]

	if _player == null:
		return

	var dist = global_position.distance_to(_player.global_position)
	var was_nearby = player_nearby
	player_nearby = dist <= interact_radius and not is_depleted

	# Afficher/cacher le hint si changement d'état
	if player_nearby != was_nearby:
		interact_hint.visible = player_nearby

	if player_nearby and Input.is_action_just_pressed("interact"):
		harvest()

func harvest() -> void:
	var amount = randi_range(amount_min, amount_max)
	if resource_type == ResourceType.BOIS:
		GameManager.add_item("bois", amount)
		_show_pickup_text("+" + str(amount) + " Bois")
		print("[ResourceNode] Recolte bois x", amount)
	else:
		GameManager.add_item("baies", amount)
		_show_pickup_text("+" + str(amount) + " Baies")
		print("[ResourceNode] Recolte baies x", amount)
	_deplete()

func _deplete() -> void:
	is_depleted = true
	player_nearby = false
	interact_hint.visible = false
	sprite.modulate.a = 0.3
	respawn_timer.start()

func _on_respawn() -> void:
	is_depleted = false
	sprite.modulate.a = 1.0
	print("[ResourceNode] Respawn !")

func _show_pickup_text(msg: String) -> void:
	var popup = Label.new()
	popup.text = msg
	popup.position = Vector2(-20.0, -60.0)
	popup.modulate = Color(1.0, 0.85, 0.0, 1.0)
	add_child(popup)
	var tw = create_tween()
	tw.tween_property(popup, "position", Vector2(-20.0, -100.0), 0.8)
	tw.parallel().tween_property(popup, "modulate:a", 0.0, 0.8)
	tw.tween_callback(popup.queue_free)
