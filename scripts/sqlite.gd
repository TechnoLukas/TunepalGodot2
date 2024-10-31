extends Node

@onready var db = SQLite.new()
@onready var db_name
var query_result = []

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
	if OS.get_name() in ["Android", "iOS", "Web"]:
		db_name = "user://assets/data/tunepal"
		copy_data_to_user()
		print("finished")
	else:
		db_name = "res://assets/data/tunepal"
	
	db.path = db_name
	db.open_db()
	db.read_only = true
	# source = 2 norbeck
	db.query("select tuneindex.id as id, midi_sequence, tune_type, time_sig, notation, source.id as sourceid, shortName, url, source.source as sourcename, title, alt_title, tunepalid, x, midi_file_name, key_sig, search_key from tuneindex, tunekeys, source where tunekeys.tuneid = tuneindex.id and tuneindex.source = source.id and source.id = 2;")
	query_result = db.query_result
	for i in range(0, query_result.size()):
		var title = query_result[i]["title"]
		for character in accented_characters:
			if character in title:
				title=title.replace(character, accented_characters[character])
		query_result[i]["accented_title"] = title
	db.close_db()

func cprint(text : String) -> void:
	print(text)

func copy_data_to_user() -> void:
	var original_data_path := "res://assets/data"
	var copy_assets_path := "user://assets"
	var copy_data_path := "user://assets/data"

	DirAccess.make_dir_absolute(copy_assets_path)
	DirAccess.make_dir_absolute(copy_data_path)
	var dir = DirAccess.open(original_data_path)
	
	print(dir.get_files())
	if dir:
		dir.list_dir_begin();
		var file_name = dir.get_next()
		while (file_name != ""):
			if dir.current_is_dir():
				pass
			else:
				cprint("Copying " + file_name + " to /user-folder")
				dir.copy(original_data_path + "/" + file_name, copy_data_path + "/" + file_name)
			file_name = dir.get_next()
	else:
		cprint("An error occurred when trying to access the path.")
