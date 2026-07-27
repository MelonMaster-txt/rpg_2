extends Area2D

var _player_in_area: bool = false
var _transitioning:  bool = false


func _ready() -> void:
	# IMPORTANT : ne pas connecter ici si les signaux sont déjà
	# branchés dans la scène .tscn via l'éditeur Godot.
	# On utilise connect() UNIQUEMENT en code — retirer les connexions
	# dans le panneau Node > Signals de la scène pour éviter le double.
	#
	# Si tu préfères tout gérer en code : supprime les connexions dans
	# l'éditeur et laisse ce bloc actif.
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_area = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_area = false


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning:
		return
	if _player_in_area and event.is_action_pressed("interact") and not event.is_echo():
		_transitioning = true
		set_process_unhandled_input(false)
		SceneManager.change_scene("res://game/world/scenes/hut.tscn")
