extends Perk

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	super.set_perk_type(Enums.PERKS.MAGNET)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		taken.emit()
		queue_free()

# public - pulls every xp gem and shard to the ship
func apply_to(player) -> void:
	player.createFloatingText("Magnet!", Color.GOLD, 2)
	player.get_tree().call_group("XpGem", "attract")
	player.get_tree().call_group("Shard", "attract")
