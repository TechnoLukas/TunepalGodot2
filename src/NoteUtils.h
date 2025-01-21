#pragma once
#include <cmath>

namespace NoteUtils {
    inline float midiToFrequency(int midiNote) {
        return 440.0f * std::pow(2.0f, (midiNote - 69.0f) / 12.0f);
    }
    
    inline int frequencyToMidi(float frequency) {
        return static_cast<int>(std::round(12.0f * std::log2(frequency / 440.0f) + 69.0f));
    }

    // Add alias for backward compatibility
    inline int hzToMidi(float frequency) {
        return frequencyToMidi(frequency);
    }
}