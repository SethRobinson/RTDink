SET _FTP_USER_=rtsoft
SET _FTP_SITE_=rtsoft.com
SET WEB_SUB_DIR=web/dink


set CURPATH=%cd%
cd ..
call app_info_setup.bat

SET PROJECT_PATH=projects/proton/%APP_NAME%/html5

cd %CURPATH%

if not exist %APP_NAME%.js beeper.exe /p

:Get rid of files we don't actually need
del %APP_NAME%.js.orig.js
del temp.bc

:SSH transfer, this assumes you have ssh and valid keys setup already
copy /Y %APP_NAME%.html index.html

: Create directory and remove existing files
wsl ssh %_FTP_USER_%@%_FTP_SITE_% "mkdir -p ~/www/%WEB_SUB_DIR% && rm -rf ~/www/%WEB_SUB_DIR%/WebLoaderData"

: Transfer files using rsync via WSL
wsl rsync -avz -e "ssh" /mnt/d/%PROJECT_PATH%/%APP_NAME%*.* %_FTP_USER_%@%_FTP_SITE_%:www/%WEB_SUB_DIR%/
wsl rsync -avzr -e "ssh" /mnt/d/%PROJECT_PATH%/WebLoaderData %_FTP_USER_%@%_FTP_SITE_%:www/%WEB_SUB_DIR%/
wsl rsync -avz -e "ssh" /mnt/d/%PROJECT_PATH%/index.html %_FTP_USER_%@%_FTP_SITE_%:www/%WEB_SUB_DIR%/

: Open a browser to test it
:start http://www.%_FTP_SITE_%/%WEB_SUB_DIR%/%APP_NAME%.html
start http://www.%_FTP_SITE_%/%WEB_SUB_DIR%

pause
