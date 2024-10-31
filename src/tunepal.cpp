#include "tunepal.h"
#include "transcriber.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include<string>
#include<ios>

using namespace godot;
using namespace std;

void Tunepal::_bind_methods() {
	ClassDB::bind_method(D_METHOD("say_hello"), &Tunepal::say_hello);
	ClassDB::bind_method(D_METHOD("edSubstring"), &Tunepal::edSubstring);
	ClassDB::bind_method(D_METHOD("transcribe"), &Tunepal::transcribe);
	ClassDB::bind_method(D_METHOD("findClosest"), &Tunepal::findClosest);
	ClassDB::bind_method(D_METHOD("_sort_by_distance"), &Tunepal::_sort_by_distance);
	ClassDB::bind_method(D_METHOD("finished_searching"), &Tunepal::finished_searching);

	ClassDB::add_signal("Tunepal", MethodInfo("search_completed", PropertyInfo(Variant::ARRAY, "results")));
    
	
}

Tunepal::Tunepal() {
	// Initialize any variables here.
	//time_passed = 0.0;
}

Tunepal::~Tunepal() {
	// Add your cleanup here.
}

void Tunepal::_process(double delta) {
	//time_passed += delta;
	//Vector2 new_position = Vector2(10.0 + (10.0 * sin(time_passed * 2.0)), 10.0 + (10.0 * cos(time_passed * 1.5)));
	//set_position(new_position);
}

int g_fundamental = 3;

godot::String Tunepal::transcribe(const godot::PackedByteArray & signal, const int fundamental)
{
		Transcriber transcriber(signal);

		g_fundamental = fundamental;

		float f = 0.0f;
        bool b = false;
		//return env->NewStringUTF("HELLO!");
        string transcription = transcriber.transcribe(& f, & b, false);
	
		UtilityFunctions::print("i got: ", transcription.c_str());
		return godot::String(transcription.c_str());
        		
}

godot::Array Tunepal::findClosest(const godot::String needle, const godot::Array haystack)
{
    godot::Array matches;
    
    // For each dictionary in the haystack
    for (int i = 0; i < 50; i++)
    {
		if (i % 100 == 0)
		{
			UtilityFunctions::print("i: ", i);
		}
        Dictionary tune = haystack[i];
        String search_key = tune["search_key"];
        
        // Calculate edit distance using search_key
        float distance = edSubstring(needle, search_key, 0);
        
        Dictionary match;
        match["distance"] = distance;
        match["tune"] = tune;
        
        matches.push_back(match);
    }

    // Sort matches by edit distance (lowest to highest)
    matches.sort_custom(Callable(this, "_sort_by_distance"));
    
    // Create result array with top 10 matches
    result.clear();
    int numToReturn = MIN(10, matches.size());
    
    for (int i = 0; i < numToReturn; i++)
    {
        Dictionary match = matches[i];
        Dictionary tune = match["tune"];
        tune["edit_distance"] = match["distance"];
        result.push_back(tune);
    }


	call_deferred("finished_searching");
	// Emit signal with results	
	// Return the top 10 matches
	//
	// 
    return result;
}

void Tunepal::finished_searching()
{
	emit_signal("search_completed", result);
}

bool Tunepal::_sort_by_distance(const Variant &a, const Variant &b) const
{
    Dictionary dict_a = a;
    Dictionary dict_b = b;
    
    float distance_a = dict_a["distance"];
    float distance_b = dict_b["distance"];
    
    return distance_a < distance_b;
}

/*
godot::Array Tunepal::findClosesestMatch(const godot::String needle, const godot::Array haystack)
{
    // Create a vector to store matches with their distances
    std::vector<std::pair<float, Dictionary>> matches;
    matches.reserve(haystack.size());

    // For each dictionary in the haystack
    for (int i = 0; i < haystack.size(); i++)
    {
        Dictionary tune = haystack[i];
        String midi_sequence = tune["midi_sequence"];
        
        // Calculate edit distance
        float distance = edSubstring(needle, midi_sequence);
        
        // Store the distance and the full dictionary
        matches.push_back(std::make_pair(distance, tune));
    }

    // Sort matches by edit distance (lowest to highest)
    std::sort(matches.begin(), matches.end(),
        [](const std::pair<float, Dictionary>& a, const std::pair<float, Dictionary>& b) {
            return a.first < b.first;
        });

    // Create result array with top 10 matches
    godot::Array result;
    int numToReturn = std::min(10, static_cast<int>(matches.size()));
    
    for (int i = 0; i < numToReturn; i++)
    {
        Dictionary matchedTune = matches[i].second;
        // Add the edit distance to the dictionary for reference
        matchedTune["edit_distance"] = matches[i].first;
        result.push_back(matchedTune);
    }

    return result;
}
*/

/*
godot::Array Tunepal::findClosesestMatch(const godot::String needle, const godot::Array haystack)
{

	// The haystack is an array of Dictionary
	// Each dictionary has the following keys:
	// id, midi_sequence, tune_type, time_sig, notation, sourceid, shortName, url, sourcename, title, alt_title, tunepalid, x, midi_file_name, key_sig, search_key
	// Call this function below to return the edit distance between pattern and subsequences of text
	// Tunepal::edSubstring(const godot::String pattern, const godot::String text)
	// The function should return an array of dictionaries, sorted by edit distance lowest to highest
	// Only return the top 10 matches

	

	return godot::Array();
}
*/

int Tunepal::edSubstring(const godot::String pattern, const godot::String text, const int thread_id)
{
	//return 666;
	static int matrix[400][400];
	int pLength = pattern.length();
	int tLength = text.length();
	int difference = 0;

	char sc;
	//UtilityFunctions::print("edsubstring: ", pattern, text, thread_id);
	if (pLength == 0)
	{
		return 0;
	}
	if (tLength == 0)
	{
		return 0;
	}

	
	// Initialise the 0 row
	for (int i = 0; i < tLength + 1; i++)
	{
		matrix[0][i] = 0;
	}
	// Now make the 0 col = 0,1,2,3,4,5,6
	for (int i = 0; i < pLength + 1; i++)
	{
		matrix[i][0] = i;
	}


	for (int i = 1; i <= pLength; i++)
	{
		sc = pattern[i - 1];
		for (int j = 1; j <= tLength; j++)
		{
			int v = matrix[i - 1][j - 1];
			//if ((text.charAt(j - 1) != sc) && (text.charAt(j - 1) != 'Z') && sc != 'Z')                
			if ((text[j - 1] != sc)  && sc != 'Z')
			{
				difference = 1;
			}
			else
			{
				difference = 0;
			}
			matrix[i][j] = UtilityFunctions::min(UtilityFunctions::min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1), v + difference);
		}
	}
	//UtilityFunctions::print("Matrix:");
	// for (int i = 0 ; i <= pLength ; i ++)
	// {
	// 	godot::String line = "";
	// 	for (int j = 0 ; j <= tLength; j ++)
	// 	{
	// 		line += UtilityFunctions::str(matrix[i][j]) + "\t";
	// 	}
	// 	UtilityFunctions::print(line);
	// }
	int min = matrix[pLength][0];
	for (int i = 0; i < tLength + 1; i++)
	{
		int c = matrix[pLength][i];
		// System.out.println(c);
		if (c < min)
		{
			min = c;
		}
	}
	float ed = min;
	return ed;
}

void Tunepal::say_hello()
{
    UtilityFunctions::print("Hello World");
}
