cmake_minimum_required(VERSION 3.10)
project(RTDinkApp)

set(CMAKE_CXX_STANDARD 14)

# FMOD
set(FMOD_ROOT_DIR "${CMAKE_SOURCE_DIR}/fmodstudio/api/core")
include_directories(${FMOD_ROOT_DIR}/inc)
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
  set(FMOD_LIB_DIR "${FMOD_ROOT_DIR}/lib/x86_64")
else()
  set(FMOD_LIB_DIR "${FMOD_ROOT_DIR}/lib/x86")
endif()
link_directories(${FMOD_LIB_DIR})

# Platform defines for Proton SDK
if(UNIX AND NOT APPLE)
  add_definitions(-DRTLINUX -DPLATFORM_LINUX -DC_GL_MODE -DRT_USE_SDL -DRT_PNG_SUPPORT -DRT_JPG_SUPPORT)
elseif(APPLE)
  add_definitions(-DPLATFORM_OSX -DC_GL_MODE)
elseif(WIN32)
  add_definitions(-DWIN32 -DC_GL_MODE)
endif()

# Source files
file(GLOB_RECURSE RTDINK_SOURCES
    source/*.cpp
)

# Exclude platform-specific files (Android/iOS)
list(FILTER RTDINK_SOURCES EXCLUDE REGEX ".*Android.*|.*android.*|.*iOS.*|.*ios.*")

# Includes
include_directories(
    ${CMAKE_SOURCE_DIR}
    source
    proton/shared
    proton/shared/util/boost
    proton/shared/ClanLib-2.0/Sources
    proton/RTSimpleApp/source
)

# Proton shared sources needed by RTDink
set(PROTON "${CMAKE_SOURCE_DIR}/proton/shared")
set(PROTON_SOURCES
    ${PROTON}/BaseApp.cpp
    ${PROTON}/PlatformSetup.cpp
    ${PROTON}/linux/LinuxUtils.cpp
    ${PROTON}/SDL/SDL2Main.cpp
    ${PROTON}/util/VideoModeSelector.cpp
    ${PROTON}/util/PassThroughPointerEventHandler.cpp
    ${PROTON}/util/TouchDeviceEmulatorPointerEventHandler.cpp
    ${PROTON}/util/Variant.cpp
    ${PROTON}/util/MathUtils.cpp
    ${PROTON}/util/CRandom.cpp
    ${PROTON}/util/MiscUtils.cpp
    ${PROTON}/util/ResourceUtils.cpp
    ${PROTON}/util/RenderUtils.cpp
    ${PROTON}/util/GLESUtils.cpp
    ${PROTON}/util/TextScanner.cpp
    ${PROTON}/Manager/Console.cpp
    ${PROTON}/Manager/GameTimer.cpp
    ${PROTON}/Manager/MessageManager.cpp
    ${PROTON}/Manager/ResourceManager.cpp
    ${PROTON}/Manager/VariantDB.cpp
    ${PROTON}/FileSystem/FileManager.cpp
    ${PROTON}/FileSystem/StreamingInstance.cpp
    ${PROTON}/FileSystem/StreamingInstanceFile.cpp
    ${PROTON}/FileSystem/FileSystemZip.cpp
    ${PROTON}/FileSystem/StreamingInstanceZip.cpp
    ${PROTON}/GUI/RTFont.cpp
    ${PROTON}/Math/rtRect.cpp
    ${PROTON}/Renderer/Surface.cpp
    ${PROTON}/Renderer/SoftSurface.cpp
    ${PROTON}/Renderer/SurfaceAnim.cpp
    ${PROTON}/Renderer/RenderBatcher.cpp
    ${PROTON}/Entity/Entity.cpp
    ${PROTON}/Entity/Component.cpp
    ${PROTON}/Entity/EntityUtils.cpp
    ${PROTON}/Network/NetHTTP.cpp
    ${PROTON}/Network/NetSocket.cpp
    ${PROTON}/Network/NetUtils.cpp
    ${PROTON}/Manager/AdManager.cpp
    ${PROTON}/Audio/AudioManager.cpp
    ${PROTON}/Audio/AudioManagerFMODStudio.cpp
    ${PROTON}/Gamepad/Gamepad.cpp
    ${PROTON}/Gamepad/GamepadManager.cpp
    ${PROTON}/Gamepad/GamepadProvider.cpp
    ${PROTON}/Gamepad/GamepadProvideriCade.cpp
    ${PROTON}/Gamepad/GamepadiCade.cpp
    ${PROTON}/ClanLib-2.0/Sources/Core/Math/angle.cpp
    ${PROTON}/ClanLib-2.0/Sources/Core/Math/mat3.cpp
    ${PROTON}/ClanLib-2.0/Sources/Core/Math/mat4.cpp
    ${PROTON}/ClanLib-2.0/Sources/Core/Math/rect.cpp
    ${PROTON}/ClanLib-2.0/Sources/Core/Math/vec2.cpp
    ${PROTON}/ClanLib-2.0/Sources/Core/Math/vec3.cpp
    ${PROTON}/ClanLib-2.0/Sources/Core/Math/vec4.cpp
    ${PROTON}/Renderer/JPGSurfaceLoader.cpp
    ${PROTON}/util/archive/TarHandler.cpp
    ${PROTON}/util/unzip/unzip.c
    ${PROTON}/util/unzip/ioapi.c
    ${PROTON}/FileSystem/FileSystem.cpp
    ${CMAKE_SOURCE_DIR}/proton/RTSimpleApp/source/Component/ParticleTestComponent.cpp
)

# Bundled libjpeg 6b sources (must use bundled version - headers expect v62, system libjpeg is v80)
file(GLOB PROTON_JPEGLIB_SOURCES ${PROTON}/Irrlicht/source/Irrlicht/jpeglib/*.c)
list(APPEND PROTON_SOURCES ${PROTON_JPEGLIB_SOURCES})

# Proton linearparticle sources (needed by ParticleTestComponent)
file(GLOB PROTON_LINEARPARTICLE_SOURCES ${PROTON}/Renderer/linearparticle/sources/*.cpp)
list(APPEND PROTON_SOURCES ${PROTON_LINEARPARTICLE_SOURCES})

# Proton Entity Components (exclude VLC/Irrlicht/template components not needed)
file(GLOB PROTON_COMPONENT_SOURCES ${PROTON}/Entity/*Component.cpp)
list(FILTER PROTON_COMPONENT_SOURCES EXCLUDE REGEX ".*LibVlc.*|.*Irrlicht.*|.*Template.*|.*SpriteAnimation.*")
list(APPEND PROTON_SOURCES ${PROTON_COMPONENT_SOURCES})

# Executable
add_executable(RTDinkApp ${RTDINK_SOURCES} ${PROTON_SOURCES})

# Libraries
find_package(OpenGL REQUIRED)
find_package(PNG REQUIRED)
find_package(ZLIB REQUIRED)

find_package(BZip2 REQUIRED)
set(EXTRA_LIBS pthread X11 ${OPENGL_LIBRARIES} ${PNG_LIBRARIES} ${ZLIB_LIBRARIES} ${BZIP2_LIBRARIES} curl SDL2)

target_link_libraries(RTDinkApp ${EXTRA_LIBS} ${FMOD_LIB_DIR}/libfmod.so)

# Create symlinks so the binary can find resources when run from build/
add_custom_command(TARGET RTDinkApp POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E create_symlink
        ${CMAKE_SOURCE_DIR}/media/interface
        ${CMAKE_BINARY_DIR}/interface
    COMMAND ${CMAKE_COMMAND} -E create_symlink
        ${CMAKE_SOURCE_DIR}/media/audio
        ${CMAKE_BINARY_DIR}/audio
)
