:Copy a couple glue Java files we share between Proton projects, don't edit these as they are overwritten here
copy ..\..\shared\android\v3_src\*.java app\src\main\java\com\rtsoft\RTAndroidApp

:Copy over graphics and sounds so they get included in the apk
SET ASSET_DIR=app\src\main\assets
rmdir app\src\main\assets /S /Q

mkdir %ASSET_DIR%

mkdir %ASSET_DIR%\interface
IF EXIST ..\bin\interface xcopy ..\bin\interface %ASSET_DIR%\interface /E /F /Y

mkdir %ASSET_DIR%\audio

IF EXIST ..\bin\audio xcopy ..\bin\audio %ASSET_DIR%\audio /E /F /Y

mkdir %ASSET_DIR%\game
IF EXIST ..\bin\game xcopy ..\bin\game %ASSET_DIR%\game /E /F /Y

mkdir %ASSET_DIR%\dink
xcopy ..\bin\dink_for_android %ASSET_DIR%\dink /E /F /Y

:Remove save data we shouldn't have
IF EXIST %ASSET_DIR%\dink\continue_state.dat del %ASSET_DIR%\dink\continue_state.dat
IF EXIST %ASSET_DIR%\dink\quicksave.dat del %ASSET_DIR%\dink\quicksave.dat
IF EXIST %ASSET_DIR%\dink\save*.dat del %ASSET_DIR%\dink\save*.dat
IF EXIST %ASSET_DIR%\dink\autosave*.* del %ASSET_DIR%\dink\autosave*.*

:Oh, we need this too for ssl to work
copy ..\bin\curl-ca-bundle.crt %ASSET_DIR% /Y

