extends Node

@onready var db = SQLite.new()
@onready var db_name
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
	db.path =  clientside.prefix + "://assets/data/tunepal"
	db.open_db()
	db.read_only = true
	# source = 2 norbeck
	await db.query("select tuneindex.id as id, midi_sequence, tune_type, time_sig, notation, file_name, source.id as sourceid, shortName, url, source.source as sourcename, title, alt_title, tunepalid, x, midi_file_name, key_sig, search_key from tuneindex, tunekeys, source where tunekeys.tuneid = tuneindex.id and tuneindex.source = source.id and source.id = 1 limit 1000;")
	tunes = db.query_result
	print(str(tunes.size()) + " tunes loaded")
	for i in range(0, tunes.size()):
		var title = tunes[i]["title"]
		for character in accented_characters:
			if character in title:
				title=title.replace(character, accented_characters[character])
		tunes[i]["accented_title"] = title
	db.close_db()
