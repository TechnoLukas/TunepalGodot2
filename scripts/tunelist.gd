extends Control

@onready var item_list = $SectionWithMargin/ScrollContainer/ListContainer
@onready var item = $SectionWithMargin/ScrollContainer/ListContainer/list_item

var item_data = {}

signal show_tune_page(data)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func add_item(data):
	var new_item = item.duplicate()
	item_list.add_child(new_item)
	new_item.get_node("label").text=data["accented_title"]
	new_item.get_node("button").pressed.connect(_button_pressed.bind(new_item.get_node("button"))) #.connect("pressed", self, "_button_pressed",[new_item.get_node("button")])
	item_data[new_item] = data 
	new_item.visible=true
	
func _button_pressed(which):
	var data = item_data[which.get_parent()]
	show_tune_page.emit(data)
	

	
func clear_list():
	for i in range(1,item_list.get_children().size()):
		item_list.get_children()[i].queue_free()
	item_data={}
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
