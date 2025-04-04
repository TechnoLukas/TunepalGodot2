/*
 *  transcriber.h
 *  recording
 *
 *  Created by Bryan Duggan on 16/01/2010.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#pragma once
#include <memory>
#include <string>
#include <vector>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
// #include "transcription_engine.h"

using namespace std;

class TranscribedNote {
public:
    string spelling;
    float frequency;
    float duration;
    float onset;
    float qq;
};

class Transcriber {
private:
    float* signal;
    int numSamples;
    int sampleRate;
    float duration;
    vector<TranscribedNote> notes;
    string transcription;
    // std::unique_ptr<TranscriptionEngine> transcriptionEngine;

public:
    // Constructors
    Transcriber();
    explicit Transcriber(const godot::PackedByteArray& audioData, int sampleRate, float duration);
    ~Transcriber();

    // Member functions
    void setSignal(float* signal);
    string transcribe(float* progress, bool * interrupted, bool midi);
    // string transcribeWithAI();
    void postProcess(bool midi);
    void printTranscription();
};

