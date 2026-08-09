# npc_state_base.gd
# Classe de base pour tous les états NPC.
# Chaque état hérite de cette classe et override les méthodes nécessaires.
class_name NpcStateBase
extends Node

# Référence vers le NPC owner (RandomNpc)
var npc: CharacterBody2D = null
# Référence vers la State Machine
var sm: Node = null


func enter(_prev_state: String) -> void:
	pass


func exit(_next_state: String) -> void:
	pass


func update(_delta: float) -> String:
	return ""
