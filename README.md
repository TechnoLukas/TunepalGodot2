# TunepalGodot2
Rework of Tunepal though with more modern design.

## Setup instructions for AI transription
1. AI-based transcription from NeuralNote uses dependencies ONNXRuntime and RTNeural

- For development purposes ONNXRuntime for system can be installed from here: https://github.com/microsoft/onnxruntime/releases

- RTNeural is to be installed using:

```
git clone https://github.com/jatinchowdhury18/RTNeural.git
```

2. Setting up Environment Variables:
 
### Windows
 ```
set ONNX_INCLUDE=C:\onnxruntime\onnxruntime-win-x64-gpu-1.20.1\include
set ONNX_LIB=C:\onnxruntime\onnxruntime-win-x64-gpu-1.20.1\lib
set RTNEURAL_INCLUDE=C:\dev\final-project\RTNeural\RTNeural
set RTNEURAL_LIB=C:\dev\final-project\RTNeural\build\RTNeural\Debug
```

### macOS/Linux

export ONNX_INCLUDE=/path/to/onnxruntime/include
export ONNX_LIB=/path/to/onnxruntime/lib
export RTNEURAL_INCLUDE=/path/to/RTNeural/include
export RTNEURAL_LIB=/path/to/RTNeural/build