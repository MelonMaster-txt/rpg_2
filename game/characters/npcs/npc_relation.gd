# npc_relation.gd
extends Node

const FRIENDSHIP_MAX := 100
const FRIENDSHIP_MIN := -100

enum Level { HOSTILE = -2, NEUTRAL = 0, ACQUAINTANCE = 1, FRIEND = 2, TRUSTED = 3, SOULMATE = 4 }

var friendship:    int = 0
var trust:         int = 0
var mood:          int = 50
var talk_count:    int = 0
var gift_count:    int = 0
var last_talk_day: int = -1

signal relation_changed(new_level: int)

func get_level() -> Level:
	if friendship >= 80: return Level.SOULMATE
	if friendship >= 50: return Level.TRUSTED
	if friendship >= 20: return Level.FRIEND
	if friendship >= 5:  return Level.ACQUAINTANCE
	if friendship < -20: return Level.HOSTILE
	return Level.NEUTRAL

func level_name() -> String:
	match get_level():
		Level.SOULMATE:     return "Âme sœur"
		Level.TRUSTED:      return "Confiant·e"
		Level.FRIEND:       return "Ami·e"
		Level.ACQUAINTANCE: return "Connaissance"
		Level.HOSTILE:      return "Hostile"
		_:                  return "Neutre"

func level_icon() -> String:
	match get_level():
		Level.SOULMATE:     return "💞"
		Level.TRUSTED:      return "🤝"
		Level.FRIEND:       return "😊"
		Level.ACQUAINTANCE: return "🙂"
		Level.HOSTILE:      return "😠"
		_:                  return "😐"

# ─── Modificateurs ───────────────────────────────────────────────────────────────

func talk(day: int = -1) -> String:
	var already_today := (day >= 0 and day == last_talk_day)
	if already_today:
		return _mood_line("Tu m'as déjà parlé aujourd'hui.", -1)
	last_talk_day = day
	talk_count += 1
	# FIX: float division pour éviter INTEGER_DIVISION warning
	var gain: int = randi_range(2, 6) + int(float(mood) / 20.0)
	_add_friendship(gain)
	return _mood_line("Tu gagnes +%d amitié." % gain, gain)

func give_gift(value: int = 5) -> String:
	gift_count += 1
	var gain: int = value + randi_range(0, 3)
	_add_friendship(gain)
	# FIX: float division
	var trust_gain: int = int(float(gain) / 2.0)
	trust = min(100, trust + trust_gain)
	return _mood_line("Don apprécié ! +%d amitié, +%d confiance." % [gain, trust_gain], gain)

func insult() -> String:
	var loss: int = randi_range(5, 15)
	_add_friendship(-loss)
	return _mood_line("Tu perds -%d amitié." % loss, -loss)

func do_favor(amount: int = 10) -> String:
	_add_friendship(amount)
	# FIX: float division
	var trust_gain: int = int(float(amount) / 3.0)
	trust = min(100, trust + trust_gain)
	return "+%d amitié pour service rendu." % amount

# ─── Interne ────────────────────────────────────────────────────────────────────────

func _add_friendship(delta: int) -> void:
	var old_lvl := get_level()
	friendship = clamp(friendship + delta, FRIENDSHIP_MIN, FRIENDSHIP_MAX)
	if get_level() != old_lvl:
		relation_changed.emit(int(get_level()))

func _mood_line(base: String, _delta: int) -> String:
	var mood_str: String
	if mood >= 70:   mood_str = " 😄 Il est de bonne humeur."
	elif mood >= 40: mood_str = ""
	else:            mood_str = " 😔 Il est de mauvaise humeur."
	return base + mood_str

func randomize_mood() -> void:
	mood = randi_range(20, 100)

func summary() -> String:
	return "%s %s | Amitié: %d | Confiance: %d | Humeur: %d" % [
		level_icon(), level_name(), friendship, trust, mood]
