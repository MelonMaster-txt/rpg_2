# inventory_screen.gd
# Panneau inventaire ouvert/ferme avec la touche I
# Affiche tous les items + permet de manger les baies (a venir : hunger system)
extends Control

const ITEM_META := {
	"bois":        { "nom": "Bois",          "icone": "🪵", "consommable": false },
	"pierre":      { "nom": "Pierre",        "icone": "🪨", "consommable": false },
	"baies":       { "nom": "Baies",         "icone": "🍇", "consommable": true  },
	"graine_baie": { "nom": "Graine (baie)", "icone": "🌱", "consommable": false },
	"pioche":      { "nom": "Pioche",        "icone": "⛏️",  "consommable": false },
	"arrosoir":    { "nom": "Arrosoir",      "icone": "🪣", "consommable": false },
}

var _is_open: bool = false

@onready var grid:       GridContainer = $BG/Panel/VBox/Grid
@onready var title_lbl:  Label         = $BG/Panel/VBox/Title
@onready var close_btn:  Button        = $BG/Panel/VBox/CloseBtn

func _ready() -> void:
	add_to_group("inventory_screen")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	close_btn.pressed.connect(toggle)
	GameManager.inventory_changed.connect(_on_inventory_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		toggle()

func toggle() -> void:
	_is_open = not _is_open
	visible = _is_open
	if _is_open:
		_refresh()
		get_tree().paused = true
	else:
		get_tree().paused = false

func _on_inventory_changed(_item: String, _amount: int) -> void:
	if _is_open:
		_refresh()

func _refresh() -> void:
	for child in grid.get_children():
		child.queue_free()

	for item_id in ITEM_META:
		var meta: Dictionary = ITEM_META[item_id]
		var qty: int = GameManager.get_item(item_id)

		var card := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.12, 0.16, 0.95) if qty > 0 else Color(0.07, 0.07, 0.09, 0.7)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		style.content_margin_left = 8.0
		style.content_margin_right = 8.0
		style.content_margin_top = 6.0
		style.content_margin_bottom = 6.0
		card.add_theme_stylebox_override("panel", style)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var icone_lbl := Label.new()
		icone_lbl.text = meta["icone"]
		icone_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icone_lbl.add_theme_font_size_override("font_size", 28)

		var nom_lbl := Label.new()
		nom_lbl.text = meta["nom"]
		nom_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nom_lbl.add_theme_font_size_override("font_size", 11)
		nom_lbl.modulate = Color.WHITE if qty > 0 else Color(0.5, 0.5, 0.5)

		var qty_lbl := Label.new()
		qty_lbl.text = "x%d" % qty
		qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty_lbl.add_theme_font_size_override("font_size", 13)
		qty_lbl.modulate = Color(1, 0.9, 0.4) if qty > 0 else Color(0.4, 0.4, 0.4)

		vbox.add_child(icone_lbl)
		vbox.add_child(nom_lbl)
		vbox.add_child(qty_lbl)

		# Bouton manger si consommable et qty > 0
		if meta["consommable"] and qty > 0:
			var eat_btn := Button.new()
			eat_btn.text = "Manger"
			eat_btn.process_mode = Node.PROCESS_MODE_ALWAYS
			eat_btn.add_theme_font_size_override("font_size", 10)
			eat_btn.pressed.connect(_on_eat_pressed.bind(item_id))
			vbox.add_child(eat_btn)

		card.add_child(vbox)
		grid.add_child(card)

func _on_eat_pressed(item_id: String) -> void:
	# TODO: brancher sur le systeme de faim quand il sera cree
	# Pour l'instant : consomme 1 baie et affiche un message
	if GameManager.remove_item(item_id, 1):
		var popup := Label.new()
		popup.text = "Miam ! (+faim bientot)"
		popup.add_theme_font_size_override("font_size", 14)
		popup.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		popup.set_anchors_preset(Control.PRESET_CENTER)
		add_child(popup)
		var tw := create_tween()
		tw.tween_property(popup, "position", popup.position + Vector2(0, -40), 1.0)
		tw.parallel().tween_property(popup, "modulate:a", 0.0, 1.0)
		tw.tween_callback(popup.queue_free)
