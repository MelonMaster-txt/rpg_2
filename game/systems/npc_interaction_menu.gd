# npc_interaction_menu.gd
# Menu d'interaction NPC : DISCUTER / RECRUTER / CAPTURER
# Instancié dynamiquement par random_npc._open_interaction_menu()
extends CanvasLayer

# ─── ONREADY ──────────────────────────────────────────────────────────────────
@onready var _panel:        PanelContainer = $Panel
@onready var _name_label:   Label          = $Panel/VBox/NameLabel
@onready var _btn_discuss:  Button         = $Panel/VBox/BtnDiscuss
@onready var _btn_recruit:  Button         = $Panel/VBox/BtnRecruit
@onready var _btn_capture:  Button         = $Panel/VBox/BtnCapture
@onready var _btn_leave:    Button         = $Panel/VBox/BtnLeave

# ─── VARS ─────────────────────────────────────────────────────────────────────
var _npc: Node = null

# ─── OPEN ─────────────────────────────────────────────────────────────────────
func open(npc: Node) -> void:
	_npc = npc
	if _name_label:
		var n: String = npc.get("npc_name") if npc.get("npc_name") != null else "Inconnu"
		_name_label.text = n
	# Pause le jeu pendant le menu
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_btn_discuss.pressed.connect(_on_discuss)
	_btn_recruit.pressed.connect(_on_recruit)
	_btn_capture.pressed.connect(_on_capture)
	_btn_leave.pressed.connect(_on_leave)

# ─── ACTIONS ──────────────────────────────────────────────────────────────────
func _on_discuss() -> void:
	_close()
	# Dialogue basique — à enrichir avec DialogueManager plus tard
	if _npc != null and is_instance_valid(_npc):
		var npc_name_str: String = _npc.get("npc_name") if _npc.get("npc_name") != null else "???"
		print("[Interaction] Discussion avec ", npc_name_str)


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

# ─── CLOSE ────────────────────────────────────────────────────────────────────
func _close() -> void:
	get_tree().paused = false
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
