extends Control

var stuff
@onready var item_list = $BottomSection/SectionWithMargin/ScrollContainer/ListContainer
@onready var item = $BottomSection/SectionWithMargin/ScrollContainer/ListContainer/list_item
@onready var search_line = $TopSection/SectionWithMargin/group/search_field/line_edit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stuff = sqlite.query_result
	clear_list()
	update_list("")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_item(item, title):
	var new_item = item.duplicate()
	item_list.add_child(new_item)
	new_item.get_node("label").text=title
	new_item.visible=true
	#print(title)

func update_list(text):
	for i in range(0, stuff.size()):
		var title = stuff[i]["title"]
		if search_line.text == "":
			add_item(item, title)
		else:
			if search_line.text in title:
				add_item(item, title)

func clear_list():
	for i in range(1,item_list.get_children().size()):
		item_list.get_children()[i].queue_free()

	
func _on_line_edit_text_changed(new_text: String) -> void:
	pass
	#clear_list()
	#update_list(new_text)

func _on_line_edit_text_submitted(new_text: String) -> void:
	clear_list()
	update_list(new_text)


func _on_close_field_pressed() -> void:
	search_line.text=""
	clear_list()
	update_list("")
	#search_line.emit_signal("text_submitted","")
