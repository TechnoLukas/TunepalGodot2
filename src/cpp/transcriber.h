/*
 *  transcriber.h
 *  recording
 *
 *  Created by Bryan Duggan on 16/01/2010.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#pragma once

#include <string>
#include <vector>

using namespace std;

class TranscribedNote
{
public:
	string spelling;
	float frequency;
	float duration;
	float onset;
	float qq;
};	

class Transcriber  {
private:
	float * signal;
	int numSamples;
	vector<TranscribedNote> notes;
	string transcription;
public:
	void setSignal(float * signal);
	string transcribe(float * progress, bool * interrupted, bool midi);
	void postProcess(bool);
	void printTranscription();
	Transcriber(char * audioData, int numSamples);
    Transcriber();
	~Transcriber();
};



