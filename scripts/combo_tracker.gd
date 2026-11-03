class_name ComboTracker
extends RefCounted

# Kill combo: every kill extends it, a pause longer than COMBO_TIMEOUT ends it.
# The multiplier scores each kill more, the HUD shows the streak.

const TIMEOUT = 2.0
const STEPS = [10, 25, 50, 100]
const NAMES = ["KILLING SPREE!", "RAMPAGE!", "UNSTOPPABLE!", "GODLIKE!"]

var count = 0
var _time_left = 0.0
var _hud = null
var _banner = null


func _init(hud, banner) -> void:
	_hud = hud
	_banner = banner


# public
func multiplier() -> int:
	var result = 1
	for step in STEPS:
		if count >= step:
			result += 1
	return result


# public - called every physics frame
func update(delta : float) -> void:
	if count == 0:
		return

	_time_left -= delta
	_hud.set_combo_alpha(clamp(_time_left / (TIMEOUT * 0.5), 0.2, 1.0))
	if _time_left <= 0:
		count = 0
		_hud.set_combo(0, 1)


# public - called on every kill
func add_kill() -> void:
	count += 1
	_time_left = TIMEOUT
	_hud.set_combo(count, multiplier())
	_hud.set_combo_alpha(1.0)

	var index = STEPS.find(count)
	if index != -1:
		_banner.show_text(NAMES[index], Color.MAGENTA)
		Juice.shake(3.0)
