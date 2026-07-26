# ResourceNode.gd — À attacher sur chaque nœud de ressource (Bois, Baies)
# Structure de la scène :
#   ResourceNode (Area2D) <── ce script
#     ├── CollisionShape2D
#     ├── Sprite2D              (visuellement la ressource)
#     ├── Label (interact_hint)  ("[E] Couper" / "[E] Cueillir")
#     └── Timer (respawn_timer)

extends Area2D

enum ResourceType { BOIS, BAIES }

@export var resource_type: ResourceType = ResourceType.BOIS
@export var amount_min: int = 1
@export var amount_max: int = 3
@export var respawn_time: float = 30.0  # secondes avant réapparition
@export var harvest_label_text: String = "[E] Couper"

@onready var sprite: Sprite2D = $Sprite2D
@onready var interact_hint: Label = $InteractHint
@onready var respawn_timer: Timer = $RespawnTimer
@onready var collision: CollisionShape2D = $CollisionShape2D

var is_depleted: bool = false
var player_nearby: bool = false

func _ready() -> void:
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_on_respawn)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	interact_hint.visible = false

	match resource_type:
		ResourceType.BOIS:
			harvest_label_text = "[E] Couper le bois"
		ResourceType.BAIES:
			harvest_label_text = "[E] Cueillir des baies"
	interact_hint.text = harvest_label_text

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact") and not is_depleted:
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

func harvest() -> void:
	var amount: int = randi_range(amount_min, amount_max)
	match resource_type:
		ResourceType.BOIS:
			GameManager.add_item("bois", amount)
			_show_pickup_text("+%d Bois" % amount)
		ResourceType.BAIES:
			GameManager.add_item("baies", amount)
			_show_pickup_text("+%d Baies" % amount)
	_deplete()

func _deplete() -> void:
	is_depleted = true
	interact_hint.visible = false
	sprite.modulate.a = 0.3
	collision.disabled = true
	respawn_timer.start()

func _on_respawn() -> void:
	is_depleted = false
	sprite.modulate.a = 1.0
	collision.disabled = false
	if player_nearby:
		interact_hint.visible = true

func _show_pickup_text(text: String) -> void:
	# Crée un petit label flottant temporaire
	var label := Label.new()
	label.text = text
	label.position = Vector2(-20, -40)
	label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -30), 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)
