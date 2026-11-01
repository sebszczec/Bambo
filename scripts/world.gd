extends Node2D

@onready var _backdrop : Sprite2D = $ParallaxBackground/Sprite2D
@onready var _layers : Dictionary = {
	"far" : $ParallaxBackground/SmallPlanets,
	"mid" : $ParallaxBackground/MediumPlanets,
	"near" : $ParallaxBackground/LargePlanets,
}

func _ready() -> void:
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
