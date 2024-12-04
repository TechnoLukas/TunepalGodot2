extends Node

var prefix

# Called when the node enters the scene tree for the first time.
func _init() -> void:
	if OS.get_name() in ["Android", "iOS", "Web"]:
		prefix = "user"
		copy_assets_to_user("res://assets/data", "user://assets/data")
		copy_assets_to_user("res://assets/midi", "user://assets/midi")
		copy_assets_to_user("res://assets/soundfonts", "user://assets/soundfonts")
		if DirAccess.open("user://assets/data_persistent") == null:
			copy_assets_to_user("res://assets/data_persistent", "user://assets/data_persistent")
	else:
		prefix = "res"

	print("Resource prefix is '", prefix, "'")

# Function to recursively copy the assets from one directory to another
func copy_assets_to_user(original_assets_path: String, copy_assets_path: String) -> void:
	var dir = DirAccess.open(original_assets_path)

	# Check if the original directory was successfully opened
	if dir == null:
		print("Failed to open directory: ", original_assets_path)
		return

	# Check if the copy directory exists, if not, create it
	if DirAccess.open(copy_assets_path) == null:
		# Create an instance of DirAccess for the current location
		var copy_dir = DirAccess.open("user://")
		if copy_dir.make_dir_recursive(copy_assets_path) != OK:
			print("Failed to create directory: ", copy_assets_path)
			return

	# Iterate through the directory contents
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name != "." and file_name != "..": # Ignore special directories
			var original_file_path = original_assets_path + "/" + file_name
			var copy_file_path = copy_assets_path + "/" + file_name

			if dir.current_is_dir(): # If it's a directory, recursively copy
				copy_assets_to_user(original_file_path, copy_file_path)
			else: # If it's a file, copy it
				var file = FileAccess.open(original_file_path, FileAccess.READ)
				if file:
					var file_contents = file.get_buffer(file.get_length())
					file.close()
					
					# Write to the new file location
					var new_file = FileAccess.open(copy_file_path, FileAccess.WRITE)
					if new_file:
						new_file.store_buffer(file_contents)
						new_file.close()
					else:
						print("Failed to open file for writing: ", copy_file_path)
				else:
					print("Failed to open file for reading: ", original_file_path)

		file_name = dir.get_next()

	dir.list_dir_end()
