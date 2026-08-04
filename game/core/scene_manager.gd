extends Node

var current_scene: Node = null
var _is_changing: bool = false


func change_scene(scene_path: String) -> void:
	if _is_changing:
		return
	_is_changing = true
	call_deferred("_do_change_scene", scene_path)


func load_start_scene() -> void:
	change_scene("res://game/world/scenes/overworld.tscn")


func _do_change_scene(scene_path: String) -> void:
	if current_scene != null and is_instance_valid(current_scene):
		current_scene.queue_free()
		await get_tree().process_frame
		current_scene = null

	# Toujours utiliser la scène root actuelle comme conteneur
	var container: Node = get_tree().current_scene
	if container == null:
		push_error("SceneManager: scène root introuvable")
		_is_changing = false
		return

	var res := load(scene_path)
	if res == null:
		push_error("SceneManager: impossible de charger " + scene_path)
		_is_changing = false
		return

	current_scene = res.instantiate()
	container.add_child(current_scene)
	_is_changing = false
