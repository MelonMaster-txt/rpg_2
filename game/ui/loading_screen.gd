extends CanvasLayer

var _chunks_ready: bool = false

func show_loading() -> void:
	visible = true
	_chunks_ready = false

func hide_loading() -> void:
	visible = false

func _on_chunks_ready() -> void:
	_chunks_ready = true
	hide_loading()
