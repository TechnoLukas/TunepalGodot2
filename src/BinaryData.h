#pragma once
#include <cstddef>

namespace BinaryData {
    extern const char* features_model_ort;
    extern size_t features_model_ortSize;
    
    extern const char* cnn_contour_model_json;
    extern size_t cnn_contour_model_jsonSize;
    
    extern const char* cnn_note_model_json;
    extern size_t cnn_note_model_jsonSize;
    
    extern const char* cnn_onset_1_model_json;
    extern size_t cnn_onset_1_model_jsonSize;
    
    extern const char* cnn_onset_2_model_json;
    extern size_t cnn_onset_2_model_jsonSize;
    
    bool loadModels();
}