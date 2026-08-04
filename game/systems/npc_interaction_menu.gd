# npc_interaction_menu.gd
# Menu d'interaction a 3 choix : Parler / Recruter / Combattre
extends CanvasLayer

@onready var panel: PanelContainer  = $Panel
@onready var npc_name_label: Label  = $Panel/VBox/NpcNameLabel
@onready var archetype_label: Label = $Panel/VBox/ArchetypeLabel
@onready var dialogue_label: Label  = $Panel/VBox/DialogueLabel
@onready var btn_talk: Button       = $Panel/VBox/Buttons/BtnTalk
@onready var btn_recruit: Button    = $Panel/VBox/Buttons/BtnRecruit
@onready var btn_fight: Button      = $Panel/VBox/Buttons/BtnFight
@onready var btn_close: Button      = $Panel/VBox/BtnClose
@onready var result_label: Label    = $Panel/VBox/ResultLabel

# Typage en Node pour eviter l'erreur de scope au chargement,
# le cast se fait a l'utilisation via is/as
var _npc: Node = null

func _ready() -> void:
	btn_talk.pressed.connect(_on_btn_talk_pressed)
	btn_recruit.pressed.connect(_on_btn_recruit_pressed)
	btn_fight.pressed.connect(_on_btn_fight_pressed)
	btn_close.pressed.connect(_on_btn_close_pressed)

func open(npc: Node) -> void:
	if not npc is CharacterBody2D:
		push_error("NpcInteractionMenu: npc invalide")
		return
	_npc = npc
	_refresh()
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS

func _refresh() -> void:
	if _npc == null or _npc.get("data") == null:
		return
	npc_name_label.text  = _npc.data.npc_name
	archetype_label.text = _npc.data.get_archetype_name()
	dialogue_label.text  = _npc.data.get_dialogue_line()
	result_label.text    = ""
	var already_taken: bool = _npc.get("state") != 0  # 0 = State.LIBRE
	btn_recruit.disabled = already_taken
	btn_fight.disabled   = already_taken

func _on_btn_talk_pressed() -> void:
	var reveal: String = _npc.data.get_reveal_info()
	if reveal != "":
		result_label.text = "Vous apprenez : " + reveal
	else:
		result_label.text = "Vous le connaissez deja bien."

func _on_btn_recruit_pressed() -> void:
	if _npc.data.can_be_recruited_by_player():
		_npc.recruit()
		result_label.text = _npc.data.npc_name + " rejoint votre groupe !"
		btn_recruit.disabled = true
		btn_fight.disabled   = true
	else:
		var msg := "Refus. Requis — "
		if GameManager.charisma < _npc.data.recruit_min_charisma:
			msg += "Charisme %d/%d " % [GameManager.charisma, _npc.data.recruit_min_charisma]
		if GameManager.force < _npc.data.recruit_min_force:
			msg += "Force %d/%d " % [GameManager.force, _npc.data.recruit_min_force]
		if GameManager.intelligence < _npc.data.recruit_min_intel:
			msg += "Intel %d/%d " % [GameManager.intelligence, _npc.data.recruit_min_intel]
		result_label.text = msg

func _on_btn_fight_pressed() -> void:
	var player_power: int = GameManager.force + GameManager.stamina
	var npc_power: int    = int(_npc.data.stats.force) + int(_npc.data.stats.defense)
	var player_wins: bool = player_power + randi_range(0, GameManager.luck) >= \
						npc_power    + randi_range(0, int(_npc.data.stats.luck))
	if player_wins:
		_show_victory_choice()
	else:
		var dmg: int = max(1, npc_power / 4)
		GameManager.life = max(0, GameManager.life - dmg)
		result_label.text = "Vous perdez ! Vous prenez %d degats." % dmg
		btn_fight.disabled = true

func _show_victory_choice() -> void:
	result_label.text = "Victoire ! Tuer ou capturer ?"
	btn_talk.visible    = false
	btn_fight.text      = "Tuer"
	btn_fight.pressed.disconnect(_on_btn_fight_pressed)
	btn_fight.pressed.connect(_on_btn_kill_pressed)
	btn_recruit.visible  = true
	btn_recruit.text     = "Capturer (Esclave)"
	btn_recruit.disabled = false
	btn_recruit.pressed.disconnect(_on_btn_recruit_pressed)
	btn_recruit.pressed.connect(_on_btn_capture_pressed)

func _on_btn_kill_pressed() -> void:
	result_label.text = _npc.data.npc_name + " est mort."
	_npc.die()
	_close()

func _on_btn_capture_pressed() -> void:
	_npc.capture()
	result_label.text = _npc.data.npc_name + " est maintenant votre esclave."
	btn_fight.disabled   = true
	btn_recruit.disabled = true

func _on_btn_close_pressed() -> void:
	_close()

func _close() -> void:
	get_tree().paused = false
	queue_free()
