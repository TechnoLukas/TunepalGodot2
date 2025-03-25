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

func _ready():
	var path = clientside.prefix + "://assets/data/tunepal.db"
	verify_db_schema()
	tunes = load_db(path)
	open_json(clientside.prefix + default_user_tunes_path)

# func import_all_files():
# 	var base_directory = "res://assets/abc/" # Base directory for all sources
# 	var dir = DirAccess.open(base_directory)
# 	if !dir:
# 		push_error("Failed to open base directory: " + base_directory)
# 		return false
		
# 	var total_tune_count = 0
	
# 	# Look for numbered folders (like "1", "2", "3", etc) in the base directory
# 	dir.list_dir_begin()
# 	var folder = dir.get_next()
	
# 	while folder != "":
# 		if dir.current_is_dir() and folder.is_valid_int():
# 			var source_id = folder.to_int()
# 			var source_path = base_directory + folder + "/"
# 			print("Importing from source ID " + str(source_id) + " at path " + source_path)
# 			var count = import_source_directory(source_path, source_id)
# 			total_tune_count += count
			
# 		folder = dir.get_next()
# 	dir.list_dir_end()
	
# 	# Also import directly from the base directory with default source ID 1
# 	# (keeping this for backward compatibility)
# 	var default_count = import_source_directory(base_directory, 1)
# 	total_tune_count += default_count
	
# 	print("Added " + str(total_tune_count) + " tunes to the database from all sources")
# 	return true

func import_source_directory(directory_path: String, source_id: int) -> int:
	print("Processing source directory: " + directory_path + " with source ID: " + str(source_id))
	var dir = DirAccess.open(directory_path)
	if !dir:
		push_error("Failed to open directory: " + directory_path)
		return 0
		

	dir.list_dir_begin()
	var file = dir.get_next()
	var tune_count = 0
	
	while file != "":
	
		if file.ends_with(".abc"):
			print("Processing " + file + " (source ID: " + str(source_id) + ")")
			var file_path = directory_path + file
			var abc_file = FileAccess.open(file_path, FileAccess.READ)
			print("here")
			if abc_file != null:
				var content = abc_file.get_as_text()
				abc_file.close()
				print("here now")
				var tunes_data = parse_abc_content(content)
				print("the tunes data")
				for tune in tunes_data:
					print("here I am: ", tune)
					tune["source_file"] = file
					add_tune_to_db(tune, source_id)
					tune_count += 1
			else:
				push_error("Failed to open file: " + file_path)
				
		file = dir.get_next()
	
	dir.list_dir_end()
	print("Added " + str(tune_count) + " tunes from source ID " + str(source_id))
	return tune_count

func load_db(path):
	var return_tune = []
	var db = SQLite.new()
	db.path = path
	db.open_db()
	db.read_only = true

	db.query("SELECT COUNT(*) as count FROM tuneindex;")
	var count_result = db.query_result
	if count_result.size() > 0:
		print("Database contains " + str(count_result[0]["count"]) + " tunes")

		# Try a more limited query that avoids problematic text fields
		db.query("""
			SELECT 
				tuneindex.id as id,
				tuneindex.title,
				tuneindex.key_sig, 
				tuneindex.time_sig,
				source.id as sourceid
			FROM tuneindex
			JOIN source ON tuneindex.source = source.id
			LIMIT 10;  
		""")
	# Check if this basic query works
	if db.query_result.size() > 0:
		print("Basic query successful, retrieved " + str(db.query_result.size()) + " rows")
		
		# If basic query works, try the full query with error handling
		# db.query("""
		# 	SELECT 
		# 		tuneindex.id as id,
		# 		COALESCE(midi_sequence, '') as midi_sequence, 
		# 		COALESCE(tune_type, '') as tune_type, 
		# 		COALESCE(time_sig, '') as time_sig, 
		# 		'' as notation, -- Skip loading full notation text for now
		# 		source.id as sourceid, 
		# 		COALESCE(shortName, '') as shortName, 
		# 		COALESCE(url, '') as url, 
		# 		COALESCE(source.source, '') as sourcename, 
		# 		COALESCE(title, '') as title, 
		# 		COALESCE(alt_title, '') as alt_title, 
		# 		COALESCE(tunepalid, '') as tunepalid, 
		# 		COALESCE(x, '') as x, 
		# 		COALESCE(midi_file_name, '') as midi_file_name, 
		# 		COALESCE(key_sig, '') as key_sig, 
		# 		COALESCE(search_key, '') as search_key
		# 	FROM tuneindex
		# 	LEFT JOIN tunekeys ON tunekeys.tuneid = tuneindex.id
		# 	LEFT JOIN source ON tuneindex.source = source.id;
		# 	""")

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


# func build_session_database():

# 	import_all_files()
# 	return true

# 	var file = FileAccess.open(clientside.prefix + "://assets/abc/tunes.abc", FileAccess.WRITE)


# signal build_progress(progress_text: String)

func _on_build_db_button_pressed():
	# var success = build_session_database()
	# if success:
	# 	print("build_progress", "Database build successful")
	# else:
	# 	print("build_progress", "Database build failed")
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
	import_files_from_directory(path)

func import_source_debug() -> int:
	var source_id = 1  # or change as needed
	var directory_path = "C:/dev/final-project/tunepal-local-3/TunepalGodot2/assets/abc/"  # adjust if needed
	var target_file = "stickacrossthehob.abc"
	var file_path = directory_path + target_file
	print("Processing single file: " + target_file + " (source ID: " + str(source_id) + ")")
	
	var abc_file = FileAccess.open(file_path, FileAccess.READ)
	if abc_file == null:
		push_error("Failed to open file: " + file_path)
		return 0
	var content = abc_file.get_as_text()
	abc_file.close()
	
	var tunes_data = parse_abc_content(content)
	# print("Parsed tunes data: ", tunes_data)
	
	var tune_count = 0
	for tune in tunes_data:
		# print("Processing tune: ", tune)
		tune["source_file"] = target_file
		add_tune_to_db(tune, source_id)
		tune_count += 1
	
	print("Added " + str(tune_count) + " tunes from file " + target_file)
	return tune_count

func import_files_from_directory(base_directory: String):
	# ensure proper separator at the end of the path
	if not base_directory.ends_with("/") and not base_directory.ends_with("\\"):
		base_directory += "/"
	#
	var dir = DirAccess.open(base_directory)
	if !dir:
		push_error("Failed to open base directory: " + base_directory)
		return false

	var total_tune_count = 0
	var has_numbered_folders = false

	dir.list_dir_begin()
	var folder = dir.get_next()

	while folder != "":
		if dir.current_is_dir() and folder.is_valid_int():
			has_numbered_folders = true
			var source_id = folder.to_int()
			var source_path = base_directory + folder + "/"
			print("Importing from source ID " + str(source_id) + " at path " + source_path)
			var count = import_source_directory(source_path, source_id)
			# var count = import_source_debug() # just the one file to debug
			total_tune_count += count
			
		folder = dir.get_next()
	dir.list_dir_end()

	# if no numbered folders found, import directly from the base directory with default source ID 1
	if not has_numbered_folders:
		var default_count = import_source_directory(base_directory, 1)
		total_tune_count += default_count
	
	print("Added " + str(total_tune_count) + " tunes to the database from all sources")
	return true

###########
# PARSING  the ABC FILE
###########

# func parse_abc_content(content: String) -> Array: # Creates a big array of the tunes
# 	var tunes_data = []
# 	var current_tune = {}
# 	var in_tune = false
# 	var tune_body = ""
# 	var tune_number = 0

# 	var tune_blocks = content.split("\n\n")
# 	print("TUNE BLOCKS: ", tune_blocks)
# 	for i in range(tune_blocks.size()):
# 		var block = tune_blocks[i].strip_edges()
# 		if block.is_empty():
# 			continue

# 		if block.begins_with("X:"):
# 			tune_number += 1
# 			current_tune = {
# 				"title": "",
# 				"alt_title": "",
# 				"type": "",
# 				"meter": "",
# 				"key_sig": "",
# 				"x": "",
# 				"abc": block
# 			}

# 		# extract key metadata values
# 		var lines = block.split("\n")
# 		for line in lines:
# 			line = line.strip_edges()

# 			if line.begins_with("X:"):
# 				current_tune["x"] = line.split(":")[1].strip_edges()
# 			elif line.begins_with("T:"):
# 				current_tune["title"] = line.split(":")[1].strip_edges()
# 			elif line.begins_with("T2:"):
# 				current_tune["alt_title"] = line.split(":")[1].strip_edges()
# 			elif line.begins_with("M:"):
# 				current_tune["meter"] = line.split(":")[1].strip_edges()
# 			elif line.begins_with("K:"):
# 				current_tune["key_sig"] = line.split(":")[1].strip_edges()
# 			elif line.begins_with("R:"):
# 				current_tune["type"] = line.split(":")[1].strip_edges()

# 		tunes_data.append(current_tune)

# 	return tunes_data

func parse_abc_content(content):
	print("Processing ABC content...")
	var tunes_data = []

	# Normalise line endings
	content = content.replace("\r\n", "\n")
	# First try to split by double newline and X:
	var tune_blocks = content.split("\n\nX:")
	
	# If that didn't work, try other common patterns
	if tune_blocks.size() <= 1:
		tune_blocks = content.split("\nX:")
		
	# Ensure the first block has the X: prefix if needed
	if tune_blocks.size() > 0:
		if tune_blocks[0].begins_with("X:"):
			# First block already has X: prefix
			pass
		else:
			# Need to handle the first block which may or may not contain a tune
			if tune_blocks[0].strip_edges() == "":
				# If first block is empty, remove it
				tune_blocks.remove_at(0)
			else:
				# Add X: prefix to first block
				tune_blocks[0] = "X:" + tune_blocks[0]
				
	print("Found %d potential tune blocks" % tune_blocks.size())

	for block in tune_blocks:
		if block.strip_edges() == "":
			continue
			
		var tune = {
			# Initialize with defaults to avoid "key not found" errors
			"x": "1",            # Default index if none specified
			"title": "Untitled", # Default title
			"type": "reel",      # Default tune type
			"meter": "4/4",      # Default meter
			"key_sig": "Cmaj",   # Default key signature
			"source_file": "unknown.abc"
		}
		var lines = block.split("\n")
		# print("the lines: ", lines)
		if lines.size() == 0:
			continue
		
		for line in lines:
			line = line.strip_edges()
			if line == "":
				continue
				
			if line.length() >= 2 and line[1] == ":":
				var field_type = line[0]
				var field_content = line.substr(2).strip_edges()
				
				match field_type:
					"X": # Index number
						tune["index"] = field_content
						tune["x"] = field_content  # Ensure x is always set
					"T": # Title
						if "title" in tune:
							if not "alt_title" in tune:
								tune["alt_title"] = field_content
							elif tune["alt_title"] is String:
								tune["alt_title"] = [tune["alt_title"], field_content]
							else:
								tune["alt_title"].append(field_content)
						else:
							tune["title"] = field_content
					"R": # Rhythm
						tune["tune_type"] = field_content
						tune["type"] = field_content  # Add this field directly
					"M": # Meter/Time signature
						tune["time_sig"] = field_content
						tune["meter"] = field_content  # Add this field directly
					"K": # Key
						tune["key_sig"] = field_content
					"L": # Default note length
						tune["L"] = field_content
					"Z": # Transcriber
						tune["transcriber"] = field_content
					"S": # Source
						tune["source"] = field_content
					"N": # Notes/Annotations
						if "annotations" in tune:
							tune["annotations"] += " " + field_content
						else:
							tune["annotations"] = field_content
							
							# Only add tunes with at least a title and key signature
		if "title" in tune and "key_sig" in tune:
			var notation_start = false
			var notation_lines = []
			var header_lines = []
			
			# First collect all header lines to reconstruct full ABC
			for line in lines:
				line = line.strip_edges()
				if line == "":
					continue
					
				if line.length() >= 2 and line[1] == ":":
					header_lines.append(line)
				
				if notation_start:
					notation_lines.append(line)
				elif line.begins_with("K:"):
					notation_start = true
					notation_lines.append(line)  # Include the K: line in notation
					
			tune["notation"] = "\n".join(notation_lines)
			tune["abc"] = "\n".join(header_lines + notation_lines)
			
			# Make sure required fields exis
			if not "source_file" in tune:
				tune["source_file"] = "unknown.abc"
			if not "alt_title" in tune:
				tune["alt_title"] = ""
				
			tunes_data.append(tune)
			
	print("Successfully parsed %d tunes" % tunes_data.size())
	return tunes_data
	
##### ADD A TUNE TO THE DATABASE: INDEXING ABC FILES ####

func add_tune_to_db(tune: Dictionary, source_id: int) -> bool:
	var db = SQLite.new()
	var tools = ABCTools.new()
	db.path = clientside.prefix + "://assets/data/tunepal.db"
	var result = db.open_db()

	if result == false:
		push_error("Failed to open database: " + db.get_error_message())
		return false
	
	# FIND THE next tune id
	db.query("SELECT MAX(id) as max_id FROM tuneindex;")
	var next_id = 1
	if db.query_result.size() > 0 and db.query_result[0]["max_id"] != null:
		next_id = db.query_result[0]["max_id"] + 1
	print("HERE")
	# format the tune identifier

	var tune_identifier = str(next_id) + "-" + tune["source_file"] + "-" + str(source_id) + "-" + tune["title"].replace(" ", "~")

	var abc_notation = tune["abc"]
	var abc_file_name = tune["source_file"]
	# print("NOW HERE")

	# var tune_start = ABCTools.skip_headers(abc_notation)
	# print("NOW HERE MOTHAFUCKA")
	# var just_tune = abc_notation.substr(tune_start)
	# print("JUST TUNE: NOw herererere")
	var just_tune = tools.fix_notation_for_tunepal(abc_notation)
	# print("what about here?")
	var stripped_abc = tools.strip_all(just_tune)
	# print("did u make it this far you hoor??")
	# var processed_abc = ABCTools.fix_notation_for_tunepal(stripped_abc) # ????
	# print("THE pRocessed ABC IS: ",  processed_abc)	
	# create the midi sequence or use placeholder
	# print("THE stripped ABC IS: ", stripped_abc)
	# Parameters: abc notation, s=1 (skip headers), t=0 (transpose), m=0 (mode), c=0 (channel)
	var midi_sequence = get_midi_sequence(abc_notation, abc_file_name, 1, 0, 0, 0)
	print("got midi sequence")
	
	if midi_sequence.is_empty():
		print("MIDI generation failed, proceeding with empty sequence")
		midi_sequence = "0"

	var parsons_code = generate_parsons_code(midi_sequence)
	# print("parsons code", parsons_code)
	
	var query_result = db.query("BEGIN TRANSACTION")
	if query_result == false:
		push_error("Failed to begin transaction: " + db.error_message)
		db.close_db()
		return false

	var query = """
	INSERT OR REPLACE INTO tuneindex (
		id,
		tunepalid,
		file_name,
		x,
		notation,
		title,
		alt_title,
		source,
		tune_type,
		key_sig,
		downloaded,
		time_sig
	) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
	"""
	var params = [
		next_id, # id
		tune_identifier, # tunepalid
		tune["source_file"], # file_name
		tune["x"], # x
		tune["abc"], # notation
		tune["title"], # title
		"", # alt_title
		source_id, # source
		tune["type"], # tune_type
		tune["key_sig"], # key_sig
		0, # downloaded (default 0)
		tune["meter"] # time_sig
	]

	db.query_with_bindings(query, params)
	if db.error_message != "":
		print("Error during insertion: " + db.error_message)
		# push_error("SQLite error: " + db.error_message)
		db.query("ROLLBACK")
		db.close_db()
		return false
	else:
		print("Inserted tune index successfully")

	# var midi_seq_to_store = midi_sequence
	# if midi_sequence == "":
	# 	midi_seq_to_store = "0"

	var keys_query = """
	INSERT INTO tunekeys (
		id,
		search_key,
		tuneid,
		midi_file_name,
		parsons,
		midi_sequence
	) VALUES (?, ?, ?, ?, ?, ?);
	"""

	var keys_params = [
		next_id, # id (primary key)
		stripped_abc, # tune["title"].to_lower(),  # search_key
		next_id, # tuneid (references tuneindex.id)
		tune["source_file"], # midi_file_name
		parsons_code, # parsons (empty placeholder)
		midi_sequence # midi_sequence
	]
	
	db.query_with_bindings(keys_query, keys_params)
	if db.error_message != "":
		# push_error("SQLite error: " + db.error_message)
		print("Error during insertion: " + db.error_message)
		db.query("ROLLBACK")
		db.close_db()
		return false
	else:
		print("Inserted tune keys successfully")
		

# Commit transaction
	if db.query("COMMIT") == false:
		push_error("Failed to commit transaction: " + db.error_message)
		db.query("ROLLBACK")
		db.close_db()
		return false
	else:
		print("Successfully committed transaction for tune ID: ", next_id)
		
	db.close_db()
	return true

func get_next_tune_id(db) -> int:
	db.query("select max(id) from tuneindex;")
	var result = db.query_result
	if result.size() == 0 or result[0]["max(id)"] == null:
		return 1
	else:
		return result[0]["max(id)"] + 1

func get_midi_sequence(abc: String, filename: String, s: int, t: int, m: int, c: int) -> String:

	var tunepal = Tunepal.new()
	if tunepal == null:
		push_error("Failed to create Tunepal instance")
		return ""
		
	var user_dir = ProjectSettings.globalize_path("user://")
	var abc_file_path = user_dir + "temp.abc"
	var midi_file_path = user_dir + "temp.mid"
	
	# Create ABC file first to ensure correct input to MIDI converter
	var abc_file = FileAccess.open(abc_file_path, FileAccess.WRITE)
	print("opened and written the abc file")
	if abc_file == null:
		print("failed to create abc file")
		push_error("Failed to create ABC file: " + abc_file_path)
		return ""
	abc_file.store_string(abc)
	abc_file.close()
	
	# Try to create MIDI file with better error handling
	print("Creating MIDI file...")
	tunepal.create_midi_file(abc, abc_file_path, midi_file_path, s, t, m, c)
	print("MIDI file created")
	#print("MIDI creation result: " + str(midi_result))
	
	# Check if MIDI file exists
	if not FileAccess.file_exists(midi_file_path):
		print("No midi file created")
		push_error("MIDI file not created: " + midi_file_path)
		return ""
	
	# Rest of the function as before...
		
	var midi_file = FileAccess.open(midi_file_path, FileAccess.READ)
	print("opened the midi file")
	if midi_file == null:
		print("didn't open the midi file")
		push_error("Failed to open MIDI file: " + midi_file_path)
		return ""
		
	# Extract notes directly
	var midi_data = midi_file.get_buffer(midi_file.get_length())
	# print("the midi data: ", midi_data)
	midi_file.close()
	print("closed the midi file")
	var midi_notes = tunepal.extract_notes_from_midi(midi_data)
	# print("the midi notes: ", midi_notes)
	return midi_notes
	
#########

func generate_parsons_code(midi_sequence: String) -> String:
	if midi_sequence.is_empty():
		return ""
		
	# If it's a Base64-encoded MIDI, we need to extract the note data
	# This is a simplified approach - you may need to parse the MIDI properly
	var notes = []
	
	# If the MIDI sequence is already a comma-separated list of note numbers
	if midi_sequence.contains(","):
		var note_strings = midi_sequence.split(",")
		for note in note_strings:
			if note.strip_edges().is_valid_int():
				notes.append(int(note.strip_edges()))
	else:
		# This is a placeholder - in a real implementation you would
		# parse the MIDI data to extract the note pitch information
		return ""
	
	# Generate Parsons code from note pitch relationships
	var parsons = ""
	for i in range(1, notes.size()):
		if notes[i] > notes[i - 1]:
			parsons += "U"
		elif notes[i] < notes[i - 1]:
			parsons += "D"
		else:
			parsons += "S"
			
	return parsons
	
func verify_db_schema():
	var db = SQLite.new()
	db.path = clientside.prefix + "://assets/data/tunepal.db"
	db.open_db()
	
	print("=== Checking Database Schema ===")
	db.query("PRAGMA table_info(tuneindex)")
	print("tuneindex columns:", db.query_result)
	
	db.query("PRAGMA table_info(tunekeys)")
	print("tunekeys columns:", db.query_result)
	
	db.query("PRAGMA table_info(source)")
	print("source columns:", db.query_result)
	
	db.query("PRAGMA foreign_key_list(tunekeys)")
	print("tunekeys foreign keys:", db.query_result)
	
	db.close_db()
