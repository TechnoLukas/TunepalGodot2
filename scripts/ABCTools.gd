# ABCTools class to replicate MattABCTools functionality
class_name ABCToolsClass
extends Object

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
