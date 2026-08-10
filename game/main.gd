# main.gd
# Point d'entree du jeu.
# Flux : MainMenu → (Nouvelle Partie) → CharacterCustomization → World
#        MainMenu → (Continuer)        → World directement
extends Node

const MAIN_MENU_SCENE:    PackedScene = preload("res://game/ui/menu/main_menu.tscn")
const LOADING_SCENE:      PackedScene = preload("res://game/ui/loading_screen.tscn")

var _loading: CanvasLayer = null


func _ready() -> void:
	_spawn_loading()
	# Le menu principal est la scene de démarrage — on ne spawne rien ici,
	# le ProjectSettings pointe sur main_menu.tscn ou sur main.tscn qui
	# change immédiatement vers le menu.
	get_tree().change_scene_to_file("res://game/ui/menu/main_menu.tscn")


# ── API publique appelée par d'autres systèmes ─────────────────────────────────

func show_loading() -> void:
	_spawn_loading()
	if _loading and _loading.has_method("show_loading"):
		_loading.show_loading()


func hide_loading() -> void:
	if _loading and _loading.has_method("hide_loading"):
		_loading.hide_loading()


# ── Interne ───────────────────────────────────────────────────────────────────

func _spawn_loading() -> void:
	if _loading == null:
		_loading = LOADING_SCENE.instantiate() as CanvasLayer
		add_child(_loading)
