class_name TuneList 
extends Control

var volume:float=0
var lerped_volume:float=0

var spectrum

static var tunepal_color:Color = Color(176 / 255.0, 210 / 255.0, 13 / 255.0);

var recording  = false

func _ready() -> void:
	spectrum = AudioServer.get_bus_effect_instance(1, 1)
	
@onready var background = $"../../../../background"

func _draw() -> void:
	var border = 100
	var radius = 120
	if ! recording:
		lerped_volume = 0 
	draw_circle(Vector2.ZERO, radius + 10 + (border * lerped_volume), tunepal_color, true)
	draw_circle(Vector2.ZERO, radius,background.color , true)


func _process(delta: float) -> void:
	volume = spectrum.get_magnitude_for_frequency_range(0, 10000).length()
	lerped_volume = lerp(lerped_volume, volume, delta * 5)
	# print(volume)
	queue_redraw()
