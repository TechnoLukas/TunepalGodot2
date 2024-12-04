extends Control

var stuff
@onready var tunelist = $TunesList
@onready var search_line = $TopSection/SectionWithMargin/group/search_field/line_edit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stuff = sqlite.tunes
	tunelist.clear_list()
	var time1 = Time.get_ticks_msec()
	
	update_list("")
	var time2 = Time.get_ticks_msec()
	print("time: ",time2-time1)
	
func showpage():
	self.visible = true
	
func hidepage():
	self.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func update_list(text):
	for i in range(0, stuff.size()):
		var title = stuff[i]["accented_title"]
		var alt_title = stuff[i]["alt_title"]

		if search_line.text == "":
			tunelist.add_item(stuff[i])
		else:
			if (search_line.text in title) or (alt_title!=null and (search_line.text in alt_title)):
				tunelist.add_item(stuff[i])

func _on_line_edit_text_submitted(new_text: String) -> void:
	tunelist.clear_list()
	update_list(new_text)


func _on_close_field_pressed() -> void:
	search_line.text=""
	tunelist.clear_list()
	update_list("")
	#search_line.emit_signal("text_submitted","")
