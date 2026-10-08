@echo off
setlocal DisableDelayedExpansion
cd /d "%~dp0" || exit /b 1

REM Upload only the build artifacts; keep website-owned PWA files intact.
for %%F in (RTDink.data RTDink.html RTDink.js RTDink.wasm WebLoaderData\logo.png WebLoaderData\progressLogo.Dark.png WebLoaderData\progressLogo.Light.png WebLoaderData\RTLoader.js) do (
    if not exist "%%F" (
        echo Missing build artifact: %%F
        exit /b 1
    )
)
copy /Y RTDink.html index.html >nul
if errorlevel 1 exit /b 1

REM Overwrite loader assets without deleting the live directory.
ssh -o BatchMode=yes rtsoft@rtsoft.com "mkdir -p ~/www/web/dink/WebLoaderData"
if errorlevel 1 exit /b 1
scp RTDink.data RTDink.js RTDink.wasm rtsoft@rtsoft.com:www/web/dink/
if errorlevel 1 exit /b 1
scp WebLoaderData\logo.png WebLoaderData\progressLogo.Dark.png WebLoaderData\progressLogo.Light.png WebLoaderData\RTLoader.js rtsoft@rtsoft.com:www/web/dink/WebLoaderData/
if errorlevel 1 exit /b 1
REM Publish the cache-busted pages after the payloads finish uploading.
scp RTDink.html index.html rtsoft@rtsoft.com:www/web/dink/
if errorlevel 1 exit /b 1
ssh -o BatchMode=yes rtsoft@rtsoft.com "chmod -R u=rwX,go=rX ~/www/web/dink"
if errorlevel 1 exit /b 1

REM Automation can upload without opening a visible browser.
if /i not "%~1"=="nobrowser" start https://www.rtsoft.com/web/dink/
exit /b 0
