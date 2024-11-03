extends Node

var tunes = []
var user_tunes = []

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

func _ready():
	var path = clientside.prefix + "://assets/data/tunepal"
	tunes = load_db(path)

	
func load_db(path):
	var return_tune
	var db = SQLite.new()
	db.path = path
	db.open_db()
	db.read_only = true
<<<<<<< HEAD
	db.query("select tuneindex.id as id, midi_sequence, tune_type, time_sig, notation, source.id as sourceid, shortName, url, source.source as sourcename, title, alt_title, tunepalid, x, midi_file_name, key_sig, search_key from tuneindex, tunekeys, source where tunekeys.tuneid = tuneindex.id and tuneindex.source = source.id and source.id = 2;")
	return_tune = db.query_result
=======
	# source = 2 norbeck
	await db.query("select tuneindex.id as id, midi_sequence, tune_type, time_sig, notation, file_name, source.id as sourceid, shortName, url, source.source as sourcename, title, alt_title, tunepalid, x, midi_file_name, key_sig, search_key from tuneindex, tunekeys, source where tunekeys.tuneid = tuneindex.id and tuneindex.source = source.id and source.id = 2;")
	tunes = db.query_result
	for i in range(0, tunes.size()):
		var title = tunes[i]["title"]
		for character in accented_characters:
			if character in title:
				title=title.replace(character, accented_characters[character])
		tunes[i]["accented_title"] = title
>>>>>>> main
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
	
