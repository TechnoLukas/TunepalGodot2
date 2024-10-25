extends Node

@onready var db = SQLite.new()
@onready var db_name
var query_result = []


signal output_received(text)

func _ready():
	if OS.get_name() in ["Android", "iOS", "Web"]:
		db_name = "user://assets/data/tunepal"
		copy_data_to_user()
		print("finished")
	else:
		db_name = "res://assets/data/tunepal"
	
	db.path = db_name
	db.open_db()
	db.read_only = true
	# source = 2 norbeck
	await db.query("select tuneindex.id as id, midi_sequence, tune_type, time_sig, notation, source.id as sourceid, shortName, url, source.source as sourcename, title, alt_title, tunepalid, x, midi_file_name, key_sig, search_key from tuneindex, tunekeys, source where tunekeys.tuneid = tuneindex.id and tuneindex.source = source.id and source.id = 2;")
	query_result = db.query_result
	db.close_db()

func cprint(text : String) -> void:
	print(text)
	emit_signal("output_received", text)

func copy_data_to_user() -> void:
	var original_data_path := "res://assets/data"
	var copy_assets_path := "user://assets"
	var copy_data_path := "user://assets/data"

	DirAccess.make_dir_absolute(copy_assets_path)
	DirAccess.make_dir_absolute(copy_data_path)
	var dir = DirAccess.open(original_data_path)
	
	print(dir.get_files())
	if dir:
		dir.list_dir_begin();
		var file_name = dir.get_next()
		while (file_name != ""):
			if dir.current_is_dir():
				pass
			else:
				cprint("Copying " + file_name + " to /user-folder")
				dir.copy(original_data_path + "/" + file_name, copy_data_path + "/" + file_name)
			file_name = dir.get_next()
	else:
		cprint("An error occurred when trying to access the path.")
