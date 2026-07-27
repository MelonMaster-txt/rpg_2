# npc_base.gd — NPC générique avec apparence aléatoire
# Héritage : instancie ce script pour tout NPC de l'overworld
extends CharacterBody2D

@export var npc_name: String       = ""
@export var is_random_look: bool   = true
@export var skin_override: String  = ""
@export var hair_override: String  = ""
@export var outfit_override: String = ""

@onready var appearance: Node = $CharacterAppearance


func _ready() -> void:
	add_to_group("npcs")
	if is_random_look:
		appearance.randomize_appearance()
	else:
		if skin_override   != "": appearance.set_skin(skin_override)
		if hair_override   != "": appearance.set_hair(hair_override)
		if outfit_override != "": appearance.set_outfit(outfit_override)


func get_appearance() -> Dictionary:
	return appearance.get_appearance_data()
