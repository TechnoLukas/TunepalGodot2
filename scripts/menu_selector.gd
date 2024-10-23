extends Control

@onready var menu_button = $Container/container/menu_button
@onready var deselect_button = $deselect_button
@onready var menu = $Menu
@onready var lable = $Container/container/label

@export var title = ""

var swipe_right_speed = 4
var swipe_left_speed = 6

var current_menu_position = Vector2()
var action = "" # swipe_right & swipe_left

# transparency 1.0 to 0.2
var transparency = 0.5

var t = 0.0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lable.text = title

func set_color(tr):
	var style = StyleBoxFlat.new()
	style.bg_color=Color(0.0,0.0,0.0,tr)
	deselect_button.add_theme_stylebox_override("normal",style)
	deselect_button.add_theme_stylebox_override("hover",style)
	#deselect_button.add_theme_stylebox_override("focus",style)
	deselect_button.add_theme_stylebox_override("pressed",style)
	deselect_button.add_theme_stylebox_override("disabled",style)
	
func swipe_actions(delta):
	if action == "swipe_right":
		if t<1:
			t += delta * swipe_right_speed
			var eased_t = 1 - pow(1 - t, 3)
			menu.position = lerp(Vector2(-200,0), Vector2(0,0), eased_t)
			menu.position = menu.position.round()
			set_color(transparency*t)
		else:
			menu.position=Vector2(0,0)
			action = ""
		
	elif action == "swipe_left":
		if t<1:
			t += delta * swipe_left_speed
			var eased_t = pow(t, 3)
			menu.position = lerp(Vector2(0,0), Vector2(-200,0), eased_t)#current_menu_position.lerp(Vector2(0,0), t)
			menu.position = menu.position.round()
			set_color(transparency*(1-t))
		else:
			menu.position=Vector2(-200,0)
			action = ""
	else:
		t = 0.0	
	
func _process(delta: float) -> void:
	swipe_actions(delta)
			
func _on_menu_button_pressed() -> void:
	open_menu()
	
func _on_deselect_button_pressed() -> void:
	close_menu()
	
func open_menu():
	menu_button.disabled = true
	deselect_button.disabled=false
	if t!=0: t = 1.0-t
	action = "swipe_right"
	
func close_menu():
	menu_button.disabled = false
	deselect_button.disabled=true
	if t!=0: t = 1.0-t
	action = "swipe_left"


func _on_record_scene_button_pressed() -> void:
	close_menu()

func _on_keyword_scene_button_pressed() -> void:
	close_menu()

func _on_randomtune_scene_button_pressed() -> void:
	close_menu()

func _on_settings_scene_button_pressed() -> void:
	close_menu()

func _on_help_scene_button_pressed() -> void:
	close_menu()

func _on_about_scene_button_pressed() -> void:
	close_menu()
