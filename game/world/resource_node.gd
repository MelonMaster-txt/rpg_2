# ResourceNode.gd
extends Area2D

enum ResourceType { WOOD, BERRIES, STONE }

@export var resource_type: ResourceType = ResourceType.WOOD
@export var amount_min: int = 1
@export var amount_max: int = 3
@export var respawn_time: float = 30.0

@onready var sprite: Node                = $Sprite2D
@onready var interact_hint: Label        = $InteractHint
@onready var respawn_timer: Timer        = $RespawnTimer
@onready var collision: CollisionShape2D = $CollisionShape2D

var is_depleted: bool   = false
var player_nearby: bool = false


func _ready() -> void:
	# Rejoindre les groupes utilisés par le WorkerAI pour cibler les ressources
	match resource_type:
		ResourceType.WOOD:    add_to_group("tree")
		ResourceType.BERRIES: add_to_group("tree")  # farmer cible aussi le groupe tree
		ResourceType.STONE:   add_to_group("rock")
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot  = true
	respawn_timer.timeout.connect(_on_respawn)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	interact_hint.visible = false
	match resource_type:
		ResourceType.WOOD:    interact_hint.text = "[E] Chop wood"
		ResourceType.BERRIES: interact_hint.text = "[E] Pick berries"
		ResourceType.STONE:   interact_hint.text = "[E] Gather stone"


func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and not is_depleted and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		harvest()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if not is_depleted:
			interact_hint.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		interact_hint.visible = false


# Appel joueur (sans paramètre) OU appel WorkerAI (avec quantité demandée)
# Retourne la quantité effectivement récoltée
func harvest(requested: int = -1) -> int:
	if is_depleted:
		return 0
	var amount: int
	if requested > 0:
		amount = requested
	else:
		amount = randi_range(amount_min, amount_max)
	var item_key: String = ""
	var label_text: String = ""
	match resource_type:
		ResourceType.WOOD:
			item_key   = "wood"
			label_text = "+%d Wood" % amount
		ResourceType.BERRIES:
			item_key   = "berries"
			label_text = "+%d Berries" % amount
		ResourceType.STONE:
			item_key   = "stone"
			label_text = "+%d Stone" % amount
	# Dépôt direct seulement si c'est le joueur (requested == -1)
	# Le WorkerAI gère lui-même le dépôt via son inventaire
	if requested < 0 and item_key != "":
		GameManager.add_item(item_key, amount)
		_show_pickup_text(label_text)
	_deplete()
	return amount


func can_gather() -> bool:
	return not is_depleted


func _deplete() -> void:
	is_depleted = true
	interact_hint.visible = false
	if sprite is CanvasItem:
		(sprite as CanvasItem).modulate.a = 0.3
	collision.disabled = true
	respawn_timer.start()


func _on_respawn() -> void:
	is_depleted = false
	if sprite is CanvasItem:
		(sprite as CanvasItem).modulate.a = 1.0
	collision.disabled = false
	if player_nearby:
		interact_hint.visible = true


func _show_pickup_text(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = Vector2(-20, -40)
	label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(label)
	var tween: Tween = create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -30), 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)
