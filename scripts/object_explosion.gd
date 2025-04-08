extends Node2D

var fragmentScene = preload("res://scenes/object_fragment.tscn")

@export var PathToSprite : String = "res://resources/kenney_particle_pack/window_04.png"
@export var SpriteTexture : Texture2D = null

@onready var effect = $ExplosionEffect

var _obj : Array[Sprite2D] = []
var _h_frames = 5
var _v_frames = 5
var _all_frames = _h_frames * _v_frames
var _h_offset : float = 0
var _w_offset : float = 0
var _h_pixels : float = 0
var _w_pixels : float = 0
var _h_pixels_half : float = 0
var _w_pixels_half : float = 0
var _velocity : Array[Vector2] = []
var _rotation : Array[float] = []
var _transparency : Array[float] = []
var _friction = 0.05
var _rad_fricton = 0.00
var _alpha_friciton = 0.005
var _speed = 500

var _explode = false

func _ready() -> void:
	pass

func init():
	for i in range(_all_frames): 
		var tmp : Sprite2D = fragmentScene.instantiate()
		if SpriteTexture == null:
			tmp.texture = load(PathToSprite)
		else:
			tmp.texture = SpriteTexture
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
	
	_calculate_offset()
	
	var frame = 0
	for i in range(_h_frames):
		for j in range(_v_frames):
			var tmp = _obj[frame]
			tmp.position = Vector2((j + 0.5) * _w_offset - _w_pixels_half, (i + 0.5) * _h_offset - _h_pixels_half)
			frame += 1
	

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
		

func _calculate_offset():
	_h_offset = float(_obj[0].texture.get_height()) / _h_frames
	_w_offset = float(_obj[0].texture.get_width()) / _v_frames
	_h_pixels = _obj[0].texture.get_height()
	_w_pixels = _obj[0].texture.get_width()
	_h_pixels_half = _h_pixels / 2
	_w_pixels_half = _w_pixels / 2
	
func explode():
	_explode = true
	effect.emitting = true
	

func set_particle_color(color : Color) -> void:
	effect.self_modulate = color
	
