extends Node

class_name ABCImporter

var directory_path = "res://assets/abc/"

func _ready():
    pass

func import_all_files():
    # iterate trhough all files in the directory
    var dir = DirAccess.open(directory_path)
    dir.list_dir_begin()

    var file = dir.get_next()
    while file != "":
        if file.ends_with(".abc"):
            print(file)
            var file_path = directory_path + file
            var abc_file = FileAccess.open(file_path, FileAccess.READ)
            if not abc_file:
                push_error("Could not open file: " + file_path)
                return null
            
            var content = abc_file.get_as_text()
            print(content)

            abc_file.close()
            file = dir.get_next()