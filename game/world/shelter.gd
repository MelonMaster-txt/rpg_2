# shelter.gd
# Script a attacher sur n'importe quel batiment de logement (tente, hutte, caserne...).
# Se charge tout seul aupres de HousingManager au _ready().
extends Node2D

@export var shelter_id:       String = ""     # ID unique (ex: "tent_01", "barrack_north")
@export var shelter_name:     String = "Tente" # Nom affiche dans l'UI
@export var shelter_capacity: int    = 2       # Nombre de personnes logeables


func _ready() -> void:
	if shelter_id == "":
		# Genere un ID unique base sur la position si pas defini
		shelter_id = "shelter_%d_%d" % [int(global_position.x), int(global_position.y)]
	var hm: Node = Engine.get_singleton("HousingManager")
	if hm != null:
		hm.register_shelter(shelter_id, shelter_name, shelter_capacity)
	else:
		push_warning("shelter.gd : HousingManager introuvable pour '%s'" % shelter_id)


func _exit_tree() -> void:
	var hm: Node = Engine.get_singleton("HousingManager")
	if hm != null:
		hm.unregister_shelter(shelter_id)
