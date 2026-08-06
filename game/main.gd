# main.gd — Point d'entrée. NE charge PAS le HUD (il est dans overworld.tscn).
# Gère uniquement le loading screen et le routing de scène initial.
extends Node

const LOADING_SCENE: PackedScene = preload("res://game/ui/loading_screen.tscn")

var _loading: CanvasLayer = null


func _ready() -> void:
	_spawn_loading()
	_show_loading()
	SceneManager.load_start_scene()


func _spawn_loading() -> void:
	if _loading == null:
		_loading = LOADING_SCENE.instantiate() as CanvasLayer
		add_child(_loading)


func _show_loading() -> void:
	if _loading != null and _loading.has_method("show_loading"):
		_loading.show_loading()


func hide_loading() -> void:
	if _loading != null and _loading.has_method("hide_loading"):
		_loading.hide_loading()
