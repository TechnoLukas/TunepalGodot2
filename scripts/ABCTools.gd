# ABCTools class to replicate MattABCTools functionality
class_name ABCToolsClass
extends Object

# Static flag to track successful parsing
static var flag: bool = true

# Removes accented characters and handles line breaks
static func fix_notation_for_tunepal(notation: String) -> String:
	var result = notation
	# Replace accented characters
	var replacements = {
		"á": "\\\'a", "é": "\\\'e", "í": "\\\'i", "ó": "\\\'o", "ú": "\\\'u",
		"Á": "\\\'A", "É": "\\\'E", "Í": "\\\'I", "Ó": "\\\'O", "Ú": "\\\'U"
	}
	
	for key in replacements:
		result = result.replace(key, replacements[key])
	
	if result.find("I:linebreak $") != -1:
		var tune_start = skip_headers(result)
		var just_tune = result.substr(tune_start)
		just_tune = just_tune.replace("\r", "")
		just_tune = just_tune.replace("\r\n", "")
		just_tune = just_tune.replace("\n", "")
		just_tune = just_tune.replace("$ ", "$")
		just_tune = just_tune.replace("$", "\n")
		just_tune = just_tune.replace("w:", "\nw:")
		
		result = result.substr(0, tune_start) + just_tune
	
	return result

# Removes extra notation marks and guitar chords
static func remove_extra_notation(key: String) -> String:
	var ret = key
	# Remove basic notation marks
	var to_remove = [">", "<", "/", "\\", "(", ")", "-", "!", "_"]
	for mark in to_remove:
		ret = ret.replace(mark, "")
	
	# Remove guitar chords using regex
	var regex = RegEx.new()
	for i in range(1, 6):  # Handle chords of different lengths
		regex.compile("\\[.{" + str(i) + "}\\]")
		ret = regex.sub(ret, "", true)
	
	# Keep only letters A-G and a-g
	var result = ""
	for c in ret:
		if (c >= "A" and c <= "G") or (c >= "a" and c <= "g"):
			result += c
	
	return result

# Removes repeated notes
static func remove_long_notes(key: String) -> String:
	var ret = ""
	var last_char = "*"
	
	for c in key:
		if c != last_char:
			ret += c
			last_char = c
	
	return ret

# Skips ABC notation headers
static func skip_headers(tune: String) -> int:
	var i := 0
	var in_chars := 0
	var in_header := true
	
	while i < tune.length() and in_header:
		var c = tune[i]
		if in_chars == 1:
			if (c == ":" and tune[i-1] != "|") or \
			   (c == "%" and tune[i-1] == "%"):
				in_header = true
			else:
				in_header = false
				i -= 2
		if c == "\r" or c == "\n":
			in_chars = -1
		i += 1
		in_chars += 1
	
	return i

# Expands repeated sections in ABC notation
static func expand_parts(notes: String) -> String:
	var result = notes
	var count = 0
	var regex = RegEx.new()
	
	# Handle basic repeats and alternate endings
	while count < 10:  # Limit iterations to prevent infinite loops
		count += 1
		var start_idx = result.find("|:")
		if start_idx == -1:
			break
			
		var end_idx = result.find(":|", start_idx)
		if end_idx == -1:
			break
			
		var section = result.substr(start_idx + 2, end_idx - start_idx - 2)
		var expanded = section + "|" + section
		result = result.substr(0, start_idx) + expanded + result.substr(end_idx + 2)
	
	return result

# Removes bar divisions from the notation
static func strip_bar_divisions(notes: String) -> String:
	var result = ""
	
	for c in notes:
		if c != "|" and c != ":":
			result += c
	
	return result

# Removes triplet marks
static func remove_triplet_marks(notes: String) -> String:
	var result = ""
	var i = 0
	
	while i < notes.length():
		var c = notes[i]
		if c == "(" and i + 1 < notes.length() and notes[i + 1].is_valid_int():
			i += 1
		else:
			result += c
		i += 1
	
	return result

# Expands long notes in ABC notation
static func expand_long_notes(notes: String) -> String:
	var result = ""
	var in_ornament = false
	
	# First pass: remove ornaments and certain characters
	for c in notes:
		if c == "{":
			in_ornament = true
			continue
		if c == "}":
			in_ornament = false
			continue
			
		if not in_ornament and c != "~" and c != "," and c != "=" and \
		   c != "^" and c != "'":
			result += c
	
	# Second pass: expand long notes
	var i = 1
	while i < result.length():
		var c = result[i]
		var p = result[i - 1]
		
		# If it's a long note (digit after letter)
		if c.is_valid_int() and is_valid_note(p): 
			var expanded = ""
			var count = int(c)
			for j in range(count):
				expanded += p
			
			result = result.substr(0, i - 1) + expanded + result.substr(i + 1)
			i += expanded.length() - 2
		
		i += 1
	
	return result

# Main function that combines all transformations
static func strip_all(key: String) -> String:
	flag = true
	key = strip_comments(key)
	key = strip_whitespace(key)
	key = expand_long_notes(key)
	key = expand_parts(key)
	key = strip_bar_divisions(key)
	key = remove_triplet_marks(key)
	key = remove_extra_notation(key)
	key = strip_advanced_abc(key)
	return key.to_upper()

# Additional helper functions
static func strip_whitespace(text: String) -> String:
	return text.replace(" ", "").replace("\r", "").replace("\n", "")

static func strip_comments(text: String) -> String:
	var result = ""
	var in_comment = false
	var i = 0
	
	while i < text.length():
		var c = text[i]
		if c == '"':
			in_comment = !in_comment
			i += 1
			continue
		if not in_comment:
			result += c
		i += 1
	
	return result

# Helper function to check if a character is a valid musical note letter
static func is_valid_note(c: String) -> bool:
	var ascii_val = c.unicode_at(0)
	return (ascii_val >= "A".unicode_at(0) and ascii_val <= "G".unicode_at(0)) or \
		   (ascii_val >= "a".unicode_at(0) and ascii_val <= "g".unicode_at(0))

static func strip_advanced_abc(text: String) -> String:
	var replacements = {
		"!fermata!": "",
		"!trill)!": "",
		"!trill(!": "",
		"!turn!": ""
	}
	
	var result = text
	for key in replacements:
		result = result.replace(key, replacements[key])
	
	return result


# static func strip_all_safe(key: String) -> String:
# 	print("strip all called with input length: ", + key.length())
# 	flag = true
# 	var result = key

# 	print("1. Stripping comments")
# 	result = strip_comments_safe(result)

# 	print("2. Stripping whitespace")
# 	result = result.replace(" ", "").replace("\r", "").replace("\n", "")

# 	print("3. Expanding long notes")
# 	result = expand_long_notes_safe(result)

# 	print("4. Expanding parts")
# 	result = expand_parts_safe(result)

# 	print("5. Stripping bar divisions")
# 	result = strip_bar_divisions_safe(result)

# 	print("6. Removing triplet marks")
# 	result = remove_triplet_marks_safe(result)

# 	print("7. Removing extra notation")
# 	result = remove_extra_notation_safe(result)

# 	print("8. Stripping advanced ABC")
# 	result = strip_advanced_abc(result)

# 	print("Strip complete, returning " + str(result.length()) + " characters")
# 	return result.to_upper()

	
# static func strip_comments_safe(text: String) -> String:
# 	if text.is_empty():
# 		return ""

# 	var result = ""
# 	var in_comment = false
# 	var i = 0
	
# 	while i < text.length():
# 		var c = text[i]
# 		if c == '"':
# 			in_comment = !in_comment
# 			i += 1
# 			continue
# 		if not in_comment:
# 			result += c
# 		i += 1
	
# 	return result

# static func expand_long_notes_safe(notes: String) -> String:
# 	if notes.is_empty():
# 		return ""

# 	var result = ""
# 	var in_ornament = false

# 	# First pass: remove ornaments and certain characters
# 	for c in notes:
# 		if c == "{":
# 			in_ornament = true
# 			continue
# 		if c == "}":
# 			in_ornament = false
# 			continue
			
# 		if not in_ornament and c != "~" and c != "," and c != "=" and \
# 		   c != "^" and c != "'":
# 			result += c

# 	var final_result = ""
# 	var i = 0
	
# 	while i < result.length():
# 		var c = result[i]
# 		final_result += c
		
# 		# If it's a long note (digit after letter)
# 		if i + 1 < result.length() and c.is_valid_int() and is_valid_note(c): 
# 			var count = int(result[i + 1])
# 			count = min(count, 10)  # Limit to prevent infinite loops
# 			for j in range(count):
# 				final_result += c

# 			i += 1
		
# 		i += 1

# 	return final_result

# static func expand_parts_safe(notes: String) -> String:
# 	if notes.is_empty():
# 		return ""

# 	var result = notes
# 	var max_iterations = 5 # prevent infinte loopydoooops
# 	var count = 0

# 	while count < max_iterations:
# 		count += 1
# 		var start_idx = result.find("|:")
# 		if start_idx == -1:
# 			break
			
# 		var end_idx = result.find(":|", start_idx)
# 		if end_idx == -1 or end_idx <= start_idx +2:
# 			break # invalid repeat structure

# 		var section = result.substr(start_idx + 2, end_idx - start_idx - 2)
# 		if section.length() > 1000:
# 			print("Section too long, skipping expansion")
# 			break

# 		var expanded = section + "|" + section
# 		result = result.substr(0, start_idx) + expanded + result.substr(end_idx + 2)

# 	return result
			
# static func strip_bar_divisions_safe(notes: String) -> String:
# 	if notes.is_empty():
# 		return ""

# 	var result = ""
	
# 	for c in notes:
# 		if c != "|" and c != ":":
# 			result += c
	
# 	return result

# static func remove_triplet_marks_safe(notes: String) -> String:
# 	if notes.is_empty():
# 		return ""

# 	var result = ""
# 	var i = 0
	
# 	while i < notes.length():
# 		var c = notes[i]
# 		if c == "(" and i + 1 < notes.length() and notes[i + 1].is_valid_int():
# 			i += 1
# 		else:
# 			result += c
# 		i += 1
	
# 	return result

# static func remove_extra_notation_safe(key: String) -> String:
# 	if key.is_empty():
# 		return ""
		
# 		# For very large inputs, use ultra-simplified approach
# 	if key.length() > 5000:
# 		print("Large input - using fast extraction")
		
# 	# Just extract musical notes directly - simple and robust approach
# 	var result = ""
# 	for c in key:
# 		if (c >= 'A' and c <= 'G') or (c >= 'a' and c <= 'g'):
# 			result += c
			
# 	print("Standard processing complete - result length: " + str(result.length()))
# 	return result
	# # For very large inputs, use ultra-simplified version
	# if key.length() > 5000:
	# 	# Ultra-fast approach - extract only notes in one pass
	# 	var result = ""
	# 	for c in key:
	# 		if (c >= 'A' and c <= 'G') or (c >= 'a' and c <= 'g'):
	# 			result += c
	# 	print("Used ultra-fast extraction - result length: " + str(result.length()))
	# 	return result
		
	# var ret = key

	# ret = ret.replace("<", "").replace(">", "").replace("/", "").replace("\\", "").replace("(", "").replace(")", "").replace("-", "").replace("!", "").replace("_", "")
	# ret = ret.replace("\\[.\\]", "")
	# ret = ret.replace("\\[...\\]", "")
	# ret = ret.replace("\\[....\\]", "")
	# ret = ret.replace("\\[.....\\]", "")
	# ret = ret.replace("\\[.*\\]", "")

	# var result = ""
	# var i = 0
	# while i < ret.length():
	# 	for c in ret:
	# 		if not ((c >= 'A' and c <= 'G') or (c >= 'a' and c <= 'g')):
	# 			ret = ret.replace(c, "")
	# 			result += c
	# 		i += 1
	# return result
	
	# Replace all notation marks in a single pass per character
	# var to_remove = [">", "<", "/", "\\", "(", ")", "-", "!", "_"]
	# for mark in to_remove:
	# 	ret = ret.replace(mark, "")
	
	# var result = ""
	# var i = 0
	# var in_brackets = false
	
	# while i < ret.length():
	# 	var c = ret[i]
		
	# 	# Handle brackets - simple approach that skips all content in brackets
	# 	if c == '[':
	# 		in_brackets = true
	# 	elif c == ']':
	# 		in_brackets = false
	# 	# Only add characters if not in brackets and they're valid notes
	# 	elif not in_brackets and ((c >= 'A' and c <= 'G') or (c >= 'a' and c <= 'g')):
	# 		result += c
			
	# 	i += 1
	
	# print("Standard processing complete - result length: " + str(result.length()))
	# return result
