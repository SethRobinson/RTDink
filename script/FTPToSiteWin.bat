

REM This will FTP the latest build into the correct dir at RTSOFT

if "%d_fname%" == "" ( 
   echo d_fname not set.
   SET d_fname=DinkSmallwoodHDInstaller.exe
  )

:parms are the file itself, and the rtsoft subdir to put it in
call %RT_PROJECTS%\UploadFileToRTsoftSSH.bat "%d_fname%" dink

pause

