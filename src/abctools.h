#ifndef ABCTOOLS_H
#define ABCTOOLS_H

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace tunepal {

class ABCTools : public godot::Object {
    GDCLASS(ABCTools, godot::Object);

private:
    static bool flag;
    
    // Helper methods
    static bool is_valid_note(char c);

protected:
    static void _bind_methods();

public:
    ABCTools();
    ~ABCTools();
    
    // Main processing methods
    static godot::String fix_notation_for_tunepal(const godot::String &notation);
    static godot::String remove_extra_notation(const godot::String &key);
    static godot::String remove_long_notes(const godot::String &key);
    static int skip_headers(const godot::String &tune);
    static godot::String expand_parts(const godot::String &notes);
    static godot::String strip_bar_divisions(const godot::String &notes);
    static godot::String remove_triplet_marks(const godot::String &notes);
    static godot::String expand_long_notes(const godot::String &notes);
    static godot::String strip_whitespace(const godot::String &transcription);
    static godot::String strip_comments(const godot::String &transcription);
    static godot::String strip_advanced_abc(const godot::String &body);
    static godot::String strip_all(const godot::String &key);
    static godot::String ensure_valid_utf8(const godot::String &input);
    
    // Get the status flag
    static bool get_flag();
};

}

#endif // ABCTOOLS_H