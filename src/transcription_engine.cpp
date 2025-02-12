/*#include "transcription_engine.h"

TranscriptionEngine::TranscriptionEngine() {
    basicPitch = std::make_unique<BasicPitch>();
    setParameters(); // Set default parameters
}

void TranscriptionEngine::setParameters(float noteSensitivity, 
                                      float splitSensitivity,
                                      float minNoteDurationMs) {
    basicPitch->setParameters(noteSensitivity, splitSensitivity, minNoteDurationMs);
}

void TranscriptionEngine::transcribeAudio(const float* audioData, int numSamples) {
    basicPitch->reset();
    basicPitch->transcribeToMIDI(const_cast<float*>(audioData), numSamples);
}

const std::vector<Notes::Event>& TranscriptionEngine::getNoteEvents() const {
    return basicPitch->getNoteEvents();
}
*/