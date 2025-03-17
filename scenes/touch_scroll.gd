extends ScrollContainer


func _on_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion && event.button_mask == 1:
		var hbar = get_h_scroll_bar()
		hbar.value += event.relative.x
	print(event)
	pass # Replace with function body.
