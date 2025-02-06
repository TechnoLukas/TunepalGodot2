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

## Pre requisites:

### Linux Build 

Run the following command
```
$ sudo apt-get install libsqlite3-dev libcurl4-openssl-dev nlohmann-json3-dev
```

### Windows Build

```
.\vcpkg install curl:x64-windows
.\vcpkg install nlohmann-json:x64-windows
.\vcpkg install sqlite3:x64-windows
```