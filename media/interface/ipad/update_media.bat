REM Make fonts

set PACK_EXE=%RT_PROTON_UTIL%\RTPack.exe


for /r %%f in (*.bmp *.png) do %PACK_EXE%  -ultra_compress 90 -pvrt8888 %%f

:mkdir ..\bin\interface
:xcopy interface ..\bin\interface /E /F /Y /EXCLUDE:exclude.txt

pause
