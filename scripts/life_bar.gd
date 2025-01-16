extends ProgressBar

var style = StyleBoxFlat.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_theme_stylebox_override("fill", style)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func setMaxValue(val):
	self.max_value = val
	
func setValue(val):
	self.value = val

func setColor(color: Color):
	style.bg_color = color
