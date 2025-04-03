extends Node

class_name ABCImporter

# var directory_path = "res://assets/abc/"

func _ready():
	pass

##### ADD A TUNE TO THE DATABASE: INDEXING ABC FILES ####
static func add_tune_to_db(tune: Dictionary, source_id: int, source_info: Dictionary) -> bool: # func add_tune_to_db(tune: Dictionary, source_id: int) -> bool:
	var db = SQLite.new()
	
	db.path = clientside.prefix + "://assets/data/tunepal.db"
	var result = db.open_db()

	if result == false:
		push_error("Failed to open database: " + db.get_error_message())
		return false
	db.query("BEGIN TRANSACTION;")
	# Create source if needed
	db.query_with_bindings("SELECT id FROM source WHERE id = ?", [source_id])
	var num_source_ids = db.query_result.size()
	var source_result = false
	# db.query_with_bindings("SELECT id FROM source WHERE source = ?", [source_info["source"]])
	# var num_source_names = db.query_result.size()
	if num_source_ids == 0:
		print("Creating missing source with ID: ", source_id)
		db.query_with_bindings(
			"INSERT INTO source (id, source, extra, url, shortName) VALUES (?, ?, ?, ?, ?)",
			[source_id, source_info["source"], "", source_info["url"], source_info["shortName"]]
		)
		source_result = true

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
	var tools = ABCToolsClass.new()

	var midi_sequence = tools.get_midi_sequence(abc_notation, abc_file_name, 1, 0, 0, 0)
	print("got midi sequence")

	if midi_sequence.is_empty():
		print("MIDI generation failed, proceeding with empty sequence")
		midi_sequence = "0"

	var parsons_code = tools.generate_parsons_code(midi_sequence)

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

	db.query("COMMIT;")
	db.close_db()
	log_memory_usage("After addign a tune ")
	return true

static func import_source_directory(directory_path: String, source_id: int) -> int:
	print("Processing source directory: " + directory_path + " with source ID: " + str(source_id))
	var dir = DirAccess.open(directory_path)
	if !dir:
		push_error("Failed to open directory: " + directory_path)
		return 0

	dir.list_dir_begin()
	var file = dir.get_next()
	var tune_count = 0

	while file != "":
		if file.ends_with(".abc") or file.ends_with(".rtf"): # include rtfs
			print("Processing " + file + " (source ID: " + str(source_id) + ")")
			var file_path = directory_path + file
			var abc_file = FileAccess.open(file_path, FileAccess.READ)

			if abc_file != null:
				var tools = ABCToolsClass.new()
				var source_info = tools.find_source_info(abc_file, directory_path) # hopefully this works
				abc_file.close()
				abc_file = FileAccess.open(file_path, FileAccess.READ)
				var content = abc_file.get_as_text()
				abc_file.close()

				var tunes_data = ABCParser.parse_abc_content(content)
				for tune in tunes_data:
					tune["source"] = source_info["source"]
					tune["shortName"] = source_info["shortName"]
					tune["url"] = source_info["url"]
					tune["source_file"] = file
					add_tune_to_db(tune, source_id, source_info) # add_tune_to_db(tune, source_id)
					tune_count += 1

				tunes_data.clear() # clear the array for the next file
			else:
				push_error("Failed to open file: " + file_path)
		OS.delay_msec(1) # delay prevent memory hogging
		file = dir.get_next()

	dir.list_dir_end()
	print("Added " + str(tune_count) + " tunes from source ID " + str(source_id))
	return tune_count

static func import_files_from_directory(base_directory: String): # will change this to import from all folders
	var tools = ABCToolsClass.new()
	# ensure proper separator at the end of the path
	if not base_directory.ends_with("/") and not base_directory.ends_with("\\"):
		base_directory += "/"

	var dir = DirAccess.open(base_directory)
	if !dir:
		push_error("Failed to open base directory: " + base_directory)
		return false

	var total_tune_count = 0
	var used_source_ids = [] # track source ids already used

	dir.list_dir_begin()
	var folder = dir.get_next()
	# First round, index the numbered folders
	while folder != "":
		if dir.current_is_dir() and folder.is_valid_int():
			var source_id = folder.to_int()
			used_source_ids.append(source_id) # track the id numbers
			var source_path = base_directory + folder + "/"
			print("Importing from source ID " + str(source_id) + " at path " + source_path)
			var count = import_source_directory(source_path, source_id)
			total_tune_count += count
		folder = dir.get_next()
	dir.list_dir_end()

	# sort used ids for gap finding
	used_source_ids.sort()

	# 2nd pass index the folders that AREN'T numbered
	dir.list_dir_begin()
	folder = dir.get_next()

	while folder != "":
		if dir.current_is_dir() and !folder.is_valid_int():
			var tools_class = ABCToolsClass.new()
			var source_id = tools_class.find_next_available_id(used_source_ids)
			used_source_ids.append(source_id)
			var source_path = base_directory + folder + "/"
			print("Importing from non-numeric folder '" + folder + "' with source ID " + str(source_id) + " at path " + source_path)
			var count = import_source_directory(source_path, source_id)
			total_tune_count += count
		folder = dir.get_next()
	dir.list_dir_end()

	# last but not least if no numbered folders found, import directly from the base directory with default source ID 1
	var base_source_id = tools.find_next_available_id(used_source_ids)
	var default_count = import_source_directory(base_directory, base_source_id) # next available id
	total_tune_count += default_count
	print("Added " + str(total_tune_count) + " tunes to the database from all sources")
	return true
	
static func log_memory_usage(tag: String):
	var total_static_memory = Performance.get_monitor(Performance.MEMORY_STATIC)

	print("%s - MEMORY USAGE ###################: %.2f MB" % [tag, total_static_memory / (1024.0 * 1024.0)])
