# hut_chunk_spawner.gd
# A ajouter comme script sur le noeud racine de hut_chunk.tscn
# Spawne le coffre de la base au centre de la hutte si absent
extends Node2D

const CHEST_SCENE: PackedScene = preload("res://game/world/chest.tscn")
# Position relative dans le chunk hut (centre approximatif de la cahute)
const CHEST_LOCAL_POS: Vector2 = Vector2(256, 300)


func _ready() -> void:
	# Ne spawner qu'une seule fois (le chunk peut etre rechargé depuis le pool)
	if get_tree().get_nodes_in_group("chest").size() > 0:
		return
	var chest: Node2D = CHEST_SCENE.instantiate() as Node2D
	chest.position = CHEST_LOCAL_POS
	chest.name = "BaseChest"
	add_child(chest)
	print("[HutChunk] Coffre spawné à ", chest.global_position)
