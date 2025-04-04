# TuneParser.gd
# GDScript equivalent of abc4j Java TuneParser
extends RefCounted

class_name AbcTuneParser

signal tune_begin
signal tune_end(tune, header_node)
signal no_tune

var m_tune = null

func _init():
    pass

# Return last completely parsed tune, null if not yet parsed
func get_tune():
    return m_tune

# Parses a file in ABC notation.
# 
# @param file_path: Path to tune file in ABC notation.
# @return A tune representing the ABC notation stream.
func parse_file(file_path: String):
    if not FileAccess.file_exists(file_path):
        push_error("File does not exist: " + file_path)
        return null
    
    var file = FileAccess.open(file_path, FileAccess.READ)
    if not file:
        push_error("Could not open file: " + file_path)
        return null
    
    var content = file.get_as_text()
    
    return parse(content)

# Parses a string in ABC notation.
# 
# @param tune_str: The abc tune, as a String, to be parsed.
# @return An object representation of the abc notation string.
func parse(tune_str: String):
    var abc_root = get_parse_tree(tune_str)
    return parse0(abc_root)

# Helper method for parsing
func parse0(abc_root):
    var abc_tune_node = abc_root.get_child("AbcTune")
    m_tune = parse_abc_tune(abc_tune_node)
    return m_tune

# Parses only the header of a file in ABC notation.
# This method provides faster parsing when just abc header fields are needed.
#
# @param file_path: Path to tune file in ABC notation.
# @return An object representation with no score of the abc notation.
func parse_header_file(file_path: String):
    if not FileAccess.file_exists(file_path):
        push_error("File does not exist: " + file_path)
        return null
    
    var file = FileAccess.open(file_path, FileAccess.READ)
    if not file:
        push_error("Could not open file: " + file_path)
        return null
    
    var content = file.get_as_text()
    
    return parse_header(content)

# Parses the header of the specified tune notation.
# 
# @param tune_str: A tune notation in ABC.
# @return A tune representing the ABC notation with header values only.
func parse_header(tune_str: String):
    var abc_root = get_parse_tree(tune_str)
    return parse_header0(abc_root)

# Helper method for parsing headers
func parse_header0(abc_root):
    init_new_tune()
    emit_signal("tune_begin")
    
    var abc_header_node = null
    if abc_root != null:
        var abc_tune_node = abc_root.get_child("AbcTune")
        if abc_tune_node != null:
            abc_header_node = abc_tune_node.get_child("AbcHeader")
    
    var tune
    if abc_header_node == null:
        tune = self.AbcTune.new()
        emit_signal("no_tune")
    else:
        tune = parse_abc_header(abc_header_node)
        tune.set_abc_string(abc_header_node.get_value())
    
    emit_signal("tune_end", tune, abc_header_node)
    return tune

# Get a parse tree from a string
# This method would be implemented by inheriting classes
func get_parse_tree(content: String):
    # Implementation depends on the specific parser
    pass

# Initialize a new tune
# This method would be implemented by inheriting classes
func init_new_tune():
    # Implementation depends on the specific parser
    pass

# Parse an ABC tune node
# This method would be implemented by inheriting classes
func parse_abc_tune(abc_tune_node):
    # Implementation depends on the specific parser
    pass

# Parse an ABC header node
# This method would be implemented by inheriting classes
func parse_abc_header(abc_header_node):
    # Implementation depends on the specific parser
    pass

# Simple class to store ABC tune information
class AbcTune:
    var abc_string: String = ""
    
    func set_abc_string(abc: String):
        abc_string = abc
    
    func get_abc_string() -> String:
        return abc_string

# Simple node class for our ABC parse tree
class AbcNode:
    var name: String
    var value: String
    var children: Dictionary = {}
    
    func _init(node_name: String):
        name = node_name
        value = ""
    
    func add_child(node):
        children[node.name] = node
    
    func get_child(child_name: String):
        if children.has(child_name):
            return children[child_name]
        return null
    
    func set_value(val: String):
        value = val
    
    func get_value() -> String:
        return value