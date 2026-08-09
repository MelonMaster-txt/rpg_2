# companion_manager.gd — Autoload
# Alias / façade vers PopulationManager pour la compatibilité des appels
# Engine.has_singleton("CompanionManager") dans random_npc.gd.
extends Node


func _ready() -> void:
	pass


func add_companion(entry: Dictionary) -> void:
	PopulationManager.add_companion(entry)


func add_slave(entry: Dictionary) -> void:
	PopulationManager.add_slave(entry)


func get_companions() -> Array[Dictionary]:
	return PopulationManager.get_companions()


func get_slaves() -> Array[Dictionary]:
	return PopulationManager.get_slaves()


func get_all() -> Array[Dictionary]:
	return PopulationManager.get_all()


func get_total_count() -> int:
	return PopulationManager.get_total_count()
