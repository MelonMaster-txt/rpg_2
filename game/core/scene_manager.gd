extends Node

var current_scene: Node = null

func change_scene(scene_path: String) -> void:
	if current_scene != null:
		current_scene.queue_free()
	
	var scene_resource := load(scene_path)
	current_scene = scene_resource.instantiate()
	get_tree().root.get_node("Main/CurrentScene").add_child(current_scene)

func load_start_scene() -> void:
	change_scene("res://game/world/scenes/overworld.tscn")
