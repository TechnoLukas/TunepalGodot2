#include "transcriber.h"
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <memory>
#include <stdexcept>

using namespace godot;
/*

void process_recording(const PackedByteArray& audioData) {
    try {
        if (audioData.size() == 0) {
            UtilityFunctions::print("Error: Empty audio data");
            return;
        }

        Transcriber transcriber(audioData);
        
        // AI-based transcription
        godot::String aiTranscription = String(transcriber.transcribeWithAI().c_str());
        if (!aiTranscription.is_empty()) {
            UtilityFunctions::print("AI Transcription: ", aiTranscription);
        } else {
            UtilityFunctions::print("AI Transcription failed");
        }
        
        // Traditional transcription
        godot::String traditionalTranscription = String(transcriber.transcribe(nullptr, nullptr, false).c_str());
        if (!traditionalTranscription.is_empty()) {
            UtilityFunctions::print("Traditional Transcription: ", traditionalTranscription);
        } else {
            UtilityFunctions::print("Traditional Transcription failed");
        }
    }
    catch (const std::exception& e) {
        // UtilityFunctions::print("Error processing recording: ", e.what());
    }
}

*

int main() {
    return 0;
}


// #include <string>
// #include <stdio.h>
// #include "fft.h"
// #include "transcriber.h"
// #include "tunepalconstants.h"
// #include "utils.h"


// using namespace std;

// // int g_fundamental = 3;

// int main()
// {
//     /*
//      * float progress;
//     bool interrupted;
//     int numSamples = SAMPLE_RATE * SAMPLE_TIME;
//     float * signal = new float[numSamples];


//      Transcriber transcriber;
//     transcriber.setSignal(signal);
//     transcriber.transcribe(& progress, & interrupted);
//     */
//     // createMidiFile("X:100\nABCDEFGABCDEFG", "temp.mid", 1, 1);
//     //delete signal;
//     return 0;
// }