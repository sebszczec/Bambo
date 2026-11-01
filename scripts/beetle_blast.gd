extends Node2D

# Boulder Beetle self destruct - layered blast: a refracting shock wave
# (shaders/shockwave.gdshader), a soft flash, sparks, the shell bursting into
# its own plates and legs (beetle_shards.png atlas) and a frozen smoke cloud.
# Lives on the beetle, which stays alive until the smoke has faded.

const WAVE_TIME = 0.45
const FLASH_TIME = 0.25
# hdr, the bloom makes it glow
const FLASH_COLOR = Color(1.6, 2.6, 2.8)

@onready var shockwave = $Shockwave
@onready var flash = $Flash
@onready var sparks = $Sparks
@onready var debris = $Debris
@onready var smoke = $Smoke

func _ready() -> void:
	visible = false

# public - returns how long the effect lasts
func fire(radius : float) -> float:
	visible = true
	var wave = shockwave.material as ShaderMaterial
	wave.set_shader_parameter("radius", radius)
	wave.set_shader_parameter("progress", 0.0)
	shockwave.visible = true

	for particles in [sparks, debris, smoke]:
		particles.restart()
		particles.emitting = true

	flash.modulate = FLASH_COLOR
	var flash_size = radius * 2.0 / flash.texture.get_width()
	flash.scale = Vector2.ONE * flash_size * 0.2

	var tween = create_tween().set_parallel()
	tween.tween_method(_set_progress, 0.0, 1.0, WAVE_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "scale", Vector2.ONE * flash_size * 0.9, 0.08)
	tween.tween_property(flash, "modulate:a", 0.0, FLASH_TIME).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func(): shockwave.visible = false)

	return maxf(smoke.lifetime, debris.lifetime) + 0.1

func _set_progress(value : float):
	(shockwave.material as ShaderMaterial).set_shader_parameter("progress", value)
