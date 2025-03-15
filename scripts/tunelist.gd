extends Control

@onready var item_list = $SectionWithMargin/ScrollContainer/ListContainer
@onready var item = $SectionWithMargin/ScrollContainer/ListContainer/list_item


signal show_tune_page(data)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


var item_data = []


func add_item(data, percentage=""):
	var new_item:Container = item.duplicate()
	item_list.add_child(new_item)
	
	var title_label = new_item.get_node("HBoxContainer/title_label")
	var alt_title = new_item.get_node("alt_title")
	var percent_label = new_item.get_node("HBoxContainer/percent_label")
	var source = new_item.get_node("h_container/source")
	var tune_type:Label = new_item.get_node("h_container/tune_type")
	
	tune_type.add_theme_color_override("font_color", RecordIndicator.tunepal_color)
	
	new_item.gui_input.connect(_on_list_item_gui_input.bind(item_data.size()))
	title_label.text=data["accented_title"]
	if "confidence" in data: 		
		percent_label.visible=true
		percent_label.text = str(data["confidence"]) + "%"
	else:
		percent_label.visible=false
	alt_title.text = format_text(data["alt_title"])
	source.text = format_text(data["sourcename"])
	tune_type.text = format_text(data["tune_type"]) + " in " + format_text(data["key_sig"])

	item_data.append(data) 
	new_item.visible=true
	
func format_text(txt):
	if txt == null:
		return ""
	else:
		return str(txt)
	
	
func clear_list():
	for i in range(1,item_list.get_children().size()):
		item_list.get_children()[i].queue_free()
	item_data=[]
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_list_item_gui_input(event: InputEvent, item_id) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_MASK_LEFT:
		
		var data = item_data[item_id]
		print(data)
		show_tune_page.emit(data)
		
		# handle_item_click(item_id, item)
	
	pass # Replace with function body.
