extends Node

var current_scene: Node = null
var _hud: Node = null

func _ready() -> void:
	_setup_hud()

func _setup_hud() -> void:
	if _hud == null:
		var hud_scene = load("res://game/ui/hud.tscn")
		if hud_scene:
			_hud = hud_scene.instantiate()
			get_tree().root.add_child(_hud)

func change_scene(scene_path: String) -> void:
	call_deferred("_do_change_scene", scene_path)

func _do_change_scene(scene_path: String) -> void:
	if current_scene != null:
		current_scene.queue_free()
	
	var scene_resource := load(scene_path)
	current_scene = scene_resource.instantiate()
	get_tree().root.get_node("Main/CurrentScene").add_child(current_scene)

	# S'assurer que le HUD est toujours present
	if _hud == null or not is_instance_valid(_hud):
		_setup_hud()

func load_start_scene() -> void:
	change_scene("res://game/world/scenes/overworld.tscn")

func get_hud() -> Node:
	return _hud
