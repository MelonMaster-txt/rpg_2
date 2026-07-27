extends CanvasLayer

# Référence aux éléments UI (à connecter dans la scène)
# @onready var health_bar: ProgressBar = $HealthBar
# @onready var label_hp: Label = $LabelHP

func _ready() -> void:
	print("HUD loaded and ready")

# Appelle cette fonction pour mettre à jour la vie affichée
func update_health(current: int, max_health: int) -> void:
	pass
	# health_bar.value = float(current) / float(max_health) * 100.0
	# label_hp.text = str(current) + " / " + str(max_health)
