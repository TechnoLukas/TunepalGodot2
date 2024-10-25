extends Control

var stuff
@onready var item_list = $BottomSection/SectionWithMargin/ScrollContainer/ListContainer
@onready var item = $BottomSection/SectionWithMargin/ScrollContainer/ListContainer/list_item

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stuff = sqlite.query_result
	for i in range(0, stuff.size()):
		var title = stuff[i]["title"]
		var new_item = item.duplicate()
		item_list.add_child(new_item)
		new_item.get_node("label").text=title
		new_item.visible=true
		print(title)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
