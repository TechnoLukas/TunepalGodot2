#!/usr/bin/env python
import os
import sys
from SCons.Script import Glob

env = SConscript("godot-cpp/SConstruct")

#env = Environment()

# Enable exceptions
env.Append(CXXFLAGS=['-fexceptions'])

# Supress warnings
env.Append(CCFLAGS=['-w'])
# For reference:
# - CCFLAGS are compilation flags shared between C and C++
# - CFLAGS are for C-specific compilation flags
# - CXXFLAGS are for C++-specific compilation flags
# - CPPFLAGS are for pre-processor flags
# - CPPDEFINES are for pre-processor defines
# - LINKFLAGS are for linking flags

# tweak this if you want to use different folders, or more folders, to store your source code in.
# env.Append(CPPPATH=["src/", "model/", "src/ModelData" , "src/abcm2ps/"]) 
env.Append(CPPPATH=["src/", "src/abcm2ps/"]) 
# sources = Glob("src/*.c*") + Glob("model/*.c*") + Glob("ThirdParty/RTNeural*") # + Glob("src/abcm2ps/*.c")

# env.Append(LIBS=["sqlite3"])

# Define source directories more specifically
src_dirs = [
    "src/*.cpp",
    # "src/Model/*.cpp",
    "src/abc2midi/*.c",
    "src/abcm2ps/*.c",
]

sources = []
for dir in src_dirs:
    sources.extend(Glob(dir))

# # ONNX Runtime setup
# onnx_default_path = os.getenv('ONNX_ROOT', '/home/skooter500/onnxruntime-linux-x64-1.20.1') # replace hard coded path
# onnx_include = os.path.join(onnx_default_path, 'include')
# onnx_lib = os.path.join(onnx_default_path, 'lib')


# # Verify ONNX paths exist
# if not os.path.exists(onnx_include) or not os.path.exists(onnx_lib):
#     print("Error: ONNX Runtime paths not found!")
#     print(f"Include: {onnx_include}")
#     print(f"Lib: {onnx_lib}")
#     sys.exit(1)

# # Add RTNeural
# rtneural_include = "#src/ThirdParty/external/RTNeural"

# # Update environment
# env.Append(CPPPATH=[
#     "src/",
#     "src/Model/",
#     "src/ThirdParty/external",  # RTNeural root folder
#     "src/ThirdParty/external/RTNeural",  # RTNeural include folder
#     onnx_include,
#     rtneural_include
# ])
# env.Append(LIBPATH=[onnx_lib])
# env.Append(LIBS=["onnxruntime"])

# Add RTNeural as header-only library
# env.Append(CPPDEFINES=[
#     "RTNEURAL_EIGEN_SUPPORTED=1"  # Use Eigen backend
#     "RTNEURAL_USE_EIGEN=1"
# ])

# Define compiler flags and definitions
if env["platform"] == "windows":
    env.Append(CCFLAGS=["-fexceptions"])  # Enable exception handling
    env.Append(CPPDEFINES=[
        "RTNEURAL_DEFAULT_ALIGNMENT=16",
        # "RTNEURAL_EIGEN_SUPPORTED=1",
        # "RTNEURAL_USE_EIGEN=1"
    ])

if env["platform"] == "macos":
    library = env.SharedLibrary(
        "addons/tunepal/bin/libtunepal.{}.{}.framework/libtunepal.{}.{}".format(
            env["platform"], env["target"], env["platform"], env["target"]
        ),
        source=sources,
    )
else:
    library = env.SharedLibrary(
        "addons/tunepal/bin/libtunepal{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
        source=sources,
    )

Default(library)
