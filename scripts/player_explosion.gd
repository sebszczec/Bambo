extends Node2D

var fragmentScene = preload("res://scenes/player_fragment.tscn")

var _obj : Array[Sprite2D] = []
var _h_frames = 5
var _v_frames = 5
var _all_frames = 25
var _h_pixels = 512
var _v_pixels = 512
var _h_offset : float = float(_h_pixels) / float (_h_frames)
var _v_offset : float = float(_v_pixels) / float (_v_frames)
var _scale = 0.05
var _velocity : Array[Vector2] = []
var _rotation : Array[float] = []
var _transparency : Array[float] = []
var _friction = 0.05
var _rad_fricton = 0.05
var _alpha_friciton = 0.005
var _speed = 300

var _explode = false

func _ready() -> void:
	for i in range(_all_frames): 
		var tmp : Sprite2D = fragmentScene.instantiate()
		tmp.set_frame(i)
		_obj.append(tmp)
		add_child(tmp)
		var v = Vector2(randf_range(-1, 1), randf_range(-1, 1))
		v = v.normalized()
		v = v * _speed
		_velocity.append(v)
		var r = randf_range(-PI, PI)
		_rotation.append(r)
		_transparency.append(1)
	
	var frame = 0
	for i in range(_h_frames):
		for j in range(_v_frames):
			var tmp = _obj[frame]
			tmp.position = Vector2(j * _h_offset, i * _v_offset)
			frame += 1

	scale = Vector2(_scale, _scale)
	modulate = Color.BLUE
	

func _process(delta: float) -> void:
	if _explode:
		for i in range(_all_frames):
			_velocity[i] = _velocity[i].move_toward(Vector2(0, 0), _friction)
			_obj[i].position += _velocity[i] * delta
			
			_rotation[i] = move_toward(_rotation[i], 0, _rad_fricton)
			_obj[i].rotate(_rotation[i])
			
			_transparency[i] = move_toward(_transparency[i], 0, _alpha_friciton)
			_obj[i].modulate.a = _transparency[i]
	else:
		return
		
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_zoom"):
		_explode = true
