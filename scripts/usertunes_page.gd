extends Control

@onready var tunelist = $TunesList
@onready var tunepage = $Tunepage
@onready var open_file_dialog = $FileDialog_Open
@onready var save_file_dialog = $FileDialog_Save
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func showpage():
	update_list()
	self.visible = true


func hidepage():
	self.visible = false
	
func update_list():
	tunelist.clear_list()
	var data = sqlite.user_tunes
	for i in range(0,data.size()):
		tunelist.add_item(data[i])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_tunepage_returned() -> void:
	update_list()


func _on_save_button_pressed() -> void:
	save_file_dialog.visible = true


func _on_open_button_pressed() -> void:
	open_file_dialog.visible = true

func _on_file_dialog_open_file_selected(path: String) -> void:
	print("opened: ",path)
	#if path.split(".")[-1]=="db":
	#	sqlite.user_tunes=sqlite.load_db(path)
	#	update_list()
	if path.split(".")[-1]=="json":
		sqlite.open_json(path)
		update_list()


func _on_file_dialog_save_file_selected(path: String) -> void:
	print("saved: ",path)
	#if path.split(".")[-1]=="db":
	#	sqlite.save_db(path)
	if path.split(".")[-1]=="json":
		sqlite.save_json(path)
