extends Node
# const DBBuilder = preload("res://addons/tunepal/bin/tunepal.gdextension")
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

const THESESSION_URL = "https://raw.githubusercontent.com/adactio/TheSession-data/refs/heads/main/json/tunes.json"

# func initialize_database():
# 	var builder = DBBuilder.new()
# 	add_child(builder)
# 	var success = builder.initialize_database()
# 	if success:
# 		success = builder.load_from_url()  # or load_from_file()
# 	builder.queue_free()  # Clean up after initialization
# 	return success

func _ready():

	var success = await build_session_database()
	if success:
		print("Database build successful")
	else:
		print("Database build failed")

	var path = clientside.prefix + "://assets/data/tunepal"
	tunes = load_db(path)
	open_json(clientside.prefix + default_user_tunes_path)

	
func load_db(path):
	var return_tune
	var db = SQLite.new()
	db.path = path
	db.open_db()
	db.read_only = true
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
				source where tunekeys.tuneid = tuneindex.id and tuneindex.source = source.id and source.id = 2;
				""")
	return_tune = db.query_result
	db.close_db()
	
	if return_tune.size()!=0 and (not ("accented_title" in return_tune[0])):
		for i in range(0, return_tune.size()):
			var title = return_tune[i]["title"]
			for character in accented_characters:
				if character in title:
					title=title.replace(character, accented_characters[character])
			return_tune[i]["accented_title"] = title
	
	return return_tune

func save_json(path: String) -> void:
	var json_string = JSON.stringify(user_tunes)  # Convert array to JSON string
	
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

func build_session_database():
	return await build_database_from_url(THESESSION_URL)
	
func build_database_from_url(url: String) -> bool:
	print("Starting database build from URL: ", url) 
	var http_request = HTTPRequest.new() # HTTP request
	add_child(http_request)
	var error = http_request.request(url)
	if error != OK:
		print("Failed to make HTTP request: ", error)
		return false
		
	var result = await http_request.request_completed
	http_request.queue_free()

	if result[0] != OK:
		print("HTTP request failed with code: ", result[0])
		return false
		
	var json_string = result[3].get_string_from_utf8()
	var data = JSON.parse_string(json_string)
	# if not json:
	# 	print("Failed to parse JSON response")
	# 	return false
	# print(json, "JSON parsed successfully")	
	# return populate_database(json)
	# if json.error == OK:
	# 	var data = json.result

	if data == null:
		print("Failed to parse JSON response")
		return false

	if not data is Array:
		print("Unexpected JSON response, expected array")
		return false

	var success = ABCTools.populate_database(data)
	if success:
		print("Database populated successfully")
		return true
	else:
		print("Failed to populate database")
		return false
		
		
		# print("Failed to parse JSON response")
		# return false

	
# func populate_database(data):
# 	var db = SQLite.new()
# 	db.path = clientside.prefix + "://assets/data/tunepal"
# 	db.open_db()
	
# # Begin transaction for better performance
# 	db.query("BEGIN TRANSACTION;")
	
# # Create table if it doesn't exist
# 	var create_table = """
# 	CREATE TABLE IF NOT EXISTS Tunes (
# 		ID INT NOT NULL,
# 		SETTING INT NOT NULL,
# 		NAME TEXT,
# 		TYPE CHAR(50),
# 		MODE CHAR(10),
# 		METER CHAR(10),
# 		ABC TEXT,
# 		KEY TEXT,
# 		PARSED TINYINT,
# 		PCHIST TEXT,
# 		PARSED2 TINYINT,
# 		PRIMARY KEY (ID, SETTING)
# 	);
# 	"""
# 	db.query(create_table)
	
# 	# We need to parse the JSON data and insert it into the database

# 	for tune in data:
# 		var query = """
# 		INSERT OR REPLACE INTO Tunes 
# 		(ID, SETTING, NAME, TYPE, MODE, METER, ABC, KEY, PARSED, PCHIST, PARSED2)
# 		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
# 		"""
# 		var params = [
# 			tune.get("tune", 0),
# 			tune.get("setting", 0),
# 			tune.get("name", ""),
# 			tune.get("type", ""),
# 			tune.get("mode", ""),
# 			tune.get("meter", ""),
# 			tune.get("abc", "").replace("\\\\", "\\"), ### WE NEED TO STRIP THIS PROPERLY
# 			tune.get("abc", ""),  # KEY field
# 			0,  # PARSED
# 			"",  # PCHIST
# 			0   # PARSED2
# 		]
		
# 		if !db.query_with_bindings(query, params):
# 			print("Failed to insert tune: ", tune.get("name", "unknown"))
			
			# Commit transaction
	# db.query("COMMIT;")
	# db.close_db()

	
