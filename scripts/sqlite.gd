extends Node
const ABCTools = preload("res://scripts/ABCTools.gd")

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

	var path = clientside.prefix + "://assets/data/tunepal"
	tunes = load_db(path)
	open_json(clientside.prefix + default_user_tunes_path)

func import_all_files():
	var base_directory = "res://assets/abc/" # Base directory for all sources
	var dir = DirAccess.open(base_directory)
	if !dir:
		push_error("Failed to open base directory: " + base_directory)
		return false
		
	var total_tune_count = 0
	
	# Look for numbered folders (like "1", "2", "3", etc) in the base directory
	dir.list_dir_begin()
	var folder = dir.get_next()
	
	while folder != "":
		if dir.current_is_dir() and folder.is_valid_int():
			var source_id = folder.to_int()
			var source_path = base_directory + folder + "/"
			print("Importing from source ID " + str(source_id) + " at path " + source_path)
			var count = import_source_directory(source_path, source_id)
			total_tune_count += count
			
		folder = dir.get_next()
	dir.list_dir_end()
	
	# Also import directly from the base directory with default source ID 1
	# (keeping this for backward compatibility)
	var default_count = import_source_directory(base_directory, 1)
	total_tune_count += default_count
	
	print("Added " + str(total_tune_count) + " tunes to the database from all sources")
	return true

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
			
			if abc_file != null:
				var content = abc_file.get_as_text()
				abc_file.close()
				
				var tunes_data = parse_abc_content(content)
				for tune in tunes_data:
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
				source 
				where tunekeys.tuneid = tuneindex.id and tuneindex.source = source.id;
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

	import_all_files()
	return true

	var file = FileAccess.open(clientside.prefix + "://assets/abc/tunes.abc", FileAccess.WRITE)


# signal build_progress(progress_text: String)

func _on_build_db_button_pressed():
	# emit_signal("build_progress", "Starting database build...")
	# var success = await build_session_database()
	var success = build_session_database()
	if success:
		print("build_progress", "Database build successful")
	else:
		print("build_progress", "Database build failed")

###########
# PARSING  the ABC FILE
###########

func parse_abc_content(content: String) -> Array: # Creates a big array of the tunes
	var tunes_data = []
	var current_tune = {}
	var in_tune = false
	var tune_body = ""
	var tune_number = 0

	var tune_blocks = content.split("\n\n")

	for i in range(tune_blocks.size()):
		var block = tune_blocks[i].strip_edges()
		if block.is_empty():
			continue

		if block.begins_with("X:"):
			tune_number += 1
			current_tune = {
				"title": "",
				"alt_title": "",
				"type": "",
				"meter": "",
				"key_sig": "",
				"x": "",
				"abc": block
			}

		# extract key metadata values
		var lines = block.split("\n")
		for line in lines:
			line = line.strip_edges()

			if line.begins_with("X:"):
				current_tune["x"] = line.split(":")[1].strip_edges()
			elif line.begins_with("T:"):
				current_tune["title"] = line.split(":")[1].strip_edges()
			elif line.begins_with("T2:"):
				current_tune["alt_title"] = line.split(":")[1].strip_edges()
			elif line.begins_with("M:"):
				current_tune["meter"] = line.split(":")[1].strip_edges()
			elif line.begins_with("K:"):
				current_tune["key_sig"] = line.split(":")[1].strip_edges()
			elif line.begins_with("R:"):
				current_tune["type"] = line.split(":")[1].strip_edges()

		tunes_data.append(current_tune)

	return tunes_data
	
##### ADD A TUNE TO THE DATABASE: INDEXING ABC FILES ####

func add_tune_to_db(tune: Dictionary, source_id: int) -> bool:
	var db = SQLite.new()
	db.path = clientside.prefix + "://assets/data/tunepal"
	var result = db.open_db()

	if result == false:
		push_error("Failed to open database: " + db.get_error_message())
		return false
	
	# FIND THE next tune id
	db.query("SELECT MAX(id) as max_id FROM tuneindex;")
	var next_id = 1
	if db.query_result.size() > 0 and db.query_result[0]["max_id"] != null:
		next_id = db.query_result[0]["max_id"] + 1

	# format the tune identifier

	var tune_identifier = str(next_id) + "-" + tune["source_file"] + "-" + str(source_id) + "-" + tune["title"].replace(" ", "~")

	var abc_notation = tune["abc"]
	var abc_file_name = tune["source_file"]


	var tune_start = ABCTools.skip_headers(abc_notation)
	var just_tune = abc_notation.substr(tune_start)
	
	var stripped_abc = ABCTools.strip_all(just_tune) ### this isn't stripping correctly ???
	var processed_abc = ABCTools.fix_notation_for_tunepal(stripped_abc) # ????
	print("THE pRocessed ABC IS: ",  processed_abc)	
	# create the midi sequence or use placeholder
	
	# Parameters: abc notation, s=1 (skip headers), t=0 (transpose), m=0 (mode), c=0 (channel)
	var midi_sequence = get_midi_sequence(abc_notation, abc_file_name, 1, 0, 0, 0)

	var parsons_code = generate_parsons_code(midi_sequence)
	# var midi_sequence = "0000" #place holder

	var query = """
	INSERT INTO tuneindex (
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
		next_id,                   # id
		tune_identifier,           # tunepalid
		tune["source_file"],       # file_name
		tune["x"],                 # x
		tune["abc"],               # notation
		tune["title"],             # title
		"",                        # alt_title
		source_id,                 # source
		tune["type"],              # tune_type
		tune["key_sig"],           # key_sig
		0,                         # downloaded (default 0)
		tune["meter"]              # time_sig
	]

	db.query_with_bindings(query, params)

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
		next_id,                   # id (primary key)
		processed_abc,	# tune["title"].to_lower(),  # search_key
		next_id,                   # tuneid (references tuneindex.id)
		tune["source_file"],       # midi_file_name
		parsons_code,                        # parsons (empty placeholder)
		midi_sequence              # midi_sequence
	]
	
	db.query_with_bindings(keys_query, keys_params)
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
	var midifile = "temp.mid"
	
	# Create MIDI file
	tunepal.create_midi_file(abc, filename, midifile, s, t, m, c)
	
	# Read MIDI file into memory
	if not FileAccess.file_exists(midifile):
		push_error("Failed to convert ABC to MIDI: " + abc)
		return ""
		
	var midi_file = FileAccess.open(midifile, FileAccess.READ)
	if midi_file == null:
		push_error("Failed to open MIDI file: " + midifile)
		return ""
		
	# Extract notes directly
	var midi_data = midi_file.get_buffer(midi_file.get_length())
	midi_file.close()
	return tunepal.extract_notes_from_midi(midi_data)
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
		if notes[i] > notes[i-1]:
			parsons += "U"
		elif notes[i] < notes[i-1]:
			parsons += "D"
		else:
			parsons += "S"
			
	return parsons
