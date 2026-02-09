cmake_minimum_required(VERSION 3.10)
project(RTDinkApp)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add platform defines
add_definitions(-DPLATFORM_LINUX -DRT_ENABLE_FMOD -DRT_USE_LIBCURL -DRT_PNG_SUPPORT -DRT_JPG_SUPPORT)

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
find_package(PkgConfig REQUIRED)
pkg_check_modules(FMOD REQUIRED fmod)
pkg_check_modules(CURL REQUIRED libcurl)

find_package(OpenGL REQUIRED)
find_package(PNG REQUIRED)
find_package(JPEG REQUIRED)

# Link libraries
set(EXTRA_LIBS pthread X11 ${OPENGL_LIBRARIES} ${PNG_LIBRARIES} ${JPEG_LIBRARIES} ${CURL_LIBRARIES} ${FMOD_LIBRARIES} z)

target_link_libraries(RTDinkApp ${EXTRA_LIBS})
