# npc_interaction_menu.gd
# Menu d'interaction a 3 choix : Parler / Recruter / Combattre
# Compatible random_npc.gd (proprietes directes) ET npc_base.gd (avec .data)
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

var _npc: Node = null

# ─── Helpers lecture universelle ──────────────────────────────────────────────
# Fonctionne que le NPC ait .data (NpcBase) ou des proprietes directes (RandomNpc)

func _npc_name() -> String:
	if _npc.get("data") != null:
		return _npc.data.npc_name
	return str(_npc.get("npc_name") if _npc.get("npc_name") != null else "Inconnu")

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
		"female":  return "Humaine"
		"monster": return "Monstre"
		_:         return "Humain"

func _npc_dialogue() -> String:
	if _npc.get("data") != null:
		return _npc.data.get_dialogue_line()
	var lines := [
		"...",
		"Que me veux-tu ?",
		"Passe ton chemin.",
		"Hmm.",
		"Je ne te connais pas.",
	]
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
	var s = _npc.get("state")
	if s == null: return false
	return int(s) != 0  # 0 = LIBRE

func _can_recruit() -> bool:
	if _npc.get("data") != null:
		return _npc.data.can_be_recruited_by_player()
	# Pour random_npc : toujours recrutablé (pas de seuil de stats)
	return true

# ─── Cycle de vie ─────────────────────────────────────────────────────────────

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
	if _npc == null:
		return
	npc_name_label.text  = _npc_name()
	archetype_label.text = _npc_archetype()
	dialogue_label.text  = _npc_dialogue()
	result_label.text    = ""
	var taken := _npc_already_taken()
	btn_recruit.disabled = taken
	btn_fight.disabled   = taken

# ─── Boutons ──────────────────────────────────────────────────────────────────

func _on_btn_talk_pressed() -> void:
	if _npc.get("data") != null:
		var reveal: String = _npc.data.get_reveal_info()
		result_label.text = "Vous apprenez : " + reveal if reveal != "" else "Vous le connaissez deja bien."
	else:
		result_label.text = _npc_dialogue()

func _on_btn_recruit_pressed() -> void:
	if _can_recruit():
		if _npc.has_method("recruit"):
			_npc.recruit()
		result_label.text = _npc_name() + " rejoint votre groupe !"
		btn_recruit.disabled = true
		btn_fight.disabled   = true
	else:
		# NpcBase avec seuils de stats
		var d = _npc.data
		var msg := "Refus. Requis — "
		if GameManager.charisma  < d.recruit_min_charisma: msg += "Charisme %d/%d "  % [GameManager.charisma,     d.recruit_min_charisma]
		if GameManager.force     < d.recruit_min_force:    msg += "Force %d/%d "     % [GameManager.force,        d.recruit_min_force]
		if GameManager.intelligence < d.recruit_min_intel: msg += "Intel %d/%d "     % [GameManager.intelligence, d.recruit_min_intel]
		result_label.text = msg

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
		var dmg: int = max(1, npc_power / 4)
		GameManager.life = max(0, GameManager.life - dmg)
		result_label.text = "Vous perdez ! Vous prenez %d dégâts." % dmg
		btn_fight.disabled = true

func _show_victory_choice() -> void:
	result_label.text = "Victoire ! Tuer ou capturer ?"
	btn_talk.visible  = false
	btn_fight.text    = "Tuer"
	btn_fight.pressed.disconnect(_on_btn_fight_pressed)
	btn_fight.pressed.connect(_on_btn_kill_pressed)
	btn_recruit.visible  = true
	btn_recruit.text     = "Capturer (Esclave)"
	btn_recruit.disabled = false
	btn_recruit.pressed.disconnect(_on_btn_recruit_pressed)
	btn_recruit.pressed.connect(_on_btn_capture_pressed)

func _on_btn_kill_pressed() -> void:
	result_label.text = _npc_name() + " est mort."
	if _npc.has_method("die"): _npc.die()
	else: _npc.queue_free()
	_close()

func _on_btn_capture_pressed() -> void:
	if _npc.has_method("capture"): _npc.capture()
	result_label.text = _npc_name() + " est maintenant votre esclave."
	btn_fight.disabled   = true
	btn_recruit.disabled = true

func _on_btn_close_pressed() -> void:
	_close()

func _close() -> void:
	get_tree().paused = false
	queue_free()
