#pragma once
#include "Model/BasicPitch.h"
#include <vector>
#include <memory>

class TranscriptionEngine {
public:
    TranscriptionEngine();
    void transcribeAudio(const float* audioData, int numSamples);
    const std::vector<Notes::Event>& getNoteEvents() const;
    void setParameters(float noteSensitivity = 0.7f, 
                      float splitSensitivity = 0.5f,
                      float minNoteDurationMs = 50.0f);
private:
    std::unique_ptr<BasicPitch> basicPitch;
};