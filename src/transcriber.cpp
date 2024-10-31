/*
 * Developer : Bryan Duggan (bryan.duggan@dit.ie)
 * All code (c)2010 Dublin Institute of Technology. All rights reserved
 */

#include "transcriber.h"
#include "tunepalconstants.h"
#include "pitchspeller.h"
#include "FuzzyHistogram.h"
#include "fft.h"
#include "PitchDetector.h"

#include <vector>

#include <math.h>
#include <iostream>

#include <godot_cpp/variant/utility_functions.hpp>


using namespace std;
using namespace godot;


void Transcriber::setSignal(float * signal)
{
	this->signal = signal;
}

string Transcriber::transcribe(float * progress, bool * interrupted, bool midi)
{
	PitchSpeller speller;
	string lastNote;
	speller.makeScale("major");
    speller.makeMidiNotes();
	float spectrum[(int) FRAME_SIZE / 2];
	float hopSize = FRAME_SIZE * (1.0f - OVERLAP);
	
	int numHops = numSamples / hopSize;
	
	int i;
	for (i = 0 ; i < numHops ; i ++)
	{
		int startAt = hopSize * i;
		* progress = (float) i / (float) numHops;
		// if (* interrupted)
		// {
		// 	return "";
		// }
		
		// can we get another frame out without going over?
		if (startAt + FRAME_SIZE >= numSamples)
		{
			break;
		}
		
		WindowFunc(HANNING, FRAME_SIZE, signal + startAt);
		PowerSpectrum(FRAME_SIZE, signal + startAt, spectrum);
    
		float frequency = mikelsFrequency(spectrum, FRAME_SIZE / 2, SAMPLE_RATE, FRAME_SIZE);
		//UtilityFunctions::print("freq: ", frequency);
		
        string currentNote;
		if (midi)
        {
             currentNote = speller.spellFrequencyAsMidi(frequency);
        }
        else {
            currentNote = speller.spellFrequency(frequency);
        }
		//UtilityFunctions::print("currentNote: ", currentNote.c_str());
		
		if (currentNote != lastNote)
        {
            TranscribedNote note;
            note.spelling = currentNote;
            note.frequency = frequency;					
            note.onset = ((float) startAt) / SAMPLE_RATE;			
            lastNote = currentNote; 
            notes.push_back(note);
        }

	}
	numHops = i;
	printTranscription();
	postProcess(midi);
	UtilityFunctions::print("transcription: ", transcription.c_str());
	return transcription;
}

void Transcriber::printTranscription()
{
	char str[2048];
;	for (int i = 0 ; i < notes.size() ; i ++)
	{
		sprintf(str, "%s %f %f %f %f\n", notes[i].spelling.c_str(), notes[i].frequency, notes[i].qq, notes[i].onset, notes[i].duration);
		UtilityFunctions::print(str);
	}
		
}

void Transcriber::postProcess(bool midi)
{
	transcription = "";
	// put in the durations	
	for (int i = 0 ; i < (notes.size() - 1) ; i ++)
	{
		notes[i].duration = notes[i + 1].onset - notes[i].onset;
	}
	// Now do the last note
	notes[notes.size() - 1].duration = SAMPLE_TIME - notes[notes.size() - 1].onset;
			
	// Hardcode!!!
	float durations[10000];
	for (int i = 0 ; i < notes.size() ; i ++)
	{
		durations[i] = notes[i].duration;
	}
	
	FuzzyHistogram fuzzyHistogram;
	float quaverLength = fuzzyHistogram.calculatePeek(durations, notes.size(), 0.33f, 0.1f);
	UtilityFunctions::print("quaverLength ", quaverLength);
	// Now calculate the quaver quantisation for each note
	for (int i = 0 ; i < notes.size() ; i ++)
	{
		notes[i].qq = round((float)notes[i].duration / (float)quaverLength);	
	}	
	printTranscription();
	
	//Convert the sequence of notes to a string, removing the 0 durations and expanding the multiople durations
	bool pastSilence = false;
	for (int i = 0 ; i < notes.size() ; i ++)
	{
		// Skip Z's at the start
		UtilityFunctions::print(notes[i].spelling.c_str());
		if (notes[i].spelling != "Z")
		{
			pastSilence = true;
		}
		for (int j = 0 ; j < notes[i].qq ; j ++)
		{				
			if (pastSilence)
			{
				if (notes[i].spelling != "Z")
				{
					transcription += notes[i].spelling;
				}
                if (midi && notes[i].spelling != "Z")
                {
                    transcription += ",";
                }            
			}
		}
	}	
	UtilityFunctions::print(transcription.c_str());
	// Remove Z's at the end
	if (transcription.size() > 0)
	{
		int i = transcription.size() - 1;
		while (i > 0)
		{
			if (transcription[i] == 'Z')
			{
				transcription.erase(i, 1);
				i --;
			}
			else
			{
				break;
			}
		}		
	}
	UtilityFunctions::print(transcription.c_str());
	// Count the Z's
	if (transcription.size() > 0)
	{
		int numZ = 0;
		for (int i = 0 ; i < transcription.size() ; i ++)
		{
			if (transcription[i] == 'Z')
			{
				numZ ++;
			}		
		}
		// If more than 50%, we heard mostly silence
		float normalZ = (float) numZ / (float) transcription.size();
		UtilityFunctions::print("Normal z ", normalZ);
		if (normalZ > 0.5f)
		{
			UtilityFunctions::print("Transcription is mostly silence, so I'm removing all the notes");
			transcription = "";
		}
	}	
}

Transcriber::Transcriber()
{
    numSamples = SAMPLE_RATE * SAMPLE_TIME;
}

Transcriber::Transcriber(const godot::PackedByteArray& audioData)
{
    // Godot is sending us stereo data, so we need to convert it to mono
    int numSamples = audioData.size() / 2;
    signal = new float[numSamples];
    
    for (int signalIndex = 0; signalIndex < numSamples; signalIndex++)
    {
        // Get the two bytes that make up our 16-bit sample
        uint8_t b0 = audioData[signalIndex * 4];        // Low byte
        uint8_t b1 = audioData[signalIndex * 4 + 1];    // High byte
        
        // Combine the bytes into a 16-bit signed integer
        int16_t sample = (b1 << 8) | b0;
        
        // Convert to float in the range [-1.0, 1.0]
        signal[signalIndex] = sample / 32768.0f;
        
        // if (signalIndex < 5000)
        // {
        //     UtilityFunctions::print(signal[signalIndex]);
        // }
    }
    
    this->numSamples = numSamples;
}

/*
Transcriber::Transcriber(const godot::PackedByteArray & audioData)
{
	// Godot is sending us stereo data, so we need to convert it to mono
	int numSamples = audioData.size() / 2; 
	signal = new float[numSamples];
	UtilityFunctions::print("numSamples: ", numSamples);

	// for (int signalIndex = 0 ; signalIndex < numSamples; signalIndex ++)
	// {
	// 	signal[signalIndex] = ((audioData[(signalIndex * 2) + 1] << 8) + audioData[signalIndex * 2]);
	// }

	


	for (int signalIndex = 0 ; signalIndex < numSamples; signalIndex ++)
	{		

		unsigned char b0, b1;

		b0 = audioData[(signalIndex * 2) + 1];
		b1 = audioData[signalIndex * 2];

		signal[signalIndex] = ((audioData[(signalIndex * 2) + 1] << 8) + audioData[signalIndex * 2]);
		signal[signalIndex] = (b0 << 8) + b1;

		if (signalIndex < 5000)
		{
			//UtilityFunctions::print("audiodata: ", audioData[signalIndex * 4]);
			UtilityFunctions::print(signal[signalIndex]);
		}
	}  

	this->numSamples = numSamples;
	// }
	// 	int numSamples = audioData.size() / 2;
	// 	signal = new float[numSamples];
	// 	UtilityFunctions::print("numSamples: ", numSamples);
	// 	for (int signalIndex = 0 ; signalIndex < numSamples; signalIndex ++)
	// 	{		
	// 		signal[signalIndex] = ((audioData[(signalIndex * 2) + 1] << 8) + audioData[signalIndex * 2]);

	// 		if (signalIndex < 1000)
	// 		{
	// 			UtilityFunctions::print("audiodata: ", audioData[signalIndex]);
	// 			UtilityFunctions::print("signal: ", signal[signalIndex]);
	// 		}
	// 	}  
	
	this->numSamples = numSamples;
}

*/

Transcriber::~Transcriber()
{
	//delete signal;
}
