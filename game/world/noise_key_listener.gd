# noise_key_listener.gd - Capte F2 et toggle le CanvasLayer root du panel noise
extends Node

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey): return
	var ke := event as InputEventKey
	if not (ke.pressed and not ke.is_echo()): return
	if ke.keycode == KEY_F2:
		var root = get_tree().get_first_node_in_group("noise_debug_root")
		if root != null:
			root.visible = not root.visible
			get_viewport().set_input_as_handled()
