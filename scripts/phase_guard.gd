extends Node

# Run structure (survival clock): the run lasts RUN_LENGTH seconds, every minute
# is a stage with its own spawn rate and enemy mix, swarms and an elite come at
# fixed times and the boss arrives when the clock runs out.
# After the boss is killed the run continues in Endless mode
# with difficulty growing over time and the boss coming back.

const RUN_LENGTH = 600.0
const STAGE_LENGTH = 60.0
const SWARM_EVERY = 90.0
const ELITE_AT = 300.0
const DIFFICULTY_STEP = 0.15
const DIFFICULTY_INTERVAL = 60.0
const ENDLESS_MAX_ALIVE_STEP = 10
const ENDLESS_BOSS_EVERY = 300.0
const BOSS_SPAWN_SLOWDOWN = 1.5

var current_phase = Enums.PHASE.Survival
var current_stage = 0
var difficulty : float = 1.0
var elapsed : float = 0.0

var phase_timer = Timer.new()
var difficulty_timer = Timer.new()

var _running = false
var _next_swarm = SWARM_EVERY
var _elite_spawned = false
var _next_endless_boss = 0.0
var _endless_steps = 0
var _boss_alive = false
var _last_second = -1

signal phase_started(phase : Enums.PHASE, phase_name : String)
signal stage_started(stage : int)
signal phase_timeout(value : Array)
signal boss_requested
signal elite_requested
signal swarm_requested(count : int)
signal difficulty_changed(value : float)
signal time_changed(seconds : int)

# one entry per minute, wave entry = [enemy, count, chance in %]
var _stages : Array = [
	{ "delay" : 0.9, "max_alive" : 30,
		"wave" : [[Enums.ENEMIES.SCOUT, 3, 100]] },
	{ "delay" : 0.8, "max_alive" : 45,
		"wave" : [[Enums.ENEMIES.SCOUT, 4, 100], [Enums.ENEMIES.GUARD, 1, 20]] },
	{ "delay" : 0.7, "max_alive" : 60,
		"wave" : [[Enums.ENEMIES.SCOUT, 4, 100], [Enums.ENEMIES.GUARD, 1, 35], [Enums.ENEMIES.HUNTER, 1, 10]] },
	{ "delay" : 0.6, "max_alive" : 70,
		"wave" : [[Enums.ENEMIES.SCOUT, 5, 100], [Enums.ENEMIES.GUARD, 1, 40], [Enums.ENEMIES.HUNTER, 1, 20]] },
	{ "delay" : 0.55, "max_alive" : 85,
		"wave" : [[Enums.ENEMIES.SCOUT, 5, 100], [Enums.ENEMIES.GUARD, 1, 50], [Enums.ENEMIES.HUNTER, 1, 30]] },
	{ "delay" : 0.5, "max_alive" : 100,
		"wave" : [[Enums.ENEMIES.SCOUT, 6, 100], [Enums.ENEMIES.GUARD, 2, 50], [Enums.ENEMIES.HUNTER, 1, 35]] },
	{ "delay" : 0.45, "max_alive" : 110,
		"wave" : [[Enums.ENEMIES.SCOUT, 6, 100], [Enums.ENEMIES.GUARD, 2, 60], [Enums.ENEMIES.HUNTER, 1, 45]] },
	{ "delay" : 0.4, "max_alive" : 120,
		"wave" : [[Enums.ENEMIES.SCOUT, 7, 100], [Enums.ENEMIES.GUARD, 2, 70], [Enums.ENEMIES.HUNTER, 2, 45]] },
	{ "delay" : 0.35, "max_alive" : 130,
		"wave" : [[Enums.ENEMIES.SCOUT, 7, 100], [Enums.ENEMIES.GUARD, 2, 80], [Enums.ENEMIES.HUNTER, 2, 60]] },
	{ "delay" : 0.3, "max_alive" : 140,
		"wave" : [[Enums.ENEMIES.SCOUT, 8, 100], [Enums.ENEMIES.GUARD, 3, 80], [Enums.ENEMIES.HUNTER, 2, 70]] },
]

var _phase_names : Dictionary = {
	Enums.PHASE.Survival : "Survival",
	Enums.PHASE.Boss : "Boss",
	Enums.PHASE.Endless : "Endless",
}

func _ready() -> void:
	phase_timer.connect("timeout", on_phase_timer_timeout)
	add_child(phase_timer)

	difficulty_timer.wait_time = DIFFICULTY_INTERVAL
	difficulty_timer.connect("timeout", on_difficulty_timer_timeout)
	add_child(difficulty_timer)

func _process(delta: float) -> void:
	if !_running:
		return

	elapsed += delta

	var second = int(elapsed)
	if second != _last_second:
		_last_second = second
		time_changed.emit(second)

	if current_phase == Enums.PHASE.Survival:
		var stage = min(int(elapsed / STAGE_LENGTH), _stages.size() - 1)
		if stage != current_stage:
			_start_stage(stage)

		if !_elite_spawned and elapsed >= ELITE_AT:
			_elite_spawned = true
			elite_requested.emit()

		if elapsed >= RUN_LENGTH:
			start_phase(Enums.PHASE.Boss)
			return

	if current_phase != Enums.PHASE.Boss and elapsed >= _next_swarm:
		_next_swarm += SWARM_EVERY
		swarm_requested.emit(20 + 3 * current_stage + 2 * _endless_steps)

	if current_phase == Enums.PHASE.Endless and !_boss_alive and elapsed >= _next_endless_boss:
		_next_endless_boss += ENDLESS_BOSS_EVERY
		_request_boss()

func start_phase(phase : Enums.PHASE):
	stop_phase(current_phase)
	current_phase = phase
	_running = true

	if phase == Enums.PHASE.Survival:
		_start_stage(0)
	elif phase == Enums.PHASE.Boss:
		_start_stage(_stages.size() - 1)
		phase_timer.wait_time *= BOSS_SPAWN_SLOWDOWN
	elif phase == Enums.PHASE.Endless:
		_start_stage(_stages.size() - 1)
		difficulty_timer.start()

	phase_started.emit(phase, _phase_names[phase])

	if phase == Enums.PHASE.Boss:
		_request_boss()

func _start_stage(stage : int):
	current_stage = stage
	phase_timer.wait_time = _stages[stage]["delay"] / difficulty
	phase_timer.one_shot = false
	phase_timer.start()
	stage_started.emit(stage)

func stop_phase(_phase : Enums.PHASE):
	_running = false
	phase_timer.stop()
	difficulty_timer.stop()

# public
func start_endless():
	_next_endless_boss = elapsed + ENDLESS_BOSS_EVERY
	start_phase(Enums.PHASE.Endless)

# public
func on_boss_killed():
	_boss_alive = false

# public
func is_boss_alive() -> bool:
	return _boss_alive

# public - debug helper, jumps the clock forward
func skip_time(seconds : float):
	elapsed += seconds

# public
func get_max_alive() -> int:
	return _stages[current_stage]["max_alive"] + _endless_steps * ENDLESS_MAX_ALIVE_STEP

# public
func get_time_text() -> String:
	var seconds = int(elapsed)
	return "%02d:%02d" % [seconds / 60, seconds % 60]

# public
func get_phase_name() -> String:
	return get_time_text()

func _request_boss():
	_boss_alive = true
	boss_requested.emit()

func on_phase_timer_timeout():
	var result = []
	for entry in _stages[current_stage]["wave"]:
		if randi_range(0, 99) >= entry[2]:
			continue
		var step = PhaseTimeoutResult.new()
		step.enemy = entry[0]
		step.count = entry[1]
		result.append(step)

	if result.size() > 0:
		phase_timeout.emit(result)

func on_difficulty_timer_timeout():
	_endless_steps += 1
	difficulty += DIFFICULTY_STEP
	phase_timer.wait_time = _stages[current_stage]["delay"] / difficulty
	difficulty_changed.emit(difficulty)

class PhaseTimeoutResult:
	var enemy : Enums.ENEMIES
	var count : int
