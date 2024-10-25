extends ScrollContainer

@export var delta_for_swipe := Vector2(8, 8) 

var look_for_swipe := false
var swiping := false
var swipe_start : Vector2
var swipe_mouse_start : Vector2
var swipe_mouse_times := []
var swipe_mouse_positions := []
var vertical_drag_threshold = 10

func _ready():
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(ev) -> void:
	if !is_visible_in_tree():
		return
		
	if ev is InputEventScreenDrag and swiping:
		accept_event()
		return
		
	if ev is InputEventMouseButton:
		
		if ev.pressed and get_global_rect().has_point(ev.global_position):
			look_for_swipe = true
			swipe_mouse_start = ev.global_position
			
		elif swiping:
			swipe_mouse_times.append(Time.get_ticks_msec())
			swipe_mouse_positions.append(ev.global_position)
			var source := Vector2(get_h_scroll(), get_v_scroll())
			var idx := swipe_mouse_times.size() - 1
			var now := Time.get_ticks_msec()
			var cutoff := now - 100
			for i in range(swipe_mouse_times.size() - 1, -1, -1):
				if swipe_mouse_times[i] >= cutoff: 
					idx = i
				else: break
			var flick_start : Vector2 = swipe_mouse_positions[idx]
			var flick_dur = min(0.3, (ev.global_position - flick_start).length() / 1000)
			if flick_dur > 0.0:
				var tween = create_tween()
				var delta : Vector2 = ev.global_position - flick_start
				var target = source - delta * flick_dur * 15.0
				tween.tween_property(self,'scroll_horizontal',target.x,flick_dur).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
				tween.parallel().tween_property(self,'scroll_vertical',target.y,flick_dur).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
			swiping = false
			swipe_mouse_times = []
			swipe_mouse_positions = []
		else:
			look_for_swipe = false
			
	if ev is InputEventMouseMotion:
		if swipe_mouse_start.y > ev.global_position.y && swipe_mouse_start.y - ev.global_position.y < vertical_drag_threshold:
			return
			
		if swipe_mouse_start.y < ev.global_position.y && ev.global_position.y - swipe_mouse_start.y < vertical_drag_threshold:
			return
			
		if swipe_mouse_start.y == ev.global_position.y:
			return
			
		if look_for_swipe:
			var delta = ev.global_position - swipe_mouse_start
			if abs(delta.x) > delta_for_swipe.x or abs(delta.y) > delta_for_swipe.y:
				swiping = true
				look_for_swipe = false
				swipe_start = Vector2(get_h_scroll(), get_v_scroll())
				swipe_mouse_start = ev.global_position
				swipe_mouse_times = [Time.get_ticks_msec()]
				swipe_mouse_positions = [swipe_mouse_start]
		
		if swiping:
			var delta : Vector2 = ev.global_position - swipe_mouse_start
			set_h_scroll(swipe_start.x - delta.x)
			set_v_scroll(swipe_start.y - delta.y)
			swipe_mouse_times.append(Time.get_ticks_msec())
			swipe_mouse_positions.append(ev.global_position)
			ev.position = Vector2.ZERO
