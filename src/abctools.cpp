#include "abctools.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/reg_ex.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <algorithm>
#include <cctype>

namespace tunepal {

// Initialize static member
bool ABCTools::flag = true;

ABCTools::ABCTools() {
    
}

ABCTools::~ABCTools() {
    
}

bool ABCTools::is_valid_note(char c) {
    return (c >= 'A' && c <= 'G') || (c >= 'a' && c <= 'g');
}

godot::String ABCTools::fix_notation_for_tunepal(const godot::String &notation) {
    godot::String result = notation;
    
    // Replace accented characters
    const std::pair<const char*, const char*> replacements[] = {
        {"á", "\\\'a"}, {"é", "\\\'e"}, {"í", "\\\'i"}, {"ó", "\\\'o"}, {"ú", "\\\'u"},
        {"Á", "\\\'A"}, {"É", "\\\'E"}, {"Í", "\\\'I"}, {"Ó", "\\\'O"}, {"Ú", "\\\'U"}
    };
    
    for (const auto &pair : replacements) {
        result = result.replace(pair.first, pair.second);
    }
    
    if (result.find("I:linebreak $") != -1) {
        int tune_start = skip_headers(result);
        godot::String just_tune = result.substr(tune_start);
        
        just_tune = just_tune.replace("\r", "");
        just_tune = just_tune.replace("\r\n", "");
        just_tune = just_tune.replace("\n", "");
        just_tune = just_tune.replace("$ ", "$");
        just_tune = just_tune.replace("$", "\n");
        
        // Use a regex to replace all non-newline occurrences of w: with \nw:
        godot::Ref<godot::RegEx> regex;
        regex.instantiate();
        regex->compile("[^\\n]w:");
        just_tune = regex->sub(just_tune, "\nw:", true);
        
        result = result.substr(0, tune_start) + just_tune;
    }
    
    return result;
}

godot::String ABCTools::remove_extra_notation(const godot::String &key) {
    godot::String ret = key;
    
    // Remove basic notation marks
    const char* to_remove[] = {">", "<", "/", "\\", "(", ")", "-", "!", "_"};
    for (const char* mark : to_remove) {
        ret = ret.replace(mark, "");
    }
    
    // Remove guitar chords using regex
    godot::Ref<godot::RegEx> regex;
    regex.instantiate();
    
    for (int i = 1; i <= 5; i++) {
        godot::String pattern = "\\[.{" + godot::String::num_int64(i) + "}\\]";
        regex->compile(pattern);
        ret = regex->sub(ret, "", true);
    }
    
    // Catch any remaining guitar chords with wildcard pattern
    regex->compile("\\[.*?\\]");
    ret = regex->sub(ret, "", true);
    
    // Keep only letters A-G and a-g
    godot::String result;
    for (int i = 0; i < ret.length(); i++) {
        char c = ret[i];
        if ((c >= 'A' && c <= 'G') || (c >= 'a' && c <= 'g')) {
            result += c;
        }
    }
    
    return result;
}

godot::String ABCTools::remove_long_notes(const godot::String &key) {
    godot::String result;
    char last_char = '*';  // Start with a character that won't match any note
    
    for (int i = 0; i < key.length(); i++) {
        char current = key[i];
        if (current != last_char) {
            result += current;
            last_char = current;
        }
    }
    
    return result;
}

int ABCTools::skip_headers(const godot::String &tune) {
    int i = 0;
    int in_chars = 0;
    bool in_header = true;
    
    while (i < tune.length() && in_header) {
        char c = tune[i];
        
        if (in_chars == 1) {
            if ((c == ':' && tune[i-1] != '|') || 
                (c == '%' && tune[i-1] == '%')) {
                in_header = true;
            } else {
                in_header = false;
                i -= 2;
            }
        }
        
        if (c == '\r' || c == '\n') {
            in_chars = -1;
        }
        
        i++;
        in_chars++;
    }
    
    return i;
}

godot::String ABCTools::expand_parts(const godot::String &notes) {
    godot::String ret_value = notes;
    
    try {
        int start = 0;
        int end = 0;
        const char* end_token = ":|";
        int count = 0;
        
        while (true) {
            if (count > 10) {
                godot::UtilityFunctions::print("Too many parts in tune: ", notes);
                break;
            }
            
            count++;
            end = ret_value.find(end_token);
            
            if (end == -1) {
                break;
            } else {
                int new_start = ret_value.rfind("|:", end);
                if (new_start != -1) {
                    start = new_start + 2;
                }
                
                if ((ret_value.length() > end + 2) && 
                    std::isdigit(ret_value[end + 2])) {
                    
                    int num_special_bars = 1;
                    godot::String expanded;
                    int normal_part = ret_value.rfind("|", end);
                    
                    if (!std::isdigit(ret_value[normal_part + 1])) {
                        normal_part = ret_value.rfind("|", normal_part - 1);
                        num_special_bars++;
                    }
                    
                    expanded += ret_value.substr(start, normal_part - start);
                    expanded += "|";
                    expanded += ret_value.substr(normal_part + 2, end - normal_part - 2);
                    
                    int second_time = end;
                    while (num_special_bars-- > 0) {
                        second_time = ret_value.find("|", second_time + 2);
                    }
                    
                    expanded += "|";
                    expanded += ret_value.substr(start, normal_part - start);
                    expanded += "|";
                    expanded += ret_value.substr(end + 3, second_time - end - 3);
                    expanded += "|";
                    
                    ret_value = ret_value.substr(0, start) + expanded + ret_value.substr(second_time);
                } else {
                    godot::String expanded;
                    expanded += ret_value.substr(start, end - start);
                    expanded += "|";
                    expanded += ret_value.substr(start, end - start);
                    
                    ret_value = ret_value.substr(0, start) + expanded + ret_value.substr(end + 2);
                    start = start + expanded.length();
                }
            }
        }
    } catch (...) {
        flag = false;
        ret_value = notes;
    }
    
    return ret_value;
}

godot::String ABCTools::strip_bar_divisions(const godot::String &notes) {
    godot::String result;
    
    for (int i = 0; i < notes.length(); i++) {
        char c = notes[i];
        if (c != '|' && c != ':') {
            result += c;
        }
    }
    
    return result;
}

godot::String ABCTools::remove_triplet_marks(const godot::String &notes) {
    godot::String result;
    
    for (int i = 0; i < notes.length(); i++) {
        char c = notes[i];
        if (c == '(' && i + 1 < notes.length() && std::isdigit(notes[i + 1])) {
            i++; // Skip the digit
            continue;
        }
        result += c;
    }
    
    return result;
}

godot::String ABCTools::expand_long_notes(const godot::String &notes) {
    godot::String ret_value;
    bool in_ornament = false;
    
    // First pass - remove ornaments and certain characters
    for (int i = 0; i < notes.length(); i++) {
        char c = notes[i];
        
        if (c == '{') {
            in_ornament = true;
            continue;
        }
        
        if (c == '}') {
            in_ornament = false;
            continue;
        }
        
        if (!in_ornament && c != '~' && c != ',' && c != '=' && c != '^' && c != '\'') {
            ret_value += c;
        }
    }
    
    // Second pass - expand long notes (e.g., A2 becomes AA)
    for (int i = 1; i < ret_value.length(); i++) {
        char c = ret_value[i];
        char p = ret_value[i - 1];
        
        // If it's a long note (digit after letter)
        if (std::isdigit(c) && is_valid_note(p)) {
            godot::String expanded;
            int how_many = c - '0';  // Convert char to int
            
            for (int j = 0; j < how_many; j++) {
                expanded += p;
            }
            
            ret_value = ret_value.substr(0, i - 1) + expanded + ret_value.substr(i + 1);
            i = i - 1 + expanded.length() - 1; // Adjust index for the expanded section
        }
    }
    
    return ret_value;
}

godot::String ABCTools::strip_whitespace(const godot::String &transcription) {
    godot::String ret_value;
    
    for (int i = 0; i < transcription.length(); i++) {
        char c = transcription[i];
        if (c != ' ' && c != '\r' && c != '\n') {
            ret_value += c;
        }
    }
    
    return ret_value;
}

godot::String ABCTools::strip_comments(const godot::String &transcription) {
    godot::String ret_value;
    bool in_comment = false;
    
    for (int i = 0; i < transcription.length(); i++) {
        char c = transcription[i];
        
        if (c == '"') {
            if (in_comment) {
                in_comment = false;
                continue;
            } else {
                in_comment = true;
            }
        }
        
        if (!in_comment) {
            ret_value += c;
        }
    }
    
    return ret_value;
}

godot::String ABCTools::strip_advanced_abc(const godot::String &body) {
    godot::String result = body;
    
    result = result.replace("!fermata!", "");
    result = result.replace("!trill)!", "");
    result = result.replace("!trill(!", "");
    result = result.replace("!turn!", "");
    
    return result;
}

godot::String ABCTools::strip_all(const godot::String &key) {
    flag = true;
    
    // Create a copy to work with
    godot::String result = key;
    
    // Apply all transformations in sequence
    result = strip_comments(result);
    result = strip_whitespace(result);
    result = expand_long_notes(result);
    result = expand_parts(result);
    result = strip_bar_divisions(result);
    result = remove_triplet_marks(result);
    result = remove_extra_notation(result);
    result = strip_advanced_abc(result);
    
    return result.to_upper();
}

bool ABCTools::get_flag() {
    return flag;
}

void ABCTools::_bind_methods() {
    // Register all methods to be accessible from GDScript
    godot::ClassDB::bind_static_method("ABCTools", godot::D_METHOD("fix_notation_for_tunepal", "notation"), &ABCTools::fix_notation_for_tunepal);
    godot::ClassDB::bind_static_method("ABCTools", godot::D_METHOD("remove_extra_notation", "key"), &ABCTools::remove_extra_notation);
    godot::ClassDB::bind_static_method("ABCTools", godot::D_METHOD("remove_long_notes", "key"), &ABCTools::remove_long_notes);
    godot::ClassDB::bind_static_method("ABCTools", godot::D_METHOD("skip_headers", "tune"), &ABCTools::skip_headers);
    godot::ClassDB::bind_static_method("ABCTools", godot::D_METHOD("expand_parts", "notes"), &ABCTools::expand_parts);
    godot::ClassDB::bind_static_method("ABCTools", godot::D_METHOD("strip_bar_divisions", "notes"), &ABCTools::strip_bar_divisions);
    godot::ClassDB::bind_static_method("ABCTools", godot::D_METHOD("remove_triplet_marks", "notes"), &ABCTools::remove_triplet_marks);
    godot::ClassDB::bind_static_method("ABCTools", godot::D_METHOD("expand_long_notes", "notes"), &ABCTools::expand_long_notes);
    godot::ClassDB::bind_static_method("ABCTools", godot::D_METHOD("strip_whitespace", "transcription"), &ABCTools::strip_whitespace);
    godot::ClassDB::bind_static_method("ABCTools", godot::D_METHOD("strip_comments", "transcription"), &ABCTools::strip_comments);
    godot::ClassDB::bind_static_method("ABCTools", godot::D_METHOD("strip_advanced_abc", "body"), &ABCTools::strip_advanced_abc);
    godot::ClassDB::bind_static_method("ABCTools", godot::D_METHOD("strip_all", "key"), &ABCTools::strip_all);
    godot::ClassDB::bind_static_method("ABCTools", godot::D_METHOD("get_flag"), &ABCTools::get_flag);
    
    // Add a static property for the flag
    ADD_GROUP("State", "");
    godot::ClassDB::bind_static_method("ABCTools", godot::D_METHOD("get_flag"), &ABCTools::get_flag);
}

} // namespace tunepal