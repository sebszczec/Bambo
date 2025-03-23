extends ProgressBar

var style = StyleBoxFlat.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_theme_stylebox_override("fill", style)


func setMaxValue(val : int):
	self.max_value = val
	
func setValue(val : int):
	self.value = val

func setColor(color: Color):
	style.bg_color = color
