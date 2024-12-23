extends Control

# Main menu elements
@onready var menu_button = $Container/container/menu_button
@onready var menu = $Menu
@onready var lable = $Container/container/label
var title = ""

# Swipe Animation Variables
@onready var deselect_button = $deselect_button
var swipe_right_speed = 4
var swipe_left_speed = 6
var current_menu_position = Vector2()
var action = "" # swipe_right & swipe_left
var transparency = 0.5 # transparency 1.0 to 0.5
var t = 0.0

# Page selection Variables
var pagenames = {
				"record":{"node":"RecordPage","title":"Record"},
				"keyword":{"node":"KeywordPage","title":"Search Tune"},
				"randomtune":{"node":"RandomtunePage","title":"Random Tune"},
				"usertunes":{"node":"UsertunesPage","title":"My Tunes"}, 
				}

func _ready() -> void:
	open_page("record")
	OS.request_permissions()
	
func update_title():
	lable.text = title

func set_color(button_transparency):
	var style = StyleBoxFlat.new()
	style.bg_color=Color(0.0,0.0,0.0,button_transparency)
	deselect_button.add_theme_stylebox_override("normal",style)
	deselect_button.add_theme_stylebox_override("hover",style)
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
		
func open_menu():
	menu_button.disabled = true
	deselect_button.disabled=false
	deselect_button.mouse_filter = MouseFilter.MOUSE_FILTER_STOP
	if t!=0: t = 1.0-t
	action = "swipe_right"
	
func close_menu():
	menu_button.disabled = false
	deselect_button.disabled=true
	deselect_button.mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE
	if t!=0: t = 1.0-t
	action = "swipe_left"
	
func open_page(string):
	var pages = get_parent().find_child("pages").get_children()
	for page in pages:
		if page.name == pagenames[string]["node"]:
			#page.visible = true
			page.showpage()
			title = pagenames[string]["title"]
			update_title()
		else:
			#page.visible = false
			page.hidepage()
	
	
func _process(delta: float) -> void:
	swipe_actions(delta)



func _on_menu_button_pressed() -> void:
	open_menu()
	
func _on_deselect_button_pressed() -> void:
	close_menu()

func _on_record_scene_button_pressed() -> void:
	close_menu()
	open_page("record")

func _on_keyword_scene_button_pressed() -> void:
	close_menu()
	open_page("keyword")

func _on_randomtune_scene_button_pressed() -> void:
	close_menu()
	open_page("randomtune")

func _on_usertunes_scene_button_pressed() -> void:
	close_menu()
	open_page("usertunes")

func _on_settings_scene_button_pressed() -> void:
	close_menu()

func _on_help_scene_button_pressed() -> void:
	close_menu()

func _on_about_scene_button_pressed() -> void:
	close_menu()
