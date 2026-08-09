# state_work.gd
# Délègue TOUT au WorkerAI — ne touche pas à velocity.
# Le WorkerAI a sa propre sous-state-machine (IDLE/SEEK/HARVEST/RETURN/DEPOSIT).
extends NpcStateBase


func enter(_prev: String) -> void:
	# S'assure que le WorkerAI est actif
	var worker: Node = npc.get_node_or_null("WorkerAI")
	if worker != null:
		worker.set_process(true)
		worker.set_physics_process(true)


func exit(_next: String) -> void:
	# Quand on quitte work, on arrête le WorkerAI
	var worker: Node = npc.get_node_or_null("WorkerAI")
	if worker != null:
		worker.set_physics_process(false)
		npc.velocity = Vector2.ZERO


func update(_delta: float) -> String:
	# Rien à faire ici : le WorkerAI tourne dans son propre _physics_process
	return ""
