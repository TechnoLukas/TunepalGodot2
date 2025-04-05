extends Node2D

var angle = 0.0

func _draw() -> void:
	#if action == "recording":
	draw_arc($"../background".size/2, 110, deg_to_rad(-90), deg_to_rad(-90+angle), 128, Color.WHITE,10.0,true)

func _process(_delta: float) -> void:
	queue_redraw()
