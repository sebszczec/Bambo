extends Node2D

@onready var _backdrop : Sprite2D = $ParallaxBackground/Sprite2D
@onready var _layers : Dictionary = {
	"far" : $ParallaxBackground/SmallPlanets,
	"mid" : $ParallaxBackground/MediumPlanets,
	"near" : $ParallaxBackground/LargePlanets,
}

@onready var _music : AudioStreamPlayer2D = $Player/AudioStreamPlayer2D2

func _ready() -> void:
	_apply_music()
	var background = Levels.get_current().get("background", {})
	if background.is_empty():
		return

	# the layers keep motion scale and mirroring from the scene, only the art changes
	_backdrop.texture = load(background["base"])
	for key in _layers:
		var layer : ParallaxLayer = _layers[key]
		var brightness = background.get("brightness", {})
		if brightness.has(key):
			var v = brightness[key]
			layer.modulate = Color(v, v, v)
		for child in layer.get_children():
			child.free()
		for entry in background.get(key, []):
			var sprite = Sprite2D.new()
			sprite.texture = load(entry[0])
			sprite.position = entry[1]
			sprite.scale = Vector2(entry[2], entry[2])
			layer.add_child(sprite)

func _apply_music() -> void:
	var path = Levels.get_current().get("music", "")
	if path == "":
		return
	# the player autoplays the scene track before this runs, swap it and restart
	var stream = load(path)
	# *.import files are not committed, so the loop flag can't come from the import settings
	stream.loop = true
	_music.stream = stream
	_music.play()
