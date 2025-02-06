# TunepalGodot2
Rework of Tunepal though with more modern design.

## Setup instructions for AI transription
1. Ensure to add all submodules:

```
git submodule update --init --recursive
```

2. Ensure required dependencies are installed for your system ONNXRuntime

https://github.com/microsoft/onnxruntime/releases/tag/v1.20.1

3. Add ONNX_ROOT environment variable with your install path for ONNXRuntime OR Update ONNXRuntime Path in SConstruct to include in build

