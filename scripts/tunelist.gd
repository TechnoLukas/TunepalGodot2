extends Control

@onready var item_list = $SectionWithMargin/ScrollContainer/ListContainer
@onready var item = $SectionWithMargin/ScrollContainer/ListContainer/list_item

var item_data = {}

signal show_tune_page(data)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func add_item(data, percentage=""):
	var new_item = item.duplicate()
	item_list.add_child(new_item)
	
	var title_label = item.find_child("title_label")
	var alt_title = item.find_child("alt_title")
	var percent_label = item.find_child("percent_label")
	var source = item.find_child("source")
	var tune_type = item.find_child("tune_type")
	
	
	title_label.text=data["accented_title"]
	if "confidence" in data: 		
		percent_label.visible=true
		percent_label.text = str(data["confidence"]) + "%"
	else:
		percent_label.visible=false
	new_item.get_node("button").pressed.connect(_button_pressed.bind(new_item.get_node("button"))) #.connect("pressed", self, "_button_pressed",[new_item.get_node("button")])
	
	alt_title.text = format_text(data["alt_title"])
	source.text = format_text(data["sourcename"])
	tune_type.text = format_text(data["tune_type"]) + " in " + format_text(data["key_sig"])

	item_data[new_item] = data 
	new_item.visible=true
	
func format_text(txt):
	if txt == null:
		return ""
	else:
		return str(txt)
	
func _button_pressed(which):
	var data = item_data[which.get_parent()]
	print(data)
	show_tune_page.emit(data)
	

	
func clear_list():
	for i in range(1,item_list.get_children().size()):
		item_list.get_children()[i].queue_free()
	item_data={}
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
