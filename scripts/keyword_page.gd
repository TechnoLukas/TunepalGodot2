extends Control

var stuff
@onready var tunelist = $TunesList
@onready var search_line = $TopSection/SectionWithMargin/group/search_field/line_edit

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stuff = sqlite.query_result
	tunelist.clear_list()
	update_list("")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_list(text):
	for i in range(0, stuff.size()):
		var title = stuff[i]["title"]
		var alt_title = stuff[i]["alt_title"]
		for character in accented_characters:
			if character in title:
				title=title.replace(character, accented_characters[character])

		if search_line.text == "":
			tunelist.add_item(title)
		else:
			if (search_line.text in title) or (alt_title!=null and (search_line.text in alt_title)):
				tunelist.add_item(title)
	
func _on_line_edit_text_changed(new_text: String) -> void:
	pass
	#clear_list()
	#update_list(new_text)

func _on_line_edit_text_submitted(new_text: String) -> void:
	tunelist.clear_list()
	update_list(new_text)


func _on_close_field_pressed() -> void:
	search_line.text=""
	tunelist.clear_list()
	update_list("")
	#search_line.emit_signal("text_submitted","")
