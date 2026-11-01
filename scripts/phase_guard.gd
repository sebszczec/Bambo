extends Node

# Run structure (survival clock) of the current level: every minute is a stage
# with its own spawn rate and enemy mix, swarms and an elite come at fixed times
# and the level bosses arrive on schedule. The final boss starts the Boss phase,
# killing it wins the level (game logic).
# Endless mode (dev console only) keeps growing the difficulty and brings bosses back.

const STAGE_LENGTH = 60.0
const DIFFICULTY_STEP = 0.15
const DIFFICULTY_INTERVAL = 60.0
const ENDLESS_MAX_ALIVE_STEP = 10
const ENDLESS_BOSS_EVERY = 300.0
const BOSS_SPAWN_SLOWDOWN = 1.5

var current_phase = Enums.PHASE.Survival
# time of the final boss
var run_length : float = 600.0
var current_stage = 0
var difficulty : float = 1.0
var elapsed : float = 0.0

var phase_timer = Timer.new()
var difficulty_timer = Timer.new()

var _running = false
var _next_swarm = 0.0
var _elite_spawned = false
var _next_endless_boss = 0.0
var _endless_steps = 0
var _boss_alive = false
var _last_second = -1

signal phase_started(phase : Enums.PHASE, phase_name : String)
signal stage_started(stage : int)
signal phase_timeout(value : Array)
signal boss_requested(type : Enums.ENEMIES, is_final : bool)
signal elite_requested
signal swarm_requested(count : int)
signal difficulty_changed(value : float)
signal time_changed(seconds : int)

# stage table, bosses, elite and swarms come from the current level (see Levels)
var _stages : Array = []
var _bosses : Array = []
var _next_boss = 0
var _elite_at = 300.0
var _swarm_every = 90.0
var _swarm_base = 20
var _swarm_per_stage = 3
# endless bosses take turns
var _endless_bosses = [Enums.ENEMIES.BOSS, Enums.ENEMIES.WORM_BOSS]
var _endless_boss_count = 0

var _phase_names : Dictionary = {
	Enums.PHASE.Survival : "Survival",
	Enums.PHASE.Boss : "Boss",
	Enums.PHASE.Endless : "Endless",
}

func _ready() -> void:
	_load_level(Levels.get_current())

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

		if !_elite_spawned and elapsed >= _elite_at:
			_elite_spawned = true
			elite_requested.emit()

		# the next boss waits until the previous one is dead
		if _next_boss < _bosses.size() and !_boss_alive and elapsed >= _bosses[_next_boss]["at"]:
			var entry = _bosses[_next_boss]
			_next_boss += 1
			if entry["final"]:
				start_phase(Enums.PHASE.Boss)
				_request_boss(entry["type"], true)
				return
			_request_boss(entry["type"], false)

	if elapsed >= _next_swarm:
		_next_swarm += _swarm_every
		# no swarms during boss fights
		if current_phase != Enums.PHASE.Boss and !_boss_alive:
			swarm_requested.emit(_swarm_base + _swarm_per_stage * current_stage + 2 * _endless_steps)

	if current_phase == Enums.PHASE.Endless and !_boss_alive and elapsed >= _next_endless_boss:
		_next_endless_boss += ENDLESS_BOSS_EVERY
		_request_boss(_endless_bosses[_endless_boss_count % _endless_bosses.size()], false)
		_endless_boss_count += 1

func _load_level(level : Dictionary):
	_stages = level["stages"]
	_bosses = level["bosses"]
	_elite_at = level["elite_at"]
	_swarm_every = level["swarm_every"]
	_swarm_base = level["swarm_base"]
	_swarm_per_stage = level["swarm_per_stage"]
	_next_swarm = _swarm_every
	for entry in _bosses:
		if entry["final"]:
			run_length = entry["at"]

func start_phase(phase : Enums.PHASE):
	stop_phase(current_phase)
	current_phase = phase
	_running = true

	if phase == Enums.PHASE.Survival:
		_start_stage(0)
	elif phase == Enums.PHASE.Boss:
		_start_stage(_stages.size() - 1)
	elif phase == Enums.PHASE.Endless:
		_start_stage(_stages.size() - 1)
		difficulty_timer.start()

	phase_started.emit(phase, _phase_names[phase])

func _start_stage(stage : int):
	current_stage = stage
	_update_spawn_delay()
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
	_update_spawn_delay()

# public - the final boss of the level is out
func is_final_boss_phase() -> bool:
	return current_phase == Enums.PHASE.Boss

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

func _request_boss(type : Enums.ENEMIES, is_final : bool):
	_boss_alive = true
	_update_spawn_delay()
	boss_requested.emit(type, is_final)

# fewer normal enemies while a boss is fighting
func _update_spawn_delay():
	var wait = _stages[current_stage]["delay"] / difficulty
	if _boss_alive:
		wait *= BOSS_SPAWN_SLOWDOWN
	phase_timer.wait_time = wait

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
	_update_spawn_delay()
	difficulty_changed.emit(difficulty)

class PhaseTimeoutResult:
	var enemy : Enums.ENEMIES
	var count : int
