# companion_manager.gd — Autoload
# Façade vers PopulationManager.
# Utilise Engine.get_singleton() pour éviter les erreurs de compilation
# dues à l'ordre de chargement des Autoloads.
extends Node


func _ready() -> void:
	pass


func _get_pm() -> Node:
	return Engine.get_singleton("PopulationManager")


func add_companion(entry: Dictionary) -> void:
	var pm: Node = _get_pm()
	if pm:
		pm.add_companion(entry)


func add_slave(entry: Dictionary) -> void:
	var pm: Node = _get_pm()
	if pm:
		pm.add_slave(entry)


func get_companions() -> Array:
	var pm: Node = _get_pm()
	if pm:
		return pm.get_companions()
	return []


func get_slaves() -> Array:
	var pm: Node = _get_pm()
	if pm:
		return pm.get_slaves()
	return []


func get_all() -> Array:
	var pm: Node = _get_pm()
	if pm:
		return pm.get_all()
	return []


func get_total_count() -> int:
	var pm: Node = _get_pm()
	if pm:
		return pm.get_total_count()
	return 0
