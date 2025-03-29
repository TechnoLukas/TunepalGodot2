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
	# verify_db_writeable()
	tunes = load_db(path)
	open_json(clientside.prefix + default_user_tunes_path)


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
		if file.ends_with(".abc") or file.ends_with(".rtf"): ## include rtfs
			print("Processing " + file + " (source ID: " + str(source_id) + ")")
			var file_path = directory_path + file
			var abc_file = FileAccess.open(file_path, FileAccess.READ)
			

			if abc_file != null:
				var source_info = find_source_info(abc_file, directory_path) ## hopefully this works
				abc_file.close()
				abc_file = FileAccess.open(file_path, FileAccess.READ)
				var content = abc_file.get_as_text()
				abc_file.close()
				
				var tunes_data = parse_abc_content(content)
				for tune in tunes_data:
					tune["source"] = source_info["source"]
					tune["shortName"] = source_info["shortName"]
					tune["url"] = source_info["url"] 
					tune["source_file"] = file
					add_tune_to_db(tune, source_id, source_info) # add_tune_to_db(tune, source_id)
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


# func check_inserted_tunes():
# 	print("Verifying database contents immediately after insertion...")
# 	var db = SQLite.new()
# 	db.path = clientside.prefix + "://assets/data/tunepal.db"
# 	db.open_db()
	
# 	# Check if any tunes exist
# 	db.query("SELECT COUNT(*) as count FROM tuneindex")
# 	var count = 0
# 	if db.query_result.size() > 0:
# 		count = db.query_result[0]["count"]
# 	print("Tune count in tuneindex immediately after insertion: ", count)
	
# 	if count > 0:
# 		# Get the first few tunes to verify data
# 		db.query("SELECT id, title, x, key_sig FROM tuneindex LIMIT 3")
# 		print("Sample tunes: ", db.query_result)
	
# 	# Check tunekeys as well
# 	db.query("SELECT COUNT(*) as count FROM tunekeys")
# 	if db.query_result.size() > 0:
# 		print("Tune count in tunekeys: ", db.query_result[0]["count"])
	
# 	db.close_db()

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
	import_files_from_directory(path)

# func import_source_debug() -> int:
# 	var source_id = 1  # or change as needed
# 	var directory_path = "C:/dev/final-project/tunepal-local-3/TunepalGodot2/assets/abc/"  # adjust if needed
# 	var target_file = "stickacrossthehob.abc"
# 	var file_path = directory_path + target_file
# 	print("Processing single file: " + target_file + " (source ID: " + str(source_id) + ")")
	
# 	var abc_file = FileAccess.open(file_path, FileAccess.READ)
# 	if abc_file == null:
# 		push_error("Failed to open file: " + file_path)
# 		return 0
# 	var content = abc_file.get_as_text()
# 	abc_file.close()
	
# 	var tunes_data = parse_abc_content(content)
# 	# print("Parsed tunes data: ", tunes_data)
	
# 	var tune_count = 0
# 	for tune in tunes_data:
# 		# print("Processing tune: ", tune)
# 		tune["source_file"] = target_file
# 		add_tune_to_db(tune, source_id)
# 		tune_count += 1
# 		print ("Added tune: ", tune["title"])
	
# 	print("Added " + str(tune_count) + " tunes from file " + target_file)
# 	# check_inserted_tunes()
# 	return tune_count

func import_files_from_directory(base_directory: String): ### will change this to import from all folders
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
	var used_source_ids = [] # track source ids already used

	dir.list_dir_begin()
	var folder = dir.get_next()

	while folder != "":
		if dir.current_is_dir() and folder.is_valid_int():
			has_numbered_folders = true
			var source_id = folder.to_int()
			used_source_ids.append(source_id) # rack the id numbers
			var source_path = base_directory + folder + "/"
			print("Importing from source ID " + str(source_id) + " at path " + source_path)
			var count = import_source_directory(source_path, source_id)
			# var count = import_source_debug() # just the one file to debug
			total_tune_count += count
			
		folder = dir.get_next()
	dir.list_dir_end()

	# sort used ids for gap yah finding
	used_source_ids.sort()

	# 2nd pass
	dir.list_dir_begin()
	folder = dir.get_next()

	while folder != "":
		if dir.current_is_dir() and !folder.is_valid_int():
			var source_id = find_next_available_id(used_source_ids)
			used_source_ids.append(source_id)
			# var count = import_source_directory(source_path, source_id)
			var source_path = base_directory + folder + "/"	
			print("Importing from non-numeric folder '" + folder + "' with source ID " + str(source_id) + " at path " + source_path)
			var count = import_source_directory(source_path, source_id)
			total_tune_count += count
		folder = dir.get_next()
	dir.list_dir_end()

	# if no numbered folders found, import directly from the base directory with default source ID 1
	if not has_numbered_folders:
		var default_count = import_source_directory(base_directory, 1)
		total_tune_count += default_count
	
	print("Added " + str(total_tune_count) + " tunes to the database from all sources")
	return true

# HELper to find next available id - taking into account used ids
func find_next_available_id(used_ids: Array) -> int:
	if used_ids.size() == 0:
		return 1

	for i in range(1, used_ids[-1] + 1):
		if i not in used_ids:
			return i

	return used_ids[-1] + 1

#### helper function to find the next available source id
func find_next_source_id(base_directory: String) -> int:
	var numbered_folders = []
	# list through the subdirectories to find all numbered folders
	# and 
	var dir = DirAccess.open(base_directory)
	if dir:
		dir.list_dir_begin()
		var folder = dir.get_next()

		while folder != "":
			if dir.current_is_dir() and folder.is_valid_int():
				numbered_folders.append(folder.to_int())
			folder = dir.get_next()
		dir.list_dir_end()

	if numbered_folders.size() == 0:
		return 1

	numbered_folders.sort()
	var max_id = numbered_folders[-1]

		# check for gap
	for i in range(1, max_id + 1):
		if i not in numbered_folders:
			return i

	return max_id + 1 # if no gaps

				## find next available source id
				
###########
# PARSING  the ABC FILE
###########

func parse_abc_content(content):
	print("Processing ABC content...")
	var tunes_data = []

	# Normalise line endings
	content = content.replace("\r\n", "\n")
	content = content.replace("\\\n", "\n") # Remove on end of line \ (causes problems in .rtf files)
	content = content.replace("\\\\\n", "\n") # Remove on end of line \ (causes problems in .rtf files)
	content = content.replace("]\n", "\n") # Remove on end of line ] (causes problems in .rtf files)
	# var tune_blocks = []

	# if content.find("\n\nX:") > -1:
	# 	# Split by X: prefix
	# 	tune_blocks = content.split("\n\nX:")
	# elif content.find("\n\nX:") > -1:
	# 	# Split by X: prefix
	# 	tune_blocks = content.split("\nX:")
	# else:
	# 	# last resort just split by x
	var tune_blocks = content.split("X:")
		
	if tune_blocks.size() > 0:
		if not tune_blocks[0].strip_edges().begins_with("X:"): ### THere is something up here, 
			if tune_blocks[0].strip_edges() == "":
				tune_blocks.remove_at(0)
			else:
				tune_blocks[0] = "X:" + tune_blocks[0]
		
	print("Found %d potential tune blocks" % tune_blocks.size())

	for i in range(tune_blocks.size()):
		var block = tune_blocks[i]
		if block.strip_edges() == "":
			continue

		# For all blocks except the first one, we need to re-add the X: prefix that was removed during the split operation
		if i >= 0 and not block.strip_edges().begins_with("X:"):
			block = "X:" + block
			
		var tune = {			
			"x": "1",      # Default index if none specified
			"title": "Untitled", # Default title
			"type": "reel",   # Default tune type
			"meter": "4/4",   # Default meter
			"key_sig": "Cmaj",  # Default key signature
			"source_file": "unknown.abc"
		}

		# Split block into lines
		var lines = block.split("\n")
		if lines.size() == 0:
			continue
		
		# process all header fields first.. keep going until we hit the K: field
		var header_complete = false  # Fixed variable name typo
		var header_lines = []
		var notation_lines = []

		for line in lines:
			line = line.strip_edges()
			if line.begins_with("%%%"):
				line.substr(3).strip_edges()
				continue

			if line.begins_with("\"") and line.ends_with("\""):
				# delete this line
				line = "\n"
				continue
				
			if not header_complete:
				header_lines.append(line)
			else:
				# in the notation section
				# Check for quotation mark
				if line.begins_with("\""):
					var close_quote = line.find("\"", 1)
					if close_quote != -1:
						line = line.substr(close_quote + 1).strip_edges()
					
						if line.strip_edges() == "":
							continue

				# if line.strip_edges() != "":
				# 	notation_lines.append(line)
				
			if line.length() >= 2 and line[1] == ":":
				var field_type = line[0] # key
				var field_content = line.substr(2).strip_edges() # value
				
				match field_type:
					"X": # Index number / SETTING
						if not header_complete:
							tune["x"] = field_content  # Ensure x is always set
					"T": # Title
						if not header_complete:
							if field_content.strip_edges() != "":
								if tune["title"] == "Untitled":
									tune["title"] = field_content
								else:
									if not "alt_title" in tune:
										tune["alt_title"] = field_content
									elif tune["alt_title"] is String and tune["alt_title"] != "":
										tune["alt_title"] = [tune["alt_title"], field_content]
									elif tune["alt_title"] is Array:
										tune["alt_title"].append(field_content)
									else:
										tune["alt_title"] += " " + field_content
					"R": # Rhythm
						if not header_complete:
							tune["type"] = field_content  # Add this field directly
					"M": # Meter/Time signature
						if not header_complete:
							tune["meter"] = field_content  # Add this field directly
					"K": # Key
						if not header_complete:
							tune["key_sig"] = field_content
							header_complete = true
						# else:
						# 	notation_lines.append(line)
						# K field typically marks the end
						
						# in cases where K doesn't mark the end, such as a key change mid-tune
						# we need to keep processing the header fields
				
					"L": # Default note length
						if not header_complete:
							tune["L"] = field_content
					"Z": # Transcriber
						if not header_complete:
							tune["transcriber"] = field_content
					"S": # Source
						if not header_complete:
							tune["source_file"] = field_content
					"N": # Notes/Annotations
						if not header_complete:
							if not "notes" in tune:
								tune["notes"] = field_content
							else:
								tune["notes"] += " " + field_content

				if field_type == "Q" and "==" in field_content: ## isabella burke made me put this here
				# Fix double equals in tempo
					field_content = field_content.replace("==", "=")

			if header_complete:
				notation_lines.append(line)
				

		# make sure we got min required info
		if tune["title"] != "Untitled": # or tune["key_sig"] != "Cmaj":
			# construct full abc string for the notation field
			tune["abc"] = "\n".join(header_lines + notation_lines)
			tune["notation"] = "\n".join(notation_lines)

			# ensure all req fields exist
			if not "alt_title" in tune:
				tune["alt_title"] = ""

			print("Parsed tune: ", tune["title"])
			tunes_data.append(tune)

	print("Successfully parsed %d tunes" % tunes_data.size())
	return tunes_data
							
##### ADD A TUNE TO THE DATABASE: INDEXING ABC FILES ####

func add_tune_to_db(tune: Dictionary, source_id: int, source_info: Dictionary) -> bool: # func add_tune_to_db(tune: Dictionary, source_id: int) -> bool:
	var db = SQLite.new()
	var tools = ABCTools.new()
	db.path = clientside.prefix + "://assets/data/tunepal.db"
	var result = db.open_db()

	if result == false:
		push_error("Failed to open database: " + db.get_error_message())
		return false
		
		# Create source if needed
	db.query_with_bindings("SELECT id FROM source WHERE id = ?", [source_id])
	var num_source_ids = db.query_result.size()
	# db.query_with_bindings("SELECT id FROM source WHERE source = ?", [source_info["source"]])
	# var num_source_names = db.query_result.size()
	if num_source_ids == 0:
		print("Creating missing source with ID: ", source_id)
		db.query_with_bindings(
			"INSERT INTO source (id, source, extra, url, shortName) VALUES (?, ?, ?, ?, ?)", 
			[source_id, source_info["source"], "",  source_info["url"], source_info["shortName"]]
		)

	# FIND THE next tune id
	db.query("SELECT MAX(id) as max_id FROM tuneindex;")
	var next_id = 1
	if db.query_result.size() > 0 and db.query_result[0]["max_id"] != null:
		next_id = db.query_result[0]["max_id"] + 1
	var tune_identifier = str(next_id) + "-" + tune["source_file"] + "-" + str(source_id) + "-" + tune["title"].replace(" ", "~")

	var abc_notation = tune["notation"] # cjanged from abc
	var abc_file_name = tune["source_file"]
	
	var just_tune = ABCTools.fix_notation_for_tunepal(abc_notation)
	# print("what about here?")
	var stripped_abc = ABCTools.strip_all(just_tune)


## Skips tunes that are ridiculously long to prevent crashing
	if abc_notation.length() > 2000:
		print("ABC notation too long, skipping tune: " + tune["title"])
		return false

	var midi_sequence = get_midi_sequence(abc_notation, abc_file_name, 1, 0, 0, 0)
	print("got midi sequence")
	
	if midi_sequence.is_empty():
		print("MIDI generation failed, proceeding with empty sequence")
		midi_sequence = "0"

	var parsons_code = generate_parsons_code(midi_sequence)

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
## tunepalid as setting or is "x" the setting I think it's x

	var params = [
		next_id, # id
		tune_identifier, # tunepalid
		tune["source_file"], # file_name / url
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

	print("params", params)

## checks for duplicates
	var is_duplicate = false
	var duplicate_query = """
	SELECT COUNT(*) as count FROM tuneindex WHERE file_name = ? AND x = ?;
	"""
	var duplicate_params = [tune["source_file"], tune["x"]] ## for now using this as the unique identifier
	db.query_with_bindings(duplicate_query, duplicate_params)
	var db_result = db.query_result
	if db_result.size() > 0 and db_result[0]["count"] > 0:
		print("Duplicate tune found: " + tune["title"])
		db.close_db()
		is_duplicate = true
		return false
	else:
		var index_result = db.query_with_bindings(query, params)
		if !index_result:
			push_error("Failed to insert into tuneindex: " + db.error_message)
			db.close_db()
			return false

	var keys_query = """
	INSERT OR REPLACE INTO tunekeys (
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
		stripped_abc, # tune["title"].to_lower() # search_key
		next_id, # tuneid (references tuneindex.id)
		tune["source_file"], # midi_file_name
		parsons_code, # parsons (empty placeholder)
		midi_sequence # midi_sequence
	]
	var keys_result = false
	if !is_duplicate:
		db.query_with_bindings(keys_query, keys_params)
		keys_result = true
	if !keys_result:
		push_error("Failed to insert into tunekeys: " + db.error_message)
		# Important: since we're not using transactions, we need to clean up the earlier insert
		db.query_with_bindings("DELETE FROM tuneindex WHERE id = ?", [next_id])
		db.close_db()
		return false
	print("Successfully inserted tune: " + tune["title"] + " (ID: " + str(next_id) + ")")
	db.close_db()
	return true


# 	### Skip duplicate tunes
# func check_duplicate_tune(tune: Dictionary) -> bool:
# 	var db = SQLite.new()
# 	db.path = clientside.prefix + "://assets/data/tunepal.db"
# 	var result = db.open_db()

# 	if result == false:
# 		push_error("Failed to open database: " + db.get_error_message())
# 		return false

# 	var duplicate_query = """
# 	SELECT COUNT(*) as count FROM tuneindex WHERE title = ? AND key_sig = ?;
# 	"""
# 	var duplicate_params = [tune["title"], tune["key_sig"]]
# 	db.query_with_bindings(duplicate_query, duplicate_params)
# 	var db_result = db.query_result
# 	if db_result.size() > 0 and db_result[0]["count"] > 0:
# 		print("Duplicate tune found: " + tune["title"])
# 		db.close_db()
# 		return true

# 	db.close_db()
# 	return false

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
	
######### parsons code = the movement of the melody needed for tune keys

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

## scan a file contents and assemble a dictionary of source info from a source file
func find_source_info(abc_file_contents, folder_path) -> Dictionary:
	var source_info = {
		"source": "Unknown",
		"shortName": "Unknown",
		"url": "https://example.com"
	}
	
	if abc_file_contents == null:
		return source_info
	
	var folder_name = get_folder_name_from_path(folder_path)
	print("Folder name: " + folder_name)
	if folder_name.is_valid_int():
		source_info["source"] = "Source " + folder_name
		source_info["shortName"] = "S" + folder_name
	else:
		source_info["source"] = folder_name
		source_info["shortName"] = folder_name

	var content = abc_file_contents.get_as_text()
	var lines = content.split("\n")
	
	# go through all the lines
	var found_url_in_header = false
	var found_url_in_comments = false
	var comment_url = ""

	var in_header = true
	for line in lines:
		line = line.strip_edges()
		#skip the empty ones
		if line.is_empty():
			continue

		# stop at the first notation line - we only need the header info
		if !in_header:
			if !line.begins_with("A:") and !line.begins_with("B:") and !line.begins_with("C:") and \
				!line.begins_with("D:") and !line.begins_with("F:") and !line.begins_with("G:") and \
				!line.begins_with("H:") and !line.begins_with("I:") and !line.begins_with("K:") and \
				!line.begins_with("L:") and !line.begins_with("M:") and !line.begins_with("N:") and \
				!line.begins_with("O:") and !line.begins_with("P:") and !line.begins_with("Q:") and \
				!line.begins_with("R:") and !line.begins_with("S:") and !line.begins_with("T:") and \
				!line.begins_with("U:") and !line.begins_with("V:") and !line.begins_with("W:") and \
				!line.begins_with("X:") and !line.begins_with("Z:") and !line.begins_with("%"):
					in_header = false
					break

			if line.begins_with("S:"):
				source_info["source"] = line.substr(2).strip_edges()
				if "http://" in line or "https://" in line:
					var extracted_url = extract_url_from_line(line)
					if extracted_url != "":
						source_info["url"] = extracted_url
						found_url_in_header = true
			elif line.begins_with("N:"):
				source_info["shortName"] = line.substr(2).strip_edges()
				# U header first choice for urls
			elif line.begins_with("U:"):
				source_info["url"] = line.substr(2).strip_edges()
				found_url_in_header = true
	# url not foudn in header, look in everywhere
		if !found_url_in_header and (("http://" in line or "https://" in line)):
			var extracted_url = extract_url_from_line(line)
			if extracted_url != "":
				comment_url = extracted_url
				found_url_in_comments = true
	# url elsewhere in the text but not in the header... then this is the url
	if found_url_in_comments and !found_url_in_header:
		source_info["url"] = comment_url
		print("Found URL in comments: " + comment_url)

	return source_info

## Extract just the name of the folder from a path			
func get_folder_name_from_path(path: String) -> String:
	path = path.replace("\\", "/")

	if path.ends_with("/"):
		path = path.substr(0, path.length() - 1)

	var parts = path.split("/")

	for i in range(parts.size() - 1, -1, -1):
		if parts[i] != "":
			return parts[i]
	return "Unknown"

## FInds a URL in a file and returns it				
func extract_url_from_line(line: String) -> String:
	var url_start = -1
	if "http://" in line:
		url_start = line.find("http://")
	elif "https://" in line:
		url_start = line.find("https://")
	else:
		return ""

	var end_markers = [" ", ")", "]", ",", ";", "\t", "\"", "'"]
	var url_end = line.length()
	for marker in end_markers:
		var marker_pos = line.find(marker, url_start)
		if marker_pos != -1 and marker_pos < url_end:
			url_end = marker_pos

	return line.substr(url_start, url_end - url_start)
