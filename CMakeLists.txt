# Set FMOD root (adjust path as needed)
set(FMOD_ROOT_DIR "${CMAKE_SOURCE_DIR}/fmodstudioapi20312linux/api/core")

include_directories(${FMOD_ROOT_DIR}/inc)
link_directories(${FMOD_ROOT_DIR}/lib)

# Source files
file(GLOB_RECURSE RTDINK_SOURCES
    source/*.cpp
)

# Exclude platform-specific files (Android/iOS/Win)
list(FILTER RTDINK_SOURCES EXCLUDE REGEX ".*Android.*|.*android.*|.*iOS.*|.*ios.*|.*Win.*|.*win.*|.*StackWalker.*")

# Includes
include_directories(
    source
    # Add more include dirs if needed
)

# Executable
add_executable(RTDinkApp ${RTDINK_SOURCES})

# Libraries
find_package(OpenGL REQUIRED)
find_package(PNG REQUIRED)
find_package(JPEG REQUIRED)

set(EXTRA_LIBS pthread X11 ${OPENGL_LIBRARIES} ${PNG_LIBRARIES} ${JPEG_LIBRARIES} curl z)

target_link_libraries(RTDinkApp ${EXTRA_LIBS} ${FMOD_ROOT_DIR}/lib/libfmod.so)
