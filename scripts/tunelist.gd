extends Control

@onready var item_list = $SectionWithMargin/ScrollContainer/ListContainer
@onready var item = $SectionWithMargin/ScrollContainer/ListContainer/list_item

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func add_item(title):
	var new_item = item.duplicate()
	item_list.add_child(new_item)
	new_item.get_node("label").text=title
	new_item.visible=true
	
func clear_list():
	for i in range(1,item_list.get_children().size()):
		item_list.get_children()[i].queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
