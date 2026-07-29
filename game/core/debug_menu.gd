# debug_menu.gd - Autoload
# Menu de debug accessible avec F3 en jeu
extends Node

var _visible: bool = false
var _label: RichTextLabel

func _ready() -> void:
	_label = RichTextLabel.new()
	_label.anchor_right = 0.3
	_label.anchor_bottom = 0.5
	_label.position = Vector2(8, 8)
	_label.size = Vector2(280, 200)
	_label.bbcode_enabled = true
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = false
	add_child(_label)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		_visible = !_visible
		_label.visible = _visible

func _process(_delta: float) -> void:
	if not _visible:
		return
	var fps = Engine.get_frames_per_second()
	var chunks = 0
	if has_node("/root/ChunkGenerator"):
		var cg = get_node("/root/ChunkGenerator")
		if cg.has_method("get_loaded_chunk_count"):
			chunks = cg.get_loaded_chunk_count()
	var npcs = 0
	if has_node("/root/NpcSpawner"):
		npcs = get_node("/root/NpcSpawner").get_active_count()
	_label.text = "[b][color=lime]DEBUG[/color][/b]\n" \
		+ "FPS: %d\n" % fps \
		+ "Chunks: %d\n" % chunks \
		+ "NPC actifs: %d\n" % npcs
