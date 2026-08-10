# npc_appearance.gd
# Wrapper leger : applique une apparence aleatoire ou depuis NPCData
# au composant CharacterAppearance du NPC.
# A utiliser dans le _ready() de ton NPC.
extends Node

const GENDERS:    Array = ["male", "female"]
const HAIRS:      Array = ["short", "medium", "long", "bald"]
const EYE_STYLES: Array = ["normal", "closed", "angry", "sad"]
const OUTFITS:    Array = ["none", "peasant", "guard", "mage", "farmer"]

const SKIN_PRESETS: Array = [
	Color(1.00, 0.87, 0.74),
	Color(0.96, 0.76, 0.57),
	Color(0.89, 0.65, 0.44),
	Color(0.80, 0.55, 0.34),
	Color(0.67, 0.42, 0.24),
	Color(0.52, 0.30, 0.15),
	Color(0.36, 0.20, 0.10),
]


## Applique une apparence completement aleatoire au CharacterAppearance du parent
func randomize_appearance(char_appearance: Node) -> void:
	if char_appearance == null or not char_appearance.has_method("apply_appearance"):
		return
	var data: Dictionary = {
		"gender":       GENDERS[randi() % GENDERS.size()],
		"hair":         HAIRS[randi() % HAIRS.size()],
		"eye_style":    EYE_STYLES[randi() % EYE_STYLES.size()],
		"outfit":       OUTFITS[randi() % OUTFITS.size()],
		"skin_color":   SKIN_PRESETS[randi() % SKIN_PRESETS.size()],
		"hair_color":   Color(randf_range(0.1, 0.9), randf_range(0.05, 0.6), randf_range(0.0, 0.3)),
		"eyes_color":   Color(randf_range(0.1, 1.0), randf_range(0.2, 1.0), randf_range(0.2, 1.0)),
		"outfit_color": Color(randf_range(0.3, 0.8), randf_range(0.2, 0.6), randf_range(0.1, 0.4)),
	}
	char_appearance.apply_appearance(data)


## Applique une apparence depuis un dictionnaire NPCData (si deja defini)
func apply_from_data(char_appearance: Node, npc_data: Dictionary) -> void:
	if npc_data.has("appearance"):
		char_appearance.apply_appearance(npc_data["appearance"])
	else:
		randomize_appearance(char_appearance)
