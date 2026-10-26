extends Node

# Run structure: Phase1..Phase5 advance by score, then the Boss,
# after the boss is killed the run continues in Endless mode
# with difficulty growing over time and the boss coming back.

const DIFFICULTY_STEP = 0.15
const DIFFICULTY_INTERVAL = 60.0
const ENDLESS_MAX_ALIVE_STEP = 2
const ENDLESS_BOSS_EVERY = 20000

var current_phase = Enums.PHASE.Phase1
var difficulty : float = 1.0

var phase_timer = Timer.new()
var difficulty_timer = Timer.new()

var _next_endless_boss_score = 0
var _endless_steps = 0
var _boss_alive = false

signal phase_started(phase : Enums.PHASE, phase_name : String)
signal phase_timeout(value : Array)
signal boss_requested
signal difficulty_changed(value : float)

# score_to_next = -1 means the phase is not finished by score
var _phases : Dictionary = {
	Enums.PHASE.Phase1 : {
		"name" : "Phase 1", "score_to_next" : 1000, "delay" : 1.5, "max_alive" : 6,
		"wave" : [[Enums.ENEMIES.SCOUT, 1]] },
	Enums.PHASE.Phase2 : {
		"name" : "Phase 2", "score_to_next" : 2000, "delay" : 1.5, "max_alive" : 8,
		"wave" : [[Enums.ENEMIES.SCOUT, 2]] },
	Enums.PHASE.Phase3 : {
		"name" : "Phase 3", "score_to_next" : 4000, "delay" : 2.0, "max_alive" : 10,
		"wave" : [[Enums.ENEMIES.SCOUT, 2], [Enums.ENEMIES.GUARD, 1]] },
	Enums.PHASE.Phase4 : {
		"name" : "Phase 4", "score_to_next" : 7000, "delay" : 3.0, "max_alive" : 10,
		"wave" : [[Enums.ENEMIES.HUNTER, 1], [Enums.ENEMIES.SCOUT, 1]] },
	Enums.PHASE.Phase5 : {
		"name" : "Final phase", "score_to_next" : 10000, "delay" : 5.0, "max_alive" : 12,
		"wave" : [[Enums.ENEMIES.SCOUT, 3], [Enums.ENEMIES.HUNTER, 1], [Enums.ENEMIES.GUARD, 1]] },
	Enums.PHASE.Boss : {
		"name" : "Boss", "score_to_next" : -1, "delay" : 0.0, "max_alive" : 10,
		"wave" : [] },
	Enums.PHASE.Endless : {
		"name" : "Endless", "score_to_next" : -1, "delay" : 5.0, "max_alive" : 12,
		"wave" : [[Enums.ENEMIES.SCOUT, 3], [Enums.ENEMIES.HUNTER, 1], [Enums.ENEMIES.GUARD, 1]] },
}

func _ready() -> void:
	phase_timer.connect("timeout", on_phase_timer_timeout)
	add_child(phase_timer)

	difficulty_timer.wait_time = DIFFICULTY_INTERVAL
	difficulty_timer.connect("timeout", on_difficulty_timer_timeout)
	add_child(difficulty_timer)

func start_phase(phase : Enums.PHASE):
	stop_phase(current_phase)
	current_phase = phase
	var data = _phases[phase]

	if data["delay"] > 0:
		phase_timer.wait_time = data["delay"] / difficulty
		phase_timer.one_shot = false
		phase_timer.start()

	if phase == Enums.PHASE.Endless:
		difficulty_timer.start()

	phase_started.emit(phase, data["name"])

	if phase == Enums.PHASE.Boss:
		_request_boss()

func stop_phase(_phase : Enums.PHASE):
	phase_timer.stop()
	difficulty_timer.stop()

# public - called on every score change
func check_score(score : int):
	while _phases[current_phase]["score_to_next"] != -1 and score >= _phases[current_phase]["score_to_next"]:
		start_phase((current_phase + 1) as Enums.PHASE)

	if current_phase == Enums.PHASE.Endless and !_boss_alive and score >= _next_endless_boss_score:
		_next_endless_boss_score += ENDLESS_BOSS_EVERY
		_request_boss()

# public
func start_endless(score : int):
	_next_endless_boss_score = score + ENDLESS_BOSS_EVERY
	start_phase(Enums.PHASE.Endless)

# public
func on_boss_killed():
	_boss_alive = false

# public
func get_max_alive() -> int:
	return _phases[current_phase]["max_alive"] + _endless_steps * ENDLESS_MAX_ALIVE_STEP

# public
func get_phase_name() -> String:
	return _phases[current_phase]["name"]

func _request_boss():
	_boss_alive = true
	boss_requested.emit()

func on_phase_timer_timeout():
	var result = []
	for entry in _phases[current_phase]["wave"]:
		var step = PhaseTimeoutResult.new()
		step.enemy = entry[0]
		step.count = entry[1]
		result.append(step)

	if result.size() > 0:
		phase_timeout.emit(result)

func on_difficulty_timer_timeout():
	_endless_steps += 1
	difficulty += DIFFICULTY_STEP
	phase_timer.wait_time = _phases[current_phase]["delay"] / difficulty
	difficulty_changed.emit(difficulty)

class PhaseTimeoutResult:
	var enemy : Enums.ENEMIES
	var count : int
