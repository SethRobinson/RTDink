# For more information about using CMake with Android Studio, read the
# documentation: https://d.android.com/studio/projects/add-native-code.html

# Sets the minimum version of CMake required to build the native library.

cmake_minimum_required(VERSION 3.18.1)

# Declares and names the project.

project("RTAndroidApp")

set(APP "../../../../../source")
set(SHARED "../../../../../../shared")
set(COMPPATH "${SHARED}/Entity")
set(CLANMATH "${SHARED}/ClanLib-2.0/Sources/Core/Math")

set(ZLIBPATH "${SHARED}/util/zlib")
set(PPATH "${SHARED}/Renderer/linearparticle/sources")
set(PNGSRC "${SHARED}/Irrlicht/source/Irrlicht/libpng")
set(JPGSRC "${SHARED}/Irrlicht/source/Irrlicht/jpeglib")
set(LZMASRC "${SHARED}/Irrlicht/source/Irrlicht/lzma")

include_directories("${SHARED}")
include_directories("${SHARED}/util/boost")
include_directories("${SHARED}/ClanLib-2.0/Sources")
include_directories("${APP}")
#include_directories("${SHARED}/android/optional_src/libs/libcurl_ssl/include")
include_directories("${SHARED}/android/optional_src/libs")
include_directories("${SHARED}/android/optional_src/libs/libcurl-android/jni/build/curl/${ANDROID_ABI}/include")


#the C_STACK_HACK define makes it so it won't crash on certain dmods, check dink.cpp to see how it's used there
#add_definitions(-Wno-error=format-security -Wl,-stack_size -Wl,0x800000 -DANDROID_NDK -DBOOST_ALL_NO_LIB -DBUILD_ANDROID -DPLATFORM_ANDROID -DRT_JPG_SUPPORT -DRT_ENABLE_FMOD -DRT_USE_LIBCURL -DRT_PNG_SUPPORT -DC_STACK_HACK)
add_definitions(-Wno-error=format-security -Wl,-stack_size -Wl,0x12800000 -DANDROID_NDK -DBOOST_ALL_NO_LIB -DBUILD_ANDROID -DPLATFORM_ANDROID -DRT_JPG_SUPPORT -DRT_ENABLE_FMOD -DRT_USE_LIBCURL -DRT_PNG_SUPPORT -DC_STACK_HACK)

message("Building ${CMAKE_BUILD_TYPE}")

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_definitions(-D_DEBUG)
else()
    add_definitions(-DNDEBUG)
endif()

# Creates and names a library, sets it as either STATIC
# or SHARED, and provides the relative paths to its source code.
# You can define multiple libraries, and CMake builds them for you.
# Gradle automatically packages shared libraries with your APK.

add_library( # Sets the name of the library.
        RTAndroidApp

        # Sets the library as a shared library.
        SHARED

        

${SHARED}/PlatformSetup.cpp ${SHARED}/android/AndroidUtils.cpp ${SHARED}/Android/AndroidApp.cpp
${SHARED}/Audio/AudioManager.cpp ${SHARED}/Audio/AudioManagerFMODStudio.cpp
${CLANMATH}/angle.cpp ${CLANMATH}/mat3.cpp ${CLANMATH}/mat4.cpp ${CLANMATH}/rect.cpp ${CLANMATH}/vec2.cpp ${CLANMATH}/vec3.cpp ${CLANMATH}/vec4.cpp 
${SHARED}/Entity/Entity.cpp ${SHARED}/Entity/Component.cpp ${SHARED}/GUI/RTFont.cpp ${SHARED}/Manager/Console.cpp ${SHARED}/FileSystem/FileManager.cpp 
${SHARED}/Manager/GameTimer.cpp ${SHARED}/Manager/MessageManager.cpp ${SHARED}/Manager/ResourceManager.cpp ${SHARED}/Manager/VariantDB.cpp ${SHARED}/Math/rtPlane.cpp 
${SHARED}/Math/rtRect.cpp ${SHARED}/Renderer/RenderBatcher.cpp ${SHARED}/Renderer/SoftSurface.cpp ${SHARED}/Renderer/Surface.cpp ${SHARED}/Renderer/SurfaceAnim.cpp 
${SHARED}/util/CRandom.cpp ${SHARED}/util/GLESUtils.cpp ${SHARED}/util/MathUtils.cpp ${SHARED}/util/MiscUtils.cpp ${SHARED}/util/Variant.cpp ${SHARED}/util/RenderUtils.cpp ${SHARED}/util/ResourceUtils.cpp 
${SHARED}/BaseApp.cpp ${SHARED}/FileSystem/FileSystem.cpp ${SHARED}/FileSystem/FileSystemZip.cpp 
${SHARED}/util/unzip/unzip.c ${SHARED}/util/unzip/ioapi.c ${SHARED}/util/TextScanner.cpp ${SHARED}/Entity/EntityUtils.cpp 
${SHARED}/Network/NetHTTP.cpp ${SHARED}/Network/NetHTTP_libCURL.cpp ${SHARED}/Network/NetSocket.cpp ${SHARED}/Network/NetUtils.cpp ${SHARED}/FileSystem/StreamingInstance.cpp 
${SHARED}/FileSystem/StreamingInstanceZip.cpp ${SHARED}/FileSystem/StreamingInstanceFile.cpp ${SHARED}/util/archive/TarHandler.cpp ${SHARED}/util/bzip2/blocksort.c 
${SHARED}/util/bzip2/bzlib.c ${SHARED}/util/bzip2/compress.c ${SHARED}/util/bzip2/crctable.c ${SHARED}/util/bzip2/decompress.c ${SHARED}/util/bzip2/huffman.c 
${SHARED}/util/bzip2/randtable.c 

${SHARED}/Gamepad/GamepadManager.cpp ${SHARED}/Gamepad/Gamepad.cpp ${SHARED}/Gamepad/GamepadiCade.cpp ${SHARED}/Gamepad/GamepadProvider.cpp ${SHARED}/Gamepad/GamepadProvideriCade.cpp 
${SHARED}/Gamepad/GamepadProviderMoga.cpp ${SHARED}/Gamepad/GamepadMoga.cpp 

${SHARED}/Manager/AdManager.cpp ${SHARED}/Ad/AdProvider.cpp ${SHARED}/Ad/AdProviderChartBoost.cpp 

${SHARED}/Renderer/JPGSurfaceLoader.cpp 

${JPGSRC}/jcapimin.c ${JPGSRC}/jcapistd.c ${JPGSRC}/jccoefct.c ${JPGSRC}/jccolor.c ${JPGSRC}/jcdctmgr.c ${JPGSRC}/jchuff.c ${JPGSRC}/jcinit.c ${JPGSRC}/jcmainct.c 
${JPGSRC}/jcmarker.c ${JPGSRC}/jcmaster.c ${JPGSRC}/jcomapi.c ${JPGSRC}/jcparam.c ${JPGSRC}/jcphuff.c ${JPGSRC}/jcprepct.c ${JPGSRC}/jcsample.c ${JPGSRC}/jctrans.c 
${JPGSRC}/jdapimin.c ${JPGSRC}/jdapistd.c ${JPGSRC}/jdatadst.c ${JPGSRC}/jdatasrc.c ${JPGSRC}/jdcoefct.c ${JPGSRC}/jdcolor.c ${JPGSRC}/jddctmgr.c 
${JPGSRC}/jdhuff.c ${JPGSRC}/jdinput.c ${JPGSRC}/jdmainct.c ${JPGSRC}/jdmarker.c ${JPGSRC}/jdmaster.c ${JPGSRC}/jdmerge.c ${JPGSRC}/jdphuff.c ${JPGSRC}/jdpostct.c 
${JPGSRC}/jdsample.c ${JPGSRC}/jdtrans.c ${JPGSRC}/jerror.c ${JPGSRC}/jfdctflt.c ${JPGSRC}/jfdctfst.c ${JPGSRC}/jfdctint.c ${JPGSRC}/jidctflt.c ${JPGSRC}/jidctfst.c 
${JPGSRC}/jidctint.c ${JPGSRC}/jidctred.c ${JPGSRC}/jmemmgr.c ${JPGSRC}/jmemnobs.c ${JPGSRC}/jquant1.c ${JPGSRC}/jquant2.c ${JPGSRC}/jutils.c 

${PNGSRC}/png.c ${PNGSRC}/pngerror.c ${PNGSRC}/pnggccrd.c ${PNGSRC}/pngget.c ${PNGSRC}/pngmem.c ${PNGSRC}/pngpread.c ${PNGSRC}/pngread.c 
${PNGSRC}/pngrio.c ${PNGSRC}/pngrtran.c ${PNGSRC}/pngrutil.c ${PNGSRC}/pngset.c ${PNGSRC}/pngtrans.c ${PNGSRC}/pngvcrd.c ${PNGSRC}/pngwio.c ${PNGSRC}/pngwtran.c ${PNGSRC}/pngwrite.c ${PNGSRC}/pngwutil.c

${COMPPATH}/Button2DComponent.cpp ${COMPPATH}/FilterInputComponent.cpp ${COMPPATH}/FocusInputComponent.cpp ${COMPPATH}/FocusRenderComponent.cpp ${COMPPATH}/FocusUpdateComponent.cpp 
${COMPPATH}/HTTPComponent.cpp ${COMPPATH}/InputTextRenderComponent.cpp ${COMPPATH}/InterpolateComponent.cpp ${COMPPATH}/OverlayRenderComponent.cpp ${COMPPATH}/ProgressBarComponent.cpp 
${COMPPATH}/RectRenderComponent.cpp ${COMPPATH}/ScrollBarRenderComponent.cpp ${COMPPATH}/ScrollComponent.cpp ${COMPPATH}/TapSequenceDetectComponent.cpp ${COMPPATH}/TextBoxRenderComponent.cpp 
${COMPPATH}/TextRenderComponent.cpp ${COMPPATH}/TouchStripComponent.cpp ${COMPPATH}/TrailRenderComponent.cpp ${COMPPATH}/TyperComponent.cpp ${COMPPATH}/UnderlineRenderComponent.cpp 
${COMPPATH}/TouchHandlerComponent.cpp ${COMPPATH}/SelectButtonWithCustomInputComponent.cpp ${COMPPATH}/CustomInputComponent.cpp ${COMPPATH}/SliderComponent.cpp ${COMPPATH}/RenderClipComponent.cpp 
${COMPPATH}/UnpackArchiveComponent.cpp ${COMPPATH}/ArcadeInputComponent.cpp ${COMPPATH}/EmitVirtualKeyComponent.cpp ${COMPPATH}/RenderScissorComponent.cpp ${COMPPATH}/LogDisplayComponent.cpp ${COMPPATH}/TouchDragComponent.cpp



${PPATH}/L_Defination.cpp ${PPATH}/L_DroppingEffect.cpp ${PPATH}/L_EffectEmitter.cpp ${PPATH}/L_ExplosionEffect.cpp ${PPATH}/L_MotionController.cpp ${PPATH}/L_Particle.cpp 
${PPATH}/L_ParticleEffect.cpp ${PPATH}/L_ParticleMem.cpp ${PPATH}/L_ParticleSystem.cpp ${PPATH}/L_ShootingEffect.cpp ${PPATH}/L_EffectManager.cpp 

${APP}/App.cpp ${APP}/Component/ActionButtonComponent.cpp ${APP}/Component/CursorComponent.cpp ${APP}/Component/DragControlComponent.cpp ${APP}/Component/emulatedPointerComponent.cpp
${APP}/Component/FPSControlComponent.cpp ${APP}/Component/InventoryComponent.cpp ${APP}/dink/dink.cpp ${APP}/dink/FFReader.cpp ${APP}/dink/misc_util.cpp ${APP}/dink/ScriptAccelerator.cpp 
${APP}/video_gl.cpp 
${APP}/GUI/AboutMenu.cpp ${APP}/GUI/BrowseMenu.cpp ${APP}/GUI/DebugMenu.cpp ${APP}/GUI/DMODInstallMenu.cpp 
${APP}/GUI/EnterURLMenu.cpp ${APP}/GUI/DMODMenu.cpp ${APP}/GUI/GameMenu.cpp ${APP}/GUI/LoadMenu.cpp ${APP}/GUI/LogMenu.cpp ${APP}/GUI/MainMenu.cpp ${APP}/GUI/OptionsMenu.cpp 
${APP}/GUI/PauseMenu.cpp ${APP}/GUI/PopUpMenu.cpp ${APP}/GUI/QuickTipMenu.cpp ${APP}/GUI/ReadTextMenu.cpp ${APP}/GUI/ExpiredMenu.cpp 

        )

# if you  need to add another C++ library, you can do it in the format below, then don't forget to add
# the lib name to the target_link_libraries command below as well
#add_library(lib_crypto STATIC IMPORTED)
#set_target_properties(lib_crypto PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/

add_library(lib_openssl STATIC IMPORTED)
#set_target_properties(lib_openssl PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/${SHARED}/android/optional_src/libs/libopenssl/${ANDROID_ABI}/libssl.a)
set_target_properties(lib_openssl PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/${SHARED}/android/optional_src/libs/libcurl-android/jni/build/openssl/${ANDROID_ABI}/lib/libssl.a)

add_library(lib_curl STATIC IMPORTED)
#set_target_properties(lib_curl PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/${SHARED}/android/optional_src/libs/libcurl_ssl/${ANDROID_ABI}/libcurl.a)
set_target_properties(lib_curl PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/${SHARED}/android/optional_src/libs/libcurl-android/jni/build/curl/${ANDROID_ABI}/lib/libcurl.a)

add_library(lib_crypto STATIC IMPORTED)
#set_target_properties(lib_crypto PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/${SHARED}/android/optional_src/libs/libopenssl/${ANDROID_ABI}/libcrypto.a)
set_target_properties(lib_crypto PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/${SHARED}/android/optional_src/libs/libcurl-android/jni/build/openssl/${ANDROID_ABI}/lib/libcrypto.a)

#Change libfmod.so to libfmodL.so for the debug logging version, but don't forget to change "fmod" to System.loadLibrary("fmodL"); in Main.Java as well
add_library(lib_fmod STATIC IMPORTED)
set_target_properties(lib_fmod PROPERTIES IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/${SHARED}/android/optional_src/libs/f/api/core/lib/${ANDROID_ABI}/libfmod.so)



# Searches for a specified prebuilt library and stores the path as a
# variable. Because CMake includes system libraries in the search path by
# default, you only need to specify the name of the public NDK library
# you want to add. CMake verifies that the library exists before
# completing its build.

find_library( # Sets the name of the path variable.
        log-lib

        # Specifies the name of the NDK library that
        # you want CMake to locate.
        log
        )

# Specifies libraries CMake should link to your target library. You
# can link multiple libraries, such as libraries you define in this
# build script, prebuilt third-party libraries, or system libraries.

#Keep in mind the order below matters!  Low level? Then it goes to the right

target_link_libraries( # Specifies the target library.
        RTAndroidApp

        # Links the target library to the log library
        # included in the NDK.
        ${log-lib} lib_openssl lib_curl lib_crypto dl GLESv1_CM c z lib_fmod)