# npc_data.gd
# Resource qui definit le profil complet d'un NPC (genere aleatoirement ou a la main)
class_name NpcData
extends Resource

enum Archetype {
	BANDIT,
	WANDERER,
	MERCHANT,
	HERMIT,
	FARMER,
	WOODCUTTER
}

const FIRST_NAMES := [
	"Aldric", "Brun", "Cedric", "Dagan", "Erwan", "Finn", "Garic", "Hrold",
	"Ingvar", "Jorik", "Keld", "Leif", "Mord", "Nulf", "Orm", "Ragnar",
	"Sigrid", "Torvar", "Ulf", "Varg", "Wulf", "Yrsa", "Zara", "Astrid",
	"Bryn", "Dagny", "Eira", "Freya", "Gunna", "Helga"
]

const ARCHETYPE_DIALOGUE := {
	Archetype.BANDIT: [
		"Qu'est-ce que tu veux ?",
		"Je n'ai peur de rien.",
		"Va-t-en avant de le regretter."
	],
	Archetype.WANDERER: [
		"J'ai vu bien des choses sur la route...",
		"Le monde est vaste et plein de mysteres.",
		"Tu cherches quelque chose ?"
	],
	Archetype.MERCHANT: [
		"Les affaires sont les affaires.",
		"J'ai vu de meilleures offres dans ma vie.",
		"Tu as l'air d'avoir besoin d'aide."
	],
	Archetype.HERMIT: [
		"Laisse-moi tranquille.",
		"La solitude est une sagesse.",
		"..."
	],
	Archetype.FARMER: [
		"La recolte a ete mauvaise cette annee.",
		"Je cherche une terre a cultiver.",
		"La vie est dure pour un paysan."
	],
	Archetype.WOODCUTTER: [
		"Ces arbres ne se couperont pas tout seuls.",
		"Le bois se fait rare par ici.",
		"Je connais chaque arbre de cette foret."
	]
}

@export var npc_name: String          = ""
@export var archetype: Archetype      = Archetype.WANDERER
@export var stats: CharacterStats     = null
@export var recruit_min_charisma: int = 5
@export var recruit_min_force: int    = 0
@export var recruit_min_intel: int    = 0

@export var revealed_stats: Array[String] = []


static func generate_random() -> NpcData:
	var data := NpcData.new()
	data.npc_name  = FIRST_NAMES[randi() % FIRST_NAMES.size()]
	data.archetype = Archetype.values()[randi() % Archetype.size()]
	data.stats     = CharacterStats.new()
	data.stats.randomize_stats()
	data.stats.randomize_skills()
	match data.archetype:
		Archetype.BANDIT:
			data.stats.force         += randi_range(3, 6)
			data.stats.skill_combat   = randi_range(60, 100)
			data.recruit_min_force    = 8
			data.recruit_min_charisma = 10
		Archetype.WANDERER:
			data.stats.intelligence  += randi_range(3, 6)
			data.stats.luck          += randi_range(2, 4)
			data.recruit_min_charisma = 6
		Archetype.MERCHANT:
			data.stats.charisma      += randi_range(3, 6)
			data.stats.skill_trading  = randi_range(60, 100)
			data.recruit_min_intel    = 6
			data.recruit_min_charisma = 8
		Archetype.HERMIT:
			data.stats.intelligence += randi_range(5, 10)
			data.stats.charisma     -= randi_range(2, 4)
			data.recruit_min_intel   = 10
		Archetype.FARMER:
			data.stats.stamina       += randi_range(3, 6)
			data.stats.skill_farming  = randi_range(60, 100)
			data.recruit_min_charisma = 4
		Archetype.WOODCUTTER:
			data.stats.force             += randi_range(4, 7)
			data.stats.skill_woodcutting  = randi_range(60, 100)
			data.recruit_min_force        = 7
	return data


func get_dialogue_line() -> String:
	var lines: Array = ARCHETYPE_DIALOGUE.get(archetype, ["..."])
	return lines[randi() % lines.size()]


func get_archetype_name() -> String:
	return Archetype.keys()[archetype]


func can_be_recruited_by_player() -> bool:
	return (
		GameManager.charisma >= recruit_min_charisma
		and GameManager.force >= recruit_min_force
		and GameManager.intelligence >= recruit_min_intel
	)


func get_reveal_info() -> String:
	var all_revealable := [
		"force", "intelligence", "charisma", "stamina",
		"skill_farming", "skill_woodcutting", "skill_mining",
		"skill_crafting", "skill_combat", "skill_trading"
	]
	var hidden := []
	for s in all_revealable:
		if not s in revealed_stats:
			hidden.append(s)
	if hidden.is_empty():
		return ""
	var chosen: String = hidden[randi() % hidden.size()]
	revealed_stats.append(chosen)
	var val: int = stats.get(chosen)
	return "%s: %d" % [chosen.replace("skill_", "").capitalize(), val]
