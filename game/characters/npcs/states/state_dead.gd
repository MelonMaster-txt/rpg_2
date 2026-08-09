# state_dead.gd
# État terminal — le NPC est mort. Aucune transition possible.
extends NpcStateBase


func enter(_prev: String) -> void:
	npc.velocity = Vector2.ZERO
	var app: Node = npc.get_node_or_null("CharacterAppearance")
	if app:
		app.set_eye_style("closed")
	var cr: Node = npc.get_node_or_null("ColorRect")
	if cr:
		(cr as ColorRect).color = Color(0.3, 0.3, 0.3)


func update(_delta: float) -> String:
	return ""
