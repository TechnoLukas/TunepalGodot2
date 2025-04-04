extends Node

class_name ABCParser

static func parse_abc_content(content):
    print("Processing ABC content...")
    var tunes_data = []

    # Normalise line endings
    content = content.replace("\r\n", "\n")
    content = content.replace("\\\n", "\n") # Remove on end of line \ (causes problems in .rtf files)
    content = content.replace("\\\\\n", "\n") # Remove on end of line \ (causes problems in .rtf files)
    content = content.replace("]\n", "\n") # Remove on end of line ] (causes problems in .rtf files)
    # var tune_blocks = []

    # if content.find("\n\nX:") > -1:
    # 	# Split by X: prefix
    # 	tune_blocks = content.split("\n\nX:")
    # elif content.find("\n\nX:") > -1:
    # 	# Split by X: prefix
    # 	tune_blocks = content.split("\nX:")
    # else:
    # 	# last resort just split by x
    var tune_blocks = content.split("X:")
        
    if tune_blocks.size() > 0:
        if not tune_blocks[0].strip_edges().begins_with("X:"): ### THere is something up here, 
            if tune_blocks[0].strip_edges() == "":
                tune_blocks.remove_at(0)
            else:
                tune_blocks[0] = "X:" + tune_blocks[0]
        
    print("Found %d potential tune blocks" % tune_blocks.size())

    for i in range(tune_blocks.size()):
        var block = tune_blocks[i]
        if block.strip_edges() == "":
            continue

        # For all blocks except the first one, we need to re-add the X: prefix that was removed during the split operation
        if i >= 0 and not block.strip_edges().begins_with("X:"):
            block = "X:" + block
            
        var tune = {			
            "x": "1",      # Default index if none specified
            "title": "Untitled", # Default title
            "type": "reel",   # Default tune type
            "meter": "4/4",   # Default meter
            "key_sig": "Cmaj",  # Default key signature
            "source_file": "unknown.abc"
        }

        # Split block into lines
        var lines = block.split("\n")
        if lines.size() == 0:
            continue
        
        # process all header fields first.. keep going until we hit the K: field
        var header_complete = false  # Fixed variable name typo
        var header_lines = []
        var notation_lines = []

        for line in lines:
            line = line.strip_edges()
            if line.begins_with("%%%"):
                line.substr(3).strip_edges()
                continue

            if line.begins_with("\"") and line.ends_with("\""):
                # delete this line
                line = "\n"
                continue
                
            if not header_complete:
                header_lines.append(line)
            else:
                # in the notation section
                # Check for quotation mark
                if line.begins_with("\""):
                    var close_quote = line.find("\"", 1)
                    if close_quote != -1:
                        line = line.substr(close_quote + 1).strip_edges()
                    
                        if line.strip_edges() == "":
                            continue

                # if line.strip_edges() != "":
                # 	notation_lines.append(line)
                
            if line.length() >= 2 and line[1] == ":":
                var field_type = line[0] # key
                var field_content = line.substr(2).strip_edges() # value
                
                match field_type:
                    "X": # Index number / SETTING
                        if not header_complete:
                            tune["x"] = field_content  # Ensure x is always set
                    "T": # Title
                        if not header_complete:
                            if field_content.strip_edges() != "":
                                if tune["title"] == "Untitled":
                                    tune["title"] = field_content
                                else:
                                    if not "alt_title" in tune:
                                        tune["alt_title"] = field_content
                                    elif tune["alt_title"] is String and tune["alt_title"] != "":
                                        tune["alt_title"] = [tune["alt_title"], field_content]
                                    elif tune["alt_title"] is Array:
                                        tune["alt_title"].append(field_content)
                                    else:
                                        tune["alt_title"] += " " + field_content
                    "R": # Rhythm
                        if not header_complete:
                            tune["type"] = field_content  # Add this field directly
                    "M": # Meter/Time signature
                        if not header_complete:
                            tune["meter"] = field_content  # Add this field directly
                    "K": # Key
                        if not header_complete:
                            tune["key_sig"] = field_content
                            header_complete = true
                        # else:
                        # 	notation_lines.append(line)
                        # K field typically marks the end
                        
                        # in cases where K doesn't mark the end, such as a key change mid-tune
                        # we need to keep processing the header fields
                
                    "L": # Default note length
                        if not header_complete:
                            tune["L"] = field_content
                    "Z": # Transcriber
                        if not header_complete:
                            tune["transcriber"] = field_content
                    "S": # Source
                        if not header_complete:
                            tune["source_file"] = field_content
                    "N": # Notes/Annotations
                        if not header_complete:
                            if not "notes" in tune:
                                tune["notes"] = field_content
                            else:
                                tune["notes"] += " " + field_content

                if field_type == "Q" and "==" in field_content: ## isabella burke made me put this here
                # Fix double equals in tempo
                    field_content = field_content.replace("==", "=")

            if header_complete:
                notation_lines.append(line)
                

        # make sure we got min required info
        if tune["title"] != "Untitled": # or tune["key_sig"] != "Cmaj":
            # construct full abc string for the notation field
            tune["abc"] = "\n".join(header_lines + notation_lines)
            tune["notation"] = "\n".join(notation_lines)

            # ensure all req fields exist
            if not "alt_title" in tune:
                tune["alt_title"] = ""

            print("Parsed tune: ", tune["title"])
            tunes_data.append(tune)

    print("Successfully parsed %d tunes" % tunes_data.size())
    return tunes_data