# npc_interaction_menu.gd
extends CanvasLayer

@onready var panel:           PanelContainer = $Panel
@onready var npc_name_label:  Label          = $Panel/VBox/NpcNameLabel
@onready var archetype_label: Label          = $Panel/VBox/ArchetypeLabel
@onready var dialogue_label:  Label          = $Panel/VBox/DialogueLabel
@onready var btn_talk:        Button         = $Panel/VBox/Buttons/BtnTalk
@onready var btn_recruit:     Button         = $Panel/VBox/Buttons/BtnRecruit
@onready var btn_fight:       Button         = $Panel/VBox/Buttons/BtnFight
@onready var btn_close:       Button         = $Panel/VBox/BtnClose
@onready var result_label:    Label          = $Panel/VBox/ResultLabel

@onready var job_panel:  VBoxContainer = $Panel/VBox/JobPanel
@onready var job_label:  Label         = $Panel/VBox/JobPanel/JobLabel
@onready var job_option: OptionButton  = $Panel/VBox/JobPanel/JobOption
@onready var btn_assign: Button        = $Panel/VBox/JobPanel/BtnAssign

@onready var relation_panel:  VBoxContainer = $Panel/VBox/RelationPanel
@onready var relation_label:  Label         = $Panel/VBox/RelationPanel/RelationLabel
@onready var btn_rel_talk:    Button        = $Panel/VBox/RelationPanel/BtnRelTalk
@onready var btn_rel_gift:    Button        = $Panel/VBox/RelationPanel/BtnRelGift
@onready var btn_rel_insult:  Button        = $Panel/VBox/RelationPanel/BtnRelInsult
@onready var btn_change_job:  Button        = $Panel/VBox/RelationPanel/BtnChangeJob

var _npc: Node = null
var _pending_assign_name: String = ""


func _npc_name() -> String:
	if _npc.get("data") != null:
		return _npc.data.npc_name
	return str(_npc.get("npc_name") if _npc.get("npc_name") != null else "Unknown")


func _npc_gender() -> String:
	if _npc.get("npc_gender") != null:
		return str(_npc.get("npc_gender"))
	if _npc.get("data") != null and _npc.data.get("gender") != null:
		return str(_npc.data.get("gender"))
	return "male"


func _npc_archetype() -> String:
	if _npc.get("data") != null:
		return _npc.data.get_archetype_name()
	match _npc_gender():
		"female":  return "Human (F)"
		"monster": return "Monster"
		_:         return "Human"


func _npc_dialogue() -> String:
	if _npc.get("data") != null:
		return _npc.data.get_dialogue_line()
	var lines: Array[String] = ["...", "What do you want?", "Move along.", "Hmm."]
	return lines[randi() % lines.size()]


func _npc_strength() -> int:
	if _npc.get("data") != null:
		return int(_npc.data.stats.force)
	return int(_npc.get("strength") if _npc.get("strength") != null else 5)


func _npc_defense() -> int:
	if _npc.get("data") != null:
		return int(_npc.data.stats.defense)
	return int(_npc.get("strength") if _npc.get("strength") != null else 3)


func _npc_luck() -> int:
	if _npc.get("data") != null:
		return int(_npc.data.stats.luck)
	return 3


func _npc_already_taken() -> bool:
	var s: Variant = _npc.get("state")
	if s == null:
		return false
	return int(s) != 0


func _can_recruit() -> bool:
	if _npc.get("data") != null:
		return _npc.data.can_be_recruited_by_player()
	return true


func _get_relation() -> Node:
	if _npc == null:
		return null
	return _npc.get_node_or_null("RelationComponent")


func _ready() -> void:
	btn_talk.pressed.connect(_on_btn_talk_pressed)
	btn_recruit.pressed.connect(_on_btn_recruit_pressed)
	btn_fight.pressed.connect(_on_btn_fight_pressed)
	btn_close.pressed.connect(_on_btn_close_pressed)
	if job_panel != null:
		job_panel.visible = false
		_populate_job_option()
		if btn_assign != null:
			btn_assign.pressed.connect(_on_btn_assign_pressed)
	if relation_panel != null:
		relation_panel.visible = false
		if btn_rel_talk   != null: btn_rel_talk.pressed.connect(_on_rel_talk)
		if btn_rel_gift   != null: btn_rel_gift.pressed.connect(_on_rel_gift)
		if btn_rel_insult != null: btn_rel_insult.pressed.connect(_on_rel_insult)
		if btn_change_job != null: btn_change_job.pressed.connect(_on_rel_change_job)


func open(npc: Node) -> void:
	if not npc is CharacterBody2D:
		push_error("NpcInteractionMenu: invalid npc")
		return
	_npc = npc
	_refresh()
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS


func _refresh() -> void:
	if _npc == null:
		return
	npc_name_label.text  = _npc_name()
	archetype_label.text = _npc_archetype()
	result_label.text    = ""
	var taken: bool = _npc_already_taken()
	if taken:
		var rel: Node = _get_relation()
		var worker: Node = _npc.get_node_or_null("WorkerAI")
		var current_job: String = worker.job if worker != null else "(none)"
		dialogue_label.text = "Ally — Job: %s" % current_job
		btn_recruit.visible = false
		btn_fight.visible   = false
		btn_talk.visible    = false
		_show_relation_panel(rel)
	else:
		dialogue_label.text  = _npc_dialogue()
		btn_recruit.visible  = true
		btn_fight.visible    = true
		btn_talk.visible     = true
		btn_recruit.disabled = false
		btn_fight.disabled   = false
		if job_panel      != null: job_panel.visible      = false
		if relation_panel != null: relation_panel.visible = false


func _populate_job_option() -> void:
	if job_option == null:
		return
	job_option.clear()
	for job: String in CompanionManager.JOBS:
		job_option.add_item(job if job != "" else "(none)")


func _show_relation_panel(rel: Node) -> void:
	if relation_panel == null:
		return
	if rel != null:
		relation_label.text = rel.summary()
	else:
		relation_label.text = "No special bond yet."
	relation_panel.visible = true
	if job_panel != null:
		job_panel.visible = false


func _on_rel_talk() -> void:
	var rel: Node = _get_relation()
	if rel == null:
		result_label.text = "(No relation component)"
		return
	var day: int = int(float(Time.get_ticks_msec()) / 86400000.0)
	var msg: String = rel.talk(day)
	result_label.text = msg
	relation_label.text = rel.summary()


func _on_rel_gift() -> void:
	var rel: Node = _get_relation()
	if rel == null:
		return
	if GameManager.get_item("gold") < 5:
		result_label.text = "Not enough gold (5 required)."
		return
	GameManager.remove_item("gold", 5)
	var msg: String = rel.give_gift(5)
	result_label.text = msg
	relation_label.text = rel.summary()


func _on_rel_insult() -> void:
	var rel: Node = _get_relation()
	if rel == null:
		return
	result_label.text = rel.insult()
	relation_label.text = rel.summary()


func _on_rel_change_job() -> void:
	_pending_assign_name = _npc_name()
	if relation_panel != null:
		relation_panel.visible = false
	_show_job_panel("Change job for %s:" % _pending_assign_name)


func _on_btn_talk_pressed() -> void:
	if _npc.get("data") != null:
		var reveal: String = _npc.data.get_reveal_info()
		result_label.text = "You learn: " + reveal if reveal != "" else "You already know them well."
	else:
		result_label.text = _npc_dialogue()


func _on_btn_recruit_pressed() -> void:
	if _can_recruit():
		if _npc.has_method("recruit"): _npc.recruit()
		result_label.text = _npc_name() + " joins your group!"
		btn_recruit.disabled = true
		btn_fight.disabled   = true
		_pending_assign_name = _npc_name()
		_show_job_panel("Assign a job to %s:" % _pending_assign_name)
	else:
		if _npc.get("data") != null:
			var d: Resource = _npc.data
			var msg: String = "Refused — "
			if GameManager.charisma     < d.recruit_min_charisma: msg += "Charisma %d/%d " % [GameManager.charisma, d.recruit_min_charisma]
			if GameManager.force        < d.recruit_min_force:    msg += "Force %d/%d "    % [GameManager.force, d.recruit_min_force]
			if GameManager.intelligence < d.recruit_min_intel:    msg += "Intel %d/%d "    % [GameManager.intelligence, d.recruit_min_intel]
			result_label.text = msg
		else:
			result_label.text = "This character refuses to follow you."


func _on_btn_fight_pressed() -> void:
	var player_power: int = GameManager.force + GameManager.stamina
	var npc_power: int    = _npc_strength() + _npc_defense()
	var player_wins: bool = (
		player_power + randi_range(0, GameManager.luck) >=
		npc_power    + randi_range(0, _npc_luck())
	)
	if player_wins:
		_show_victory_choice()
	else:
		var dmg: int = max(1, int(float(npc_power) / 4.0))
		GameManager.life = max(0, GameManager.life - dmg)
		result_label.text = "You lose! -%d HP." % dmg
		btn_fight.disabled = true


func _show_victory_choice() -> void:
	result_label.text    = "Victory! Kill or capture?"
	btn_talk.visible     = false
	btn_fight.text       = "Kill"
	btn_fight.pressed.disconnect(_on_btn_fight_pressed)
	btn_fight.pressed.connect(_on_btn_kill_pressed)
	btn_recruit.visible  = true
	btn_recruit.text     = "Capture (Slave)"
	btn_recruit.disabled = false
	btn_recruit.pressed.disconnect(_on_btn_recruit_pressed)
	btn_recruit.pressed.connect(_on_btn_capture_pressed)


func _on_btn_kill_pressed() -> void:
	result_label.text = _npc_name() + " is dead."
	if _npc.has_method("die"): _npc.die()
	else: _npc.queue_free()
	_close()


func _on_btn_capture_pressed() -> void:
	if _npc.has_method("capture"): _npc.capture()
	result_label.text    = _npc_name() + " is now your slave."
	btn_fight.disabled   = true
	btn_recruit.disabled = true
	_pending_assign_name = _npc_name()
	_show_job_panel("Assign a job to %s:" % _pending_assign_name)


func _show_job_panel(title: String = "Assign a job:") -> void:
	if job_panel == null:
		return
	if job_label != null:
		job_label.text = title
	job_panel.visible = true


func _on_btn_assign_pressed() -> void:
	if job_option == null:
		return
	var idx: int = job_option.selected
	var chosen_job: String = CompanionManager.JOBS[idx] if idx >= 0 else ""
	if _pending_assign_name != "":
		CompanionManager.assign_job(_pending_assign_name, chosen_job)
	if _npc != null and _npc.has_method("change_job"):
		_npc.change_job(chosen_job)
	result_label.text = "%s -> %s" % [_pending_assign_name, chosen_job if chosen_job != "" else "(none)"]
	job_panel.visible = false
	if _npc_already_taken():
		_show_relation_panel(_get_relation())


func _on_btn_close_pressed() -> void:
	_close()


func _close() -> void:
	get_tree().paused = false
	queue_free()
