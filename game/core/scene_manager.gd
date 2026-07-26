extends Node

var current_scene: Node = null


func change_scene(scene_path: String) -> void:
	call_deferred("_do_change_scene", scene_path)


func load_start_scene() -> void:
	change_scene("res://game/world/scenes/overworld.tscn")


func _do_change_scene(scene_path: String) -> void:
	if current_scene != null and is_instance_valid(current_scene):
		current_scene.queue_free()
		current_scene = null

	var container: Node = get_tree().root.get_node_or_null("Main/CurrentScene")
	if container == null:
		push_error("SceneManager: noeud 'Main/CurrentScene' introuvable")
		return

	var res := load(scene_path)
	if res == null:
		push_error("SceneManager: impossible de charger " + scene_path)
		return

	current_scene = res.instantiate()
	container.add_child(current_scene)
