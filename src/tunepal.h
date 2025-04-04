#ifndef TUNEPAL_H
#define TUNEPAL_H

#include <godot_cpp/classes/node2d.hpp>

namespace godot {

class Tunepal : public Node2D {
	GDCLASS(Tunepal, Node2D)

private:
	godot::Array result;

protected:
	static void _bind_methods();

public:
	Tunepal();
	~Tunepal();

	void _process(double delta) override;

	void say_hello();

	int edSubstring(const godot::String pattern_param, const godot::String text_param, const int thread_id);
	int edSubstringOld(const godot::String pattern_param, const godot::String text_param, const int thread_id);

	godot::String transcribe(const godot::PackedByteArray & signal, const int fundamental, int sampleRate, float duration);

	godot::Array findClosest(const godot::String needle, const godot::Array haystack);

	bool _sort_by_distance(const Variant &a, const Variant &b) const;

	void finished_searching();

	void create_midi_file(godot::String notation, godot::String abc_file_name, godot::String midi_file_name, int speed, int transpose, int melody, int chords);
	void create_html_file(godot::String notation, godot::String abc_file_name, godot::String midi_file_name, int speed, int transpose, int melody, int chords);

	void create_svg_file(godot::String notation, godot::String abc_file_name, godot::String svg_file_name);

    // int edSubstring(string
};

}

#endif