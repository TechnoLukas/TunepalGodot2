extends ScrollContainer

var score_or_abc:bool = true

func _on_color_rect_gui_input(event: InputEvent) -> void:
	var abc = $ColorRect/abc_field
	var score = $ColorRect/abc_score
	
	if event is InputEventMouseMotion && event.button_mask == 1 && event.is_pressed() == false:
		var hbar = get_h_scroll_bar()
		hbar.value -= event.relative.x
		var vbar = get_v_scroll_bar()
		vbar.value -= event.relative.y
	if event is InputEventMouseButton && event.button_mask == 1 && event.double_click :
		print(event)
		var s = get_viewport_rect()
		if score_or_abc:
			$ColorRect/abc_field.visible = true
			$ColorRect/abc_score.visible = false
		else:
			$ColorRect/abc_field.visible = false
			$ColorRect/abc_score.visible = true
		score_or_abc = ! score_or_abc				
	# print(event)
	pass # Replace with function body.
