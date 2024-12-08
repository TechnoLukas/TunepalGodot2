extends Control

@onready var tunelist = $MiddleSection/TunesList

func _on_return_button_pressed() -> void:
	visible = false

func load_tunelist(list):
	tunelist.clear_list()
	for i in range(len(list)):
		tunelist.add_item(list[i])
