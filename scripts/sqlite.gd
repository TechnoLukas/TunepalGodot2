extends Node
# const ABCTools = preload("res://scripts/ABCTools.gd")

var tunes = []
var user_tunes = []
var default_user_tunes_path = "://assets/data_persistent/user_tunes.json"

var accented_characters = {
	# Acute accents
	r"\\'a": "á", r"\\'A": "Á",
	r"\\'e": "é", r"\\'E": "É",
	r"\\'i": "í", r"\\'I": "Í",
	r"\\'o": "ó", r"\\'O": "Ó",
	r"\\'u": "ú", r"\\'U": "Ú",
	r"\\'n": "ń", r"\\'N": "Ń",
	
	# Grave accents
	r"\\`a": "à", r"\\`A": "À",
	r"\\`e": "è", r"\\`E": "È",
	r"\\`i": "ì", r"\\`I": "Ì",
	r"\\`o": "ò", r"\\`O": "Ò",
	r"\\`u": "ù", r"\\`U": "Ù",
	
	# Circumflex accents
	r"\\^a": "â", r"\\^A": "Â",
	r"\\^e": "ê", r"\\^E": "Ê",
	r"\\^i": "î", r"\\^I": "Î",
	r"\\^o": "ô", r"\\^O": "Ô",
	r"\\^u": "û", r"\\^U": "Û",
	
	# Umlauts / diaeresis
	r'\\"a': "ä", r'\\"A': "Ä",
	r'\\"e': "ë", r'\\"E': "Ë",
	r'\\"i': "ï", r'\\"I': "Ï",
	r'\\"o': "ö", r'\\"O': "Ö",
	r'\\"u': "ü", r'\\"U': "Ü",
	r'\\"y': "ÿ", r'\\"Y': "Ÿ",
	
	# Tilde accents
	r"\\~a": "ã", r"\\~A": "Ã",
	r"\\~n": "ñ", r"\\~N": "Ñ",
	r"\\~o": "õ", r"\\~O": "Õ",
	
	# Special symbols
	r"{\\aa}": "å", r"{\\AA}": "Å",
	r"{\\o}": "ø", r"{\\O}": "Ø",
	r"{\\ae}": "æ", r"{\\AE}": "Æ",
	r"{\\ss}": "ß",
}

# const THESESSION_URL = "https://thesession.org/tunes/" # "https://raw.githubusercontent.com/adactio/TheSession-data/refs/heads/main/json/tunes.json"
const session_base_url = "https://thesession.org/tunes/" # x/abc"

const create_query = """
	CREATE TABLE IF NOT EXISTS tuneindex (
		id INTEGER NOT NULL PRIMARY KEY,
		tunepalid VARCHAR(500),
		file_name VARCHAR(255),
		x INTEGER,
		notation VARCHAR(10240),
		title VARCHAR(500),
		alt_title VARCHAR(500),
		source INTEGER NOT NULL,
		tune_type VARCHAR(50),
		key_sig VARCHAR(20),
		downloaded INTEGER,
		time_sig VARCHAR(255),
		FOREIGN KEY (source) REFERENCES source(id)
	);
"""

const create_keys_query = """
	CREATE TABLE IF NOT EXISTS tunekeys (
		id INTEGER PRIMARY KEY,
		search_key TEXT,
		tuneid INTEGER,
		midi_file_name TEXT,
		parsons TEXT,
		midi_sequence TEXT,
		FOREIGN KEY (tuneid) REFERENCES tuneindex(id)
	);
"""
const create_source_query = """
	CREATE TABLE IF NOT EXISTS source (
		id INTEGER PRIMARY KEY,
		source VARCHAR(100),
		extra VARCHAR(1000),
		url VARCHAR(1024),
		shortName VARCHAR(1024)
	);
"""

func _ready():
	var path = clientside.prefix + "://assets/data/tunepal.db"
	# verify_db_writeable()
	tunes = load_db(path)

	open_json(clientside.prefix + default_user_tunes_path)

func load_db(path):
	var return_tune = []
	var db = SQLite.new()
	db.path = path
	db.open_db()
	db.query(create_query)
	db.query(create_keys_query)
	db.query(create_source_query)
	db.read_only = true

	db.query("SELECT COUNT(*) as count FROM tuneindex;")
	var count_result = db.query_result
	if count_result.size() > 0:
		print("Database contains " + str(count_result[0]["count"]) + " tunes")
		
		db.query("""
				select tuneindex.id as id, 
				midi_sequence, 
				tune_type, 
				time_sig, 
				notation, 
				source.id as sourceid, 
				shortName, 
				url, 
				source.source as sourcename, 
				title, 
				alt_title, 
				tunepalid, 
				x, 
				midi_file_name, 
				key_sig, 
				search_key from tuneindex, 
				tunekeys, 
				source where tunekeys.tuneid = tuneindex.id and tuneindex.source = source.id;
				""")
	return_tune = db.query_result
	db.close_db()
	
	if return_tune.size() != 0 and (not ("accented_title" in return_tune[0])):
		for i in range(0, return_tune.size()):
			var title = return_tune[i]["title"]
			for character in accented_characters:
				if character in title:
					title = title.replace(character, accented_characters[character])
			return_tune[i]["accented_title"] = title
	else:
		print("No tunes detected in database")

	return return_tune
### for USER TUNES ###
func save_json(path: String) -> void:
	var json_string = JSON.stringify(user_tunes) # Convert array to JSON string
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file.is_open():
		file.store_string(json_string)
	else:
		print("Failed to open file for writing: ", file)

	file.close()
	
func open_json(path: String) -> void:
	var json = JSON.new()
	
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()

	if file.is_open():
		var error = json.parse(content)
		if error == OK:
			user_tunes = json.data
		else:
			print("JSON Parse Error: ", json.get_error_message(), " in ", content, " at line ", json.get_error_line())
	else:
		print("Failed to open file for reading: ", file)

	file.close()

func _on_build_db_button_pressed():
	show_directory_select_dialog()

func show_directory_select_dialog():
	var dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.title = "Select ABC Source Directory"

	# connect directory selected signal
	dialog.dir_selected.connect(_on_directory_selected)
	dialog.canceled.connect(func(): ("Directory selection canceled"))

	add_child(dialog)
	dialog.popup_centered(Vector2(100, 600))

# callback when directory is selected

func _on_directory_selected(path: String):
	print("Selected Directory: ", path)
	ABCImporter.import_files_from_directory(path)
