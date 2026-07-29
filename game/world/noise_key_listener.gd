# noise_key_listener.gd
# Script separe pour capter F2 (inner class non supportee en Godot 4 sur Node2D)
extends Node

var debug_layer: CanvasLayer

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey): return
	var ke := event as InputEventKey
	if ke.pressed and not ke.is_echo() and ke.keycode == KEY_F2:
		if debug_layer != null:
			debug_layer.visible = not debug_layer.visible
			get_viewport().set_input_as_handled()
