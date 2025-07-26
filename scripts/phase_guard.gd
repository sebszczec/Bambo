extends Node

var current_phase = Enums.PHASE.Phase1

var phase_timer = Timer.new()

signal phase_timeout(value : PhaseTimeoutResult)

# PHASE1
var phase1_delay = 1.0

func _ready() -> void:
	pass
	
func start_phase(phase : Enums.PHASE):
	if phase == Enums.PHASE.Phase1:
		current_phase = phase
		phase_timer.wait_time = phase1_delay
		phase_timer.one_shot = false
		phase_timer.connect("timeout", on_phase_timer_timeout)
		add_child(phase_timer)
		phase_timer.start()
	elif phase == Enums.PHASE.Phase2:
		pass
	elif phase == Enums.PHASE.Phase3:
		pass

func on_phase_timer_timeout():
	if current_phase == Enums.PHASE.Phase1:
		var result = PhaseTimeoutResult.new()
		result.enemy = Enums.ENEMIES.SCOUT
		result.count = 1
		phase_timeout.emit(result)

class PhaseTimeoutResult:
	var enemy : Enums.ENEMIES
	var count : int
