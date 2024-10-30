/*
 * Developer : Bryan Duggan (bryan.duggan@dit.ie)
 * All code (c)2010 Dublin Institute of Technology. All rights reserved
 */

#pragma once

#include <string>

using namespace std;

class PitchSpeller
{
public:
	static const float RANGE;    
    static const float RATIO;
    static const int ABC_NOTE_RANGE = 33;
    static const int MIDI_NOTE_RANGE = 87;
    static const int MIDI_OFFSET = 21;	
    static const int FUNDAMENTALS = 7;	
	static const char * noteNames[];
    
	float knownFrequencies[ABC_NOTE_RANGE];
    float midiNotes[MIDI_NOTE_RANGE];    
	
	static const char * fundamentalSpellings[];
	static const float fundamentals[];
	float fundamental;
	
	enum pitch_model {FLUTE, WHISTLE};
    
	pitch_model pitchModel;
	
	
	bool isWholeToneInterval(int n, int *  intervals, int numIntervals);
	void makeScale(string mode); 
    void makeMidiNotes();

	const char * spellFrequency(float frequency);
	const char * spellFrequencyAsMidi(float frequency);
	
	PitchSpeller();
};