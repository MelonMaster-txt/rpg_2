# prison_building.gd
# Batiment de type Prison pour loger les esclaves (cellules).
extends Node2D

@export var initial_level: int = 1

var _building_id: String = ""

@onready var label: Label   = $Label if has_node("Label") else null
@onready var area:  Area2D  = $InteractArea if has_node("InteractArea") else null


func _ready() -> void:
	add_to_group("building")
	add_to_group("prison")
	var hm: Node = Engine.get_singleton("HousingManager")
	if hm != null:
		_building_id = hm.register_building(hm.BuildingType.PRISON, initial_level)
		hm.housing_changed.connect(_refresh_label)
	_refresh_label()
	if area != null:
		if not area.body_entered.is_connected(_on_body_entered):
			area.body_entered.connect(_on_body_entered)


func _exit_tree() -> void:
	var hm: Node = Engine.get_singleton("HousingManager")
	if hm != null and _building_id != "":
		hm.unregister_building(_building_id)


func get_building_id() -> String:
	return _building_id


func _refresh_label() -> void:
	if label == null or _building_id == "":
		return
	var hm: Node = Engine.get_singleton("HousingManager")
	if hm == null:
		return
	var b: Dictionary = hm._find(_building_id)
	if b.is_empty():
		return
	var used: int = 0
	for slot: Dictionary in b["slots"]:
		if slot["occupant"] != "":
			used += 1
	label.text = "%s\n%d/%d" % [hm.get_building_name(b), used, b["slots"].size()]


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_open_housing_ui()


func _open_housing_ui() -> void:
	var ui_scene: PackedScene = load("res://game/ui/housing_ui.tscn") as PackedScene
	if ui_scene == null:
		_open_housing_ui_code()
		return
	var ui: Node = ui_scene.instantiate()
	get_tree().current_scene.add_child(ui)
	if ui.has_method("open"):
		ui.open(_building_id)


func _open_housing_ui_code() -> void:
	var existing: Node = get_tree().current_scene.get_node_or_null("HousingUILayer")
	if existing != null:
		existing.queue_free()
	var layer := CanvasLayer.new()
	layer.name = "HousingUILayer"
	layer.layer = 60
	get_tree().current_scene.add_child(layer)
	var ui_script: Script = load("res://game/ui/housing_ui_inline.gd") as Script
	if ui_script == null:
		push_error("prison_building: housing_ui_inline.gd introuvable")
		return
	var ui: Node = Node.new()
	ui.set_script(ui_script)
	layer.add_child(ui)
	if ui.has_method("open"):
		ui.open(_building_id)
