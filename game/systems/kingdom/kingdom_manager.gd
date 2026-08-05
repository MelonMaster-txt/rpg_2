# kingdom_manager.gd — Autoload singleton
# Orchestre la production journalière du royaume.
extends Node

# ─── SIGNALS ──────────────────────────────────────────────────────────────────
signal day_production_done(report: Dictionary)

# ─── CONSTANTES ───────────────────────────────────────────────────────────────
const BASE_FOOD_PER_FARMER:    int = 3
const BASE_WOOD_PER_LUMBERJACK: int = 2
const BASE_STONE_PER_MINER:    int = 1
const BASE_GOLD_PER_TRADER:    int = 1

# ─── PRODUCTION JOURNALIÈRE ───────────────────────────────────────────────────
func process_daily_production() -> void:
	var report: Dictionary = {}
	_produce_by_job("farmer",     "berries", BASE_FOOD_PER_FARMER,     report)
	_produce_by_job("woodcutter", "wood",    BASE_WOOD_PER_LUMBERJACK, report)
	_produce_by_job("miner",      "stone",   BASE_STONE_PER_MINER,    report)
	_produce_by_job("trader",     "gold",    BASE_GOLD_PER_TRADER,    report)
	day_production_done.emit(report)


func _produce_by_job(
		job: String,
		resource: String,
		base_amount: int,
		report: Dictionary
) -> void:
	var workers: Array = PopulationManager.get_workers_by_job(job)
	if workers.is_empty():
		return
	var total: int = 0
	for w: Dictionary in workers:
		var skill_val: int = w.get("skills", {}).get(_job_to_skill(job), 1)
		total += base_amount + int(skill_val / 5)
	GameManager.add_item(resource, total)
	report[resource] = report.get(resource, 0) + total


func _job_to_skill(job: String) -> String:
	match job:
		"farmer":     return "farming"
		"woodcutter": return "woodcutting"
		"miner":      return "mining"
		"trader":     return "trading"
		"guard":      return "combat"
	_: return job

# ─── INFOS ROYAUME ────────────────────────────────────────────────────────────
func get_kingdom_summary() -> Dictionary:
	return {
		"population": PopulationManager.get_total_count(),
		"companions":  PopulationManager.companions.size(),
		"slaves":      PopulationManager.slaves.size(),
		"resources":   GameManager.inventory.duplicate(),
	}
