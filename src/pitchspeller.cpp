/*
 * Developer : Bryan Duggan (bryan.duggan@dit.ie)
 * All code (c)2010 Dublin Institute of Technology. All rights reserved
 */

#include "pitchspeller.h"
#include <math.h>
#include <string>
#include <sstream>
#include <float.h>
#include <godot_cpp/variant/utility_functions.hpp>

//const char * PitchSpeller::noteNames[] =  {"D,", "E,", "F,", "G,", "A,", "B,", "C", "C", "D", "E", "F", "G", "A", "B","c", "c", "d", "e", "f", "g", "a", "b", "c'", "c'", "d'", "e'", "f'", "g'", "a'", "b'", "c''", "c''", "d''"}; 
const char * PitchSpeller::noteNames[] =  {"D", "E", "F", "G", "A", "B", "C", "C", "D", "E", "F", "G", "A", "B","C", "C", "D", "E", "F", "G", "A", "B", "C", "C", "D", "E", "F", "G", "A", "B", "C", "C", "D"}; 

const char * PitchSpeller::fundamentalSpellings[] = {"Bb", "B", "C", "D", "Eb", "F", "G"};

const float PitchSpeller::fundamentals[] = {233.08f, 246.94f, 261.63f, 293.66f, 311.13f, 349.23f, 392.00f};

const float PitchSpeller::RANGE = 0.1f;    
const float PitchSpeller::RATIO = 1.05946309436f;

extern int g_fundamental;
using namespace godot;



PitchSpeller::PitchSpeller()
{
	char msg[1024];
	sprintf(msg, "Fundamental: %i %s\n", g_fundamental, PitchSpeller::fundamentalSpellings[g_fundamental]);
	
	UtilityFunctions::print(msg);
	
	fundamental = fundamentals[g_fundamental];
	pitchModel = PitchSpeller::FLUTE;
}

bool PitchSpeller::isWholeToneInterval(int n, int *  intervals, int numIntervals) 
{
	n = n % 8;
	for (int i = 0 ; i < numIntervals; i ++)
	{
		if (n == intervals[i])
		{
			return true;
		}
	}
	return false;
}

void PitchSpeller::makeMidiNotes()
{
    midiNotes[0] = 27.5f;
    for (int i = 1 ; i < MIDI_NOTE_RANGE ; i ++)
    {
        midiNotes[i] = midiNotes[i - 1] * RATIO;
    }
}

void PitchSpeller::makeScale(string mode) 
{
	
	// W - W - H - W - W - H - H - H
	int majorKeyIntervals[] = {1, 2, 4, 5};
	if (mode == "major")
	{
		if (pitchModel == PitchSpeller::FLUTE)
		{
			knownFrequencies[0] = fundamental / (float) pow(RATIO, 12);
		}
		else
		{   // Use the whistle pitch model
			knownFrequencies[0] = fundamental;
		}
		// W - W - H - W - W - W - H
		for (int i = 1 ; i < ABC_NOTE_RANGE ; i ++)
		{
			if (isWholeToneInterval(i, majorKeyIntervals, 4))
			{
				knownFrequencies[i] = knownFrequencies[i - 1] * RATIO * RATIO;
			}
			else
			{
				knownFrequencies[i] = knownFrequencies[i - 1] * RATIO;
			}               
		}
	}
	
	/*
	 printf("FREQUENCIES:\n");
	for (int i = 0 ; i < ABC_NOTE_RANGE ; i ++)
	{
		printf("%s\t%f\n:", noteNames[i], knownFrequencies[i], RANGE);
	}
	 */
	
}

const char * PitchSpeller::spellFrequencyAsMidi(float frequency)
{
    int minIndex = 0;
	float min = FLT_MAX;
	
	if ((frequency < midiNotes[0]) || (frequency > midiNotes[MIDI_NOTE_RANGE - 1]))
	{
		return "Z";
	}
    
	for (int j = 0 ; j < MIDI_NOTE_RANGE ; j ++)
	{
		float difference = fabs(frequency - midiNotes[j]);
		
		if (difference < min)
		{
			minIndex = j;
			min = difference;
		}
		
	}
    
    int i = (minIndex + 21);
    std::string s;
    std::stringstream out;
    out << i;
    s = out.str();    
	return s.c_str();
}


const char * PitchSpeller::spellFrequency(float frequency)
{
	int minIndex = 0;
	float min = FLT_MAX;
	
	if ((frequency < knownFrequencies[0]) || (frequency > knownFrequencies[ABC_NOTE_RANGE - 1]))
	{
		return "Z";
	}

	for (int j = 0 ; j < ABC_NOTE_RANGE ; j ++)
	{
		float difference = fabs(frequency - knownFrequencies[j]);
		
		if (difference < min)
		{
			minIndex = j;
			min = difference;
		}
		
	}
	return noteNames[minIndex];
}



