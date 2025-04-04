# ABCTools class to replicate MattABCTools functionality
class_name ABCToolsClass
extends Object

static func get_midi_sequence(abc: String, filename: String, s: int, t: int, m: int, c: int) -> String:

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
	DirAccess.remove_absolute(abc_file_path)
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
	DirAccess.remove_absolute(midi_file_path)

	# Extract notes directly
	var midi_data = midi_file.get_buffer(midi_file.get_length())
	# print("the midi data: ", midi_data)
	midi_file.close()
	print("closed the midi file")
	var midi_notes = tunepal.extract_notes_from_midi(midi_data)
	# print("the midi notes: ", midi_notes)
	return midi_notes
	
######### parsons code = the movement of the melody needed for tune keys

static func generate_parsons_code(midi_sequence: String) -> String:
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

## Scan a file contents and assemble a dictionary of source info from a source file
static func find_source_info(abc_file_contents, folder_path) -> Dictionary:
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

	# Go through all the lines
	var found_url_in_header = false
	var found_url_in_comments = false
	var comment_url = ""

	var in_header = true
	for line in lines:
		line = line.strip_edges()
		# Skip the empty ones
		if line.is_empty():
			continue

		# Stop at the first notation line - we only need the header info
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
			# U header first choice for URLs
			elif line.begins_with("U:"):
				source_info["url"] = line.substr(2).strip_edges()
				found_url_in_header = true
		# URL not found in header, look everywhere
		if !found_url_in_header and (("http://" in line or "https://" in line)):
			var extracted_url = extract_url_from_line(line)
			if extracted_url != "":
				comment_url = extracted_url
				found_url_in_comments = true
	# URL elsewhere in the text but not in the header... then this is the URL
	if found_url_in_comments and !found_url_in_header:
		source_info["url"] = comment_url
		print("Found URL in comments: " + comment_url)

	return source_info

## Extract just the name of the folder from a path
static func get_folder_name_from_path(path: String) -> String:
	path = path.replace("\\", "/")

	if path.ends_with("/"):
		path = path.substr(0, path.length() - 1)

	var parts = path.split("/")

	for i in range(parts.size() - 1, -1, -1):
		if parts[i] != "":
			return parts[i]
	return "Unknown"

## Finds a URL in a file and returns it
static func extract_url_from_line(line: String) -> String:
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

static func get_next_tune_id(db) -> int:
	db.query("select max(id) from tuneindex;")
	var result = db.query_result
	if result.size() == 0 or result[0]["max(id)"] == null:
		return 1
	else:
		return result[0]["max(id)"] + 1
		
# HELper to find next available id - taking into account used id
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
				