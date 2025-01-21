#include "BinaryData.h"
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace BinaryData {
    // Model data storage
    const char* features_model_ort = nullptr;
    size_t features_model_ortSize = 0;
    
    const char* cnn_contour_model_json = nullptr;
    size_t cnn_contour_model_jsonSize = 0;
    
    const char* cnn_note_model_json = nullptr;
    size_t cnn_note_model_jsonSize = 0;
    
    const char* cnn_onset_1_model_json = nullptr;
    size_t cnn_onset_1_model_jsonSize = 0;
    
    const char* cnn_onset_2_model_json = nullptr;
    size_t cnn_onset_2_model_jsonSize = 0;

    bool loadFile(const char* path, const char*& data, size_t& outSize) {
        godot::Ref<godot::FileAccess> file = godot::FileAccess::open(path, godot::FileAccess::READ);
        if (file.is_null()) return false;
        
        outSize = file->get_length();
        char* buffer = new char[outSize];
        file->get_buffer((uint8_t*)buffer, outSize);
        data = buffer;
        return true;
    }

    bool loadModels() {
        return loadFile("res://src/ModelData/features_model.onnx", features_model_ort, features_model_ortSize) &&
               loadFile("res://src/ModelData/cnn_contour_model.json", cnn_contour_model_json, cnn_contour_model_jsonSize) &&
               loadFile("res://src/ModelData/cnn_note_model.json", cnn_note_model_json, cnn_note_model_jsonSize) &&
               loadFile("res://src/ModelData/cnn_onset_1_model.json", cnn_onset_1_model_json, cnn_onset_1_model_jsonSize) &&
               loadFile("res://src/ModelData/cnn_onset_2_model.json", cnn_onset_2_model_json, cnn_onset_2_model_jsonSize);
    }
}