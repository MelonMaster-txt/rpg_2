extends Node

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func reset_for_new_game(seed: int) -> void:
	rng.seed = seed

func get_chunk_type(coords: Vector2i) -> String:
	# 0,0 = hutte
	if coords == Vector2i(0, 0):
		return "hut"

	# plus tard : chunks spéciaux selon la seed
	# ex simplifié : 5% de chance de village, 5% de camp
	var roll := rng.randi_range(0, 99)
	if roll < 5:
		return "special_village"
	elif roll < 10:
		return "special_camp"

	# sinon, chunk normal
	return "forest"
