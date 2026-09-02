# npc_interaction_menu.gd
# Menu d'interaction NPC : DISCUTER / RECRUTER / CAPTURER
# Instancié dynamiquement par random_npc._open_interaction_menu()
extends CanvasLayer

@onready var _panel: PanelContainer = $Panel
@onready var _name_label: Label = $Panel/VBox/NameLabel
@onready var _btn_discuss: Button = $Panel/VBox/BtnDiscuss
@onready var _btn_recruit: Button = $Panel/VBox/BtnRecruit
@onready var _btn_capture: Button = $Panel/VBox/BtnCapture
@onready var _btn_leave: Button = $Panel/VBox/BtnLeave

var _npc: Node = null
var _signals_connected: bool = false


func open(npc: Node) -> void:
	_npc = npc
	if _name_label:
		var display_name: String = npc.get("npc_name") if npc.get("npc_name") != null else "Inconnu"
		_name_label.text = display_name
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	# FIX : connexion des signaux une seule fois pour éviter les doublons
	if not _signals_connected:
		_btn_discuss.pressed.connect(_on_discuss)
		_btn_recruit.pressed.connect(_on_recruit)
		_btn_capture.pressed.connect(_on_capture)
		_btn_leave.pressed.connect(_on_leave)
		_signals_connected = true


func _on_discuss() -> void:
	_close()
	if _npc != null and is_instance_valid(_npc):
		var display_name: String = _npc.get("npc_name") if _npc.get("npc_name") != null else "???"
		push_warning("[Interaction] Discussion avec %s" % display_name)


func _on_recruit() -> void:
	_close()
	if _npc != null and is_instance_valid(_npc) and _npc.has_method("recruit"):
		_npc.recruit()


func _on_capture() -> void:
	_close()
	if _npc != null and is_instance_valid(_npc) and _npc.has_method("capture"):
		_npc.capture()


func _on_leave() -> void:
	_close()


func _close() -> void:
	# FIX : déconnecter proprement avant queue_free
	if _signals_connected:
		if _btn_discuss.pressed.is_connected(_on_discuss):
			_btn_discuss.pressed.disconnect(_on_discuss)
		if _btn_recruit.pressed.is_connected(_on_recruit):
			_btn_recruit.pressed.disconnect(_on_recruit)
		if _btn_capture.pressed.is_connected(_on_capture):
			_btn_capture.pressed.disconnect(_on_capture)
		if _btn_leave.pressed.is_connected(_on_leave):
			_btn_leave.pressed.disconnect(_on_leave)
		_signals_connected = false
	get_tree().paused = false
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
