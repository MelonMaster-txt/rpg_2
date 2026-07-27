# player.gd — avec système inventaire + item en main
extends CharacterBody2D

@export var move_speed: float = 120.0
@export var zoom_in_factor: float = 1.2
@export var zoom_out_factor: float = 0.8

@onready var camera: Camera2D = $Camera2D

# Item actuellement en main (id dans ItemDatabase)
var _held_item: String = ""

signal held_item_changed(item_id: String)

# Ordre de sélection rapide avec Q/E
const QUICK_SELECT: Array = ["pioche", "arrosoir", "graine_baie"]
var _quick_index: int = -1

func _ready() -> void:
	add_to_group("player")
	if camera != null:
		camera.enabled = true

func _physics_process(_delta: float) -> void:
	var dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	velocity = dir * move_speed
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if camera == null:
		return
	if event.is_action_pressed("zoom_in"):
		camera.zoom *= zoom_in_factor
	if event.is_action_pressed("zoom_out"):
		camera.zoom *= zoom_out_factor
	if event.is_action_pressed("interact"):
		_try_gather()
	# Sélection rapide d'item avec Tab
	if event.is_action_pressed("quick_select"):
		_cycle_held_item()
	# Désélectionner avec RMB ou Echap
	if event.is_action_pressed("ui_cancel"):
		set_held_item("")

# ─── INVENTAIRE ──────────────────────────────────────────────────────────────

func get_inventory() -> Dictionary:
	return GameManager.inventory

func add_item(item_id: String, amount: int = 1) -> void:
	GameManager.add_item(item_id, amount)

func remove_item(item_id: String, amount: int = 1) -> bool:
	return GameManager.remove_item(item_id, amount)

# ─── ITEM EN MAIN ─────────────────────────────────────────────────────────────

func get_held_item() -> String:
	return _held_item

func set_held_item(item_id: String) -> void:
	_held_item = item_id
	held_item_changed.emit(item_id)

func _cycle_held_item() -> void:
	_quick_index = (_quick_index + 1) % QUICK_SELECT.size()
	var candidate = QUICK_SELECT[_quick_index]
	# Seulement si le joueur possède cet item
	if GameManager.get_item(candidate) > 0:
		set_held_item(candidate)
	else:
		set_held_item("")

# ─── CUEILLETTE ───────────────────────────────────────────────────────────────

func _try_gather() -> void:
	var nodes := get_tree().get_nodes_in_group("resource_nodes")
	var best: Node = null
	var best_dist := INF

	for node in nodes:
		if not node.has_method("gather") or not node.can_gather():
			continue
		var d := global_position.distance_to(node.global_position)
		if d < best_dist:
			best_dist = d
			best = node

	if best == null:
		return

	var result: Dictionary = best.gather()
	if result.is_empty():
		return

	var rtype: String = result.get("type", "")
	var amount: int  = result.get("amount", 1)
	var rname: String = result.get("name", rtype)

	var inv_key: String = _resource_type_to_key(rtype)
	if inv_key != "":
		GameManager.add_item(inv_key, amount)
		_show_pickup_popup("+" + str(amount) + " " + rname)

func _resource_type_to_key(rtype: String) -> String:
	match rtype:
		"wood":            return "bois"
		"berry", "baies":  return "baies"
		"stone", "pierre": return "pierre"
		_:                 return rtype

func _show_pickup_popup(msg: String) -> void:
	var popup := Label.new()
	popup.text = msg
	popup.position = global_position + Vector2(-20.0, -60.0)
	get_tree().current_scene.add_child(popup)
	var tw := create_tween()
	tw.tween_property(popup, "position", popup.position + Vector2(0.0, -40.0), 0.8)
	tw.parallel().tween_property(popup, "modulate:a", 0.0, 0.8)
	tw.tween_callback(popup.queue_free)
