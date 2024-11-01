extends Node

var prefix
# Called when the node enters the scene tree for the first time.
func _init() -> void:
	if OS.get_name() in ["Android", "iOS", "Web"]:
		prefix = "user"
		copy_assets_to_user()
	else:
		prefix = "res"
		
	print("AAAAAAAAAAAAAAAAAAAA", prefix)

func copy_assets_to_user():
	var original_assets_path := "res://assets"
	var copy_assets_path := "user://assets"

	copy_directory_recursive(original_assets_path, copy_assets_path)


func copy_directory_recursive(source_dir: String, dest_dir: String) -> void:
	# Create the destination directory if it doesn't exist
	DirAccess.make_dir_absolute(dest_dir)
	
	# Open the source directory
	var dir = DirAccess.open(source_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while (file_name != ""):
			# Skip "." and ".." which represent the current and parent directories
			if file_name == "." or file_name == "..":
				file_name = dir.get_next()
				continue
			
			var source_path = source_dir + "/" + file_name
			var dest_path = dest_dir + "/" + file_name
			
			if dir.current_is_dir():
				# If it's a directory, create the directory in the destination and call recursively
				DirAccess.make_dir_absolute(dest_path)
				copy_directory_recursive(source_path, dest_path)
			else:
				# If it's a file, copy it
				print("Copying " + source_path + " to " + dest_path)
				dir.copy(source_path, dest_path)
				#FileAccess.copy(source_path, dest_path)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		print("An error occurred when trying to access the path: " + source_dir)
