# SceneManager — gère les transitions de scène dans le nœud CurrentScene.
extends Node

const MAIN_MENU: String = "res://game/ui/menu/main_menu.tscn"

var current_scene: Node = null
var _is_changing: bool = false


func change_scene(scene_path: String) -> void:
	if _is_changing:
		return
	_is_changing = true
	call_deferred("_do_change_scene", scene_path)


func load_start_scene() -> void:
	change_scene(MAIN_MENU)


func _do_change_scene(scene_path: String) -> void:
	if current_scene != null and is_instance_valid(current_scene):
		current_scene.queue_free()
		await get_tree().process_frame
		current_scene = null

	var container: Node = get_node_or_null("/root/Main/CurrentScene")
	if container == null:
		push_error("SceneManager: /root/Main/CurrentScene introuvable")
		_is_changing = false
		return

	var res: Resource = load(scene_path)
	if res == null:
		push_error("SceneManager: impossible de charger " + scene_path)
		_is_changing = false
		return

	current_scene = res.instantiate()
	container.add_child(current_scene)
	_is_changing = false
