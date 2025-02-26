extends Node

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

func _ready():

	# var success = await build_session_database() ##
	# if success:
	# 	print("Database build successful")
	# else:
	# 	print("Database build failed")

	var path = clientside.prefix + "://assets/data/tunepal"
	tunes = load_db(path)
	open_json(clientside.prefix + default_user_tunes_path)

	# FOR TESTING PURPOSES: BUILD FROM A FILE
	# var abc_file_path = clientside.prefix + "://assets/abc/reelsa-c.abc"
	# Numeric ID of the source (based on DB’s 'source' table)
	# var source_id = 2

	# do the test thing
	# var success = read_from_file(abc_file_path, source_id)
	# if success:
	# 	print("File read successful", abc_file_path)
	# else:
	# 	print("File read failed", abc_file_path)



# func check_db(path):
# 	var db = SQLite.new()
# 	db.path = path
# 	db.open_db()
# 	db.read_only = true
# 	db.query("select count(*) from tuneindex;")
# 	var result = db.query_result
# 	db.close_db()

# 	if result.size() == 0:
# 		return 0
# 	else:
# 		return result[0]["count(*)"]

func read_from_file(path: String, source_id: int) -> bool: # READ an individual ABC File!!
	print("Indexing ABC FILE: ", path)
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: " + path)
		return false

	var content = file.get_as_text()
	file.close()

	var tune_data = parse_abc_content(content)
	var success = true

	# add each of the tunes to the database
	for tune in tune_data:
		if not add_tune_to_db(tune, source_id):
			success = false
			# push_error("Failed to add tune to database: " + tune_data)
			print("no luck :()")
	return success
	
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
	else:
		print("No tunes detected in database")

	return return_tune
### for USER TUNES ###
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

	if data == null:
		print("Failed to parse JSON response")
		return false

	if not data is Array:
		print("Unexpected JSON response, expected array")
		return false


	## var success = ABCTools.populate_database(data)
	
	# Create the ABC file directly here instead of using ABCTools
	var file = FileAccess.open(clientside.prefix + "://assets/abc/tunes.abc", FileAccess.WRITE)
	var success = false
	if file:
		for tune in data:
			file.store_string(tune.abc + "\n\n")
		file.close()
		success = true
	if success:
		print("abc file created successfully")
		return true
	else:
		print("Failed to create abc file")
		return false

# signal build_progress(progress_text: String)

func _on_build_db_button_pressed():
	# emit_signal("build_progress", "Starting database build...")
	var success = await build_session_database()
	if success:
		print("build_progress", "Database build successful")
	else:
		print("build_progress", "Database build failed")

###########
# PARSING  the ABC FILE
###########

func parse_abc_content(content: String) -> Array:
	var tunes_data = []
	var current_tune = {}
	var in_tune = false
	var tune_body = ""

	var lines = content.split("\n")

	for line in lines:
		line = line.strip_edges()

		if line.is_empty() or line.begins_with("%"):
			continue
# CHECK for the beginning of a tune
		if line.begins_with("X:"):
			# if we are on a tune, save the current tune
			if in_tune:
				current_tune["abc"] = tune_body
				tunes_data.append(current_tune)
				
			current_tune = {"x": line.substr(2).strip_edges()}
			tune_body = line + "\n"
			in_tune = true

			# parse the other header fields if we are within a tune
		elif in_tune:
			tune_body += line + "\n" # thanks claude
			if line.begins_with("T:"):
				current_tune["title"] = line.substr(2).strip_edges()
			elif line.begins_with("M:"):
				current_tune["meter"] = line.substr(2).strip_edges()
			elif line.begins_with("K:"):
				current_tune["key"] = line.substr(2).strip_edges()
			elif line.begins_with("R:"):
				current_tune["rhythm"] = line.substr(2).strip_edges()
			elif line.begins_with("L:"):
				current_tune["unit_note_length"] = line.substr(2).strip_edges()
			elif line.begins_with("Q:"):
				current_tune["tempo"] = line.substr(2).strip_edges()
			elif line.begins_with("C:"):
				current_tune["composer"] = line.substr(2).strip_edges()
			elif line.begins_with("Z:"):
				current_tune["transcriber"] = line.substr(2).strip_edges()
			elif line.begins_with("P:"):
				current_tune["part_of"] = line.substr(2).strip_edges()
			elif line.begins_with("S:"):
				current_tune["source"] = line.substr(2).strip_edges()
			elif line.begins_with("D:"):
				current_tune["discography"] = line.substr(2).strip_edges()
			elif line.begins_with("N:"):
				current_tune["notes"] = line.substr(2).strip_edges()
			elif line.begins_with("O:"):
				current_tune["origin"] = line.substr(2).strip_edges()
			elif line.begins_with("H:"):
				current_tune["history"] = line.substr(2).strip_edges()
			elif line.begins_with("I:"):
				current_tune["instruction"] = line.substr(2).strip_edges()
			elif line.begins_with("K:"):
				current_tune["key"] = line.substr(2).strip_edges()
			elif line.begins_with("V:"):
				current_tune["voice"] = line.substr(2).strip_edges()
			elif line.begins_with("W:"):
				current_tune["words"] = line.substr(2).strip_edges()

	# last tune....
	if in_tune:
		current_tune["abc"] = tune_body
		tunes_data.append(current_tune)

	return tunes_data

	
##### ADD A TUNE TO THE DATABASE: INDEXING ABC FILES ####

func add_tune_to_db(tune: Dictionary, source_id: int) -> bool:
	var db = SQLite.new()
	db.path = clientside.prefix + "://assets/data/tunepal"
	var result = db.open_db()
	if result == null:
		push_error("Failed to open database: " + db.get_error())
		return false
	db.query("begin transaction;")
	
	var next_id = get_next_tune_id(db)
	var abc_notation = tune.get("abc", "")

# create unique tunepalId
	var tune_title = tune.get("title", "No Title").replace("'", "''") # escape single quotes
	var tunepalid = str(next_id) + "-" + tune.get("x", "0") + ".abc-1-" + tune_title


	## insert into tuneindex
	var query = """
	INSERT into tuneindex 
	(id, tune_type, time_sig, notation, source, title, alt_title, tunepalid, x, key_sig)
	VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
	"""

	var params = [
		next_id,
		tune.get("type", ""),
		tune.get("meter", ""),
		abc_notation,
		source_id,
		tune.get("title", ""),
		tune.get("alt_title", ""),
		tunepalid,
		tune.get("x", ""),
		tune.get("key_sig", "")
	]

	if not db.query_with_bindings(query, params):
		push_error("Failed to insert tune into database: " + tune.get("title", "No Title"))
		db.query("rollback;")
		db.close_db()
		return false

	#Process the ABC notation for TUNE KEY search keys

	var stripped_abc = ABCTools.strip_all(abc_notation)

	var midi_sequence = get_midi_sequence(abc_notation, 100, 0, 1, 1)
	

	# insert into tunekeys table
	query = """
	INSERT into tunekeys
	(tuneid, search_key, midi_sequence)
	VALUES (?, ?, ?);
	"""

	params = [
		next_id,
		stripped_abc,
		midi_sequence
	]

	if not db.query_with_bindings(query, params):
		push_error("Failed to insert tune keys into database: " + tune.get("title", "No Title"))
		db.query("ROLLBACK;")
		db.close_db()
		return false

	# commit the transaction
	db.query("COMMIT;")
	db.close_db()
	return true

	# Get the next available tune ID
func get_next_tune_id(db) -> int:
	db.query("select max(id) from tuneindex;")
	var result = db.query_result
	if result.size() == 0 or result[0]["max(id)"] == null:
		return 1
	else:
		return result[0]["max(id)"] + 1

# Function to  andle the ABC to midi conversion - using the ABC2MIDI library
	# Here we'll call the Tunepal GDExtension function

# func get_midi_sequence(abc: String, abc_path: String, midi_path: String, s: int, t: int, m: int, c: int) -> String:

# 	var tunepal = Tunepal.new()
	 
# 	tunepal.create_midi_file(abc, abc_path, midi_path, s, t, m, c)	
# 	if not FileAccess.file_exists(midi_path):
# 		push_error("Failed to convert ABC to MIDI: " + abc)
# 		return ""

# 	if midi_path == "":
# 		return ""
# 	else: 
# 		var midi_file = FileAccess.open(midi_path, FileAccess.READ)
# 		if midi_file == null:
# 			push_error("Failed to open MIDI file: " + midi_path)
# 			return ""
# 		return midi_file.get_as_text()

# Function to just get it from memory
func get_midi_sequence(abc: String, s: int, t: int, m: int, c: int) -> String:
	var tunepal = Tunepal.new()
	var midi_bytes = tunepal.create_midi_in_memory(abc, s, t, m, c)
	if midi_bytes.size() == 0:
		push_error("Failed to convert ABC to MIDI in memory")
		return ""
	return midi_bytes.to_base64()

	
