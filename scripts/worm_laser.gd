extends Node2D

# Laser of the worm boss. It points down (+Y) from where it is placed.
# A thin flickering warning line comes first, then a wide beam
# that hurts the player for as long as they stay inside it.

@export var Length : float = 1500.0
@export var Width : float = 44.0
@export var Damage : int = 22
@export var DamageTickTime : float = 0.15

@onready var warning = $Warning
@onready var beam = $Beam
@onready var core = $Core
@onready var muzzle = $Muzzle
@onready var sparks = $Sparks
@onready var hurt_box = $HurtBox
@onready var hurt_shape = $HurtBox/CollisionShape2D
@onready var audio = $AudioStreamPlayer2D

var _player = null
var _player_inside = false
var _firing = false
var _damaging = false
var _tick = 0.0
var _time = 0.0
# 0..1, opens and closes the beam
var _intensity = 0.0
# bumped by stop(), a running fire() sequence quits when it changes
var _sequence = 0
var _timer = Timer.new()

signal beam_started
signal finished

func _ready() -> void:
	visible = false
	_timer.one_shot = true
	add_child(_timer)
	for line in [warning, beam, core]:
		line.points = PackedVector2Array([Vector2.ZERO, Vector2(0, Length)])

	var shape = RectangleShape2D.new()
	shape.size = Vector2(Width * 0.6, Length)
	hurt_shape.shape = shape
	hurt_shape.position = Vector2(0, Length / 2)
	hurt_shape.disabled = true

	hurt_box.connect("area_entered", _on_hurt_box_area_entered)
	hurt_box.connect("area_exited", _on_hurt_box_area_exited)

func _physics_process(delta: float) -> void:
	if !visible:
		return

	_time += delta
	if !_firing:
		# warning line flickers faster and faster
		warning.modulate.a = 0.45 + 0.45 * sin(_time * (20.0 + _time * 30.0))
		return

	var pulse = (1.0 + 0.12 * sin(_time * 45.0)) * _intensity
	beam.width = Width * pulse
	core.width = Width * 0.32 * pulse
	muzzle.scale = Vector2.ONE * 0.18 * pulse

	if !_damaging or !_player_inside or !is_instance_valid(_player):
		return

	_tick -= delta
	if _tick <= 0:
		_tick = DamageTickTime
		_player.take_damage(Damage)

# public - runs the whole warning, fire and fade sequence
func fire(charge_time : float, fire_time : float):
	_sequence += 1
	var sequence = _sequence
	_time = 0.0
	_tick = 0.0
	visible = true
	warning.visible = true
	beam.visible = false
	core.visible = false
	muzzle.visible = false
	warning.width = 3.0
	create_tween().tween_property(warning, "width", 9.0, charge_time)

	await _wait(charge_time)
	if sequence != _sequence:
		return

	warning.visible = false
	beam.visible = true
	core.visible = true
	muzzle.visible = true
	sparks.emitting = true
	_intensity = 0.0
	create_tween().tween_property(self, "_intensity", 1.0, 0.1)
	audio.play()
	_firing = true
	_damaging = true
	hurt_shape.set_deferred("disabled", false)
	beam_started.emit()

	await _wait(fire_time)
	if sequence != _sequence:
		return

	# the beam keeps pulsing while it fades but does not hurt anymore
	_damaging = false
	sparks.emitting = false
	hurt_shape.set_deferred("disabled", true)
	var fade = create_tween()
	fade.tween_property(self, "_intensity", 0.0, 0.25)
	await fade.finished
	if sequence != _sequence:
		return

	_firing = false
	visible = false
	finished.emit()

func _wait(seconds : float):
	_timer.start(seconds)
	await _timer.timeout

# public - cuts the beam at once (boss died)
func stop():
	_sequence += 1
	_timer.stop()
	_firing = false
	_damaging = false
	sparks.emitting = false
	hurt_shape.set_deferred("disabled", true)
	visible = false

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		_player = area.get_parent()
		_player_inside = true

func _on_hurt_box_area_exited(area: Area2D) -> void:
	if area.is_in_group("Player"):
		_player_inside = false
