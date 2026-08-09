# npc_state_machine.gd
# Gère la State Machine d'un NPC.
# Usage : ajouter comme enfant du NPC, appeler init(npc_node), puis transition("idle").
#
# États disponibles : idle, wander, follow, work, combat, flee, dead
class_name NpcStateMachine
extends Node

const STATE_SCRIPTS: Dictionary = {
	"idle":   "res://game/characters/npcs/states/state_idle.gd",
	"wander": "res://game/characters/npcs/states/state_wander.gd",
	"follow": "res://game/characters/npcs/states/state_follow.gd",
	"work":   "res://game/characters/npcs/states/state_work.gd",
	"combat": "res://game/characters/npcs/states/state_combat.gd",
	"flee":   "res://game/characters/npcs/states/state_flee.gd",
	"dead":   "res://game/characters/npcs/states/state_dead.gd",
}

var _states: Dictionary = {}         # nom → instance NpcStateBase
var _current_state: NpcStateBase = null
var _current_name:  String = ""
var _npc: CharacterBody2D = null

signal state_changed(from: String, to: String)


func init(npc_node: CharacterBody2D) -> void:
	_npc = npc_node
	# Instancie tous les états
	for state_name: String in STATE_SCRIPTS:
		var script: Script = load(STATE_SCRIPTS[state_name])
		if script == null:
			push_error("NpcStateMachine: script introuvable pour '%s'" % state_name)
			continue
		var instance: NpcStateBase = NpcStateBase.new()
		instance.set_script(script)
		instance.npc = _npc
		instance.sm  = self
		instance.name = "State_" + state_name
		add_child(instance)
		_states[state_name] = instance


func transition(new_state: String) -> void:
	if new_state == _current_name:
		return
	if not _states.has(new_state):
		push_error("NpcStateMachine: état inconnu '%s'" % new_state)
		return
	var prev_name: String = _current_name
	if _current_state != null:
		_current_state.exit(new_state)
	_current_name  = new_state
	_current_state = _states[new_state]
	_current_state.enter(prev_name)
	state_changed.emit(prev_name, new_state)


func update(delta: float) -> void:
	if _current_state == null:
		return
	var next: String = _current_state.update(delta)
	if next != "":
		transition(next)


func get_current() -> String:
	return _current_name


func is_state(state_name: String) -> bool:
	return _current_name == state_name
