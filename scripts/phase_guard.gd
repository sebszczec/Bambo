extends Node

var current_phase = Enums.PHASE.Phase1

var phase_timer = Timer.new()

signal phase_timeout(value : PhaseTimeoutResult)

# PHASE1
var phase1_delay = 1.0
var phase1_enemy_ratio = 1
var phase1_enemy = Enums.ENEMIES.SCOUT

# PHASE2
var phase2_delay = 1.0
var phase2_enemy_ratio = 2
var phase2_enemy = Enums.ENEMIES.SCOUT

# PHASE3
var phase3_delay = 1.0
var phase3_enemy_ratio1 = 2
var phase3_enemy1 = Enums.ENEMIES.SCOUT
var phase3_enemy_ratio2 = 1
var phase3_enemy2 = Enums.ENEMIES.GUARD

# PHASE4
var phase4_delay = 4.0
var phase4_enemy_ratio = 1
var phase4_enemy = Enums.ENEMIES.HUNTER

# PHASE5
var phase5_delay = 5.0
var phase5_enemy_ratio1 = 3
var phase5_enemy1 = Enums.ENEMIES.SCOUT
var phase5_enemy_ratio2 = 1
var phase5_enemy2 = Enums.ENEMIES.HUNTER
var phase5_enemy_ratio3 = 1
var phase5_enemy3 = Enums.ENEMIES.GUARD

func _ready() -> void:
	phase_timer.connect("timeout", on_phase_timer_timeout)
	add_child(phase_timer)
	pass
	
func start_phase(phase : Enums.PHASE):
	stop_phase(current_phase)
	current_phase = phase
	if phase == Enums.PHASE.Phase1:
		phase_timer.wait_time = phase1_delay
		phase_timer.one_shot = false
		phase_timer.start()
	elif phase == Enums.PHASE.Phase2:
		phase_timer.wait_time = phase2_delay
		phase_timer.one_shot = false
		phase_timer.start()
	elif phase == Enums.PHASE.Phase3:
		phase_timer.wait_time = phase3_delay
		phase_timer.one_shot = false
		phase_timer.start()
	elif phase == Enums.PHASE.Phase4:
		phase_timer.wait_time = phase5_delay
		phase_timer.one_shot = false
		phase_timer.start()
	elif phase == Enums.PHASE.Phase5:
		phase_timer.wait_time = phase5_delay
		phase_timer.one_shot = false
		phase_timer.start()

func stop_phase(_phase : Enums.PHASE):
	phase_timer.stop()

func on_phase_timer_timeout():
	if current_phase == Enums.PHASE.Phase1:
		pass
		#var result = [PhaseTimeoutResult.new()]
		#result[0].enemy = phase1_enemy
		#result[0].count = phase1_enemy_ratio
		#phase_timeout.emit(result)
	elif current_phase == Enums.PHASE.Phase2:
		var result = [PhaseTimeoutResult.new()]
		result[0].enemy = phase2_enemy
		result[0].count = phase2_enemy_ratio
		phase_timeout.emit(result)
	elif current_phase == Enums.PHASE.Phase3:
		var result = [PhaseTimeoutResult.new(), PhaseTimeoutResult.new()]
		result[0].enemy = phase3_enemy1
		result[0].count = phase3_enemy_ratio1
		result[1].enemy = phase3_enemy2
		result[1].count = phase3_enemy_ratio2
		phase_timeout.emit(result)
	elif current_phase == Enums.PHASE.Phase4:
		var result = [PhaseTimeoutResult.new(), PhaseTimeoutResult.new(), PhaseTimeoutResult.new()]
		result[0].enemy = phase5_enemy1
		result[0].count = phase5_enemy_ratio1
		result[1].enemy = phase5_enemy2
		result[1].count = phase5_enemy_ratio2
		result[2].enemy = phase5_enemy3
		result[2].count = phase5_enemy_ratio3
		phase_timeout.emit(result)
	elif current_phase == Enums.PHASE.Phase5:
		var result = [PhaseTimeoutResult.new(), PhaseTimeoutResult.new(), PhaseTimeoutResult.new()]
		result[0].enemy = phase5_enemy1
		result[0].count = phase5_enemy_ratio1
		result[1].enemy = phase5_enemy2
		result[1].count = phase5_enemy_ratio2
		result[2].enemy = phase5_enemy3
		result[2].count = phase5_enemy_ratio3
		phase_timeout.emit(result)

class PhaseTimeoutResult:
	var enemy : Enums.ENEMIES
	var count : int
