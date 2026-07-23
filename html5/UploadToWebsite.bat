SET _FTP_USER_=rtsoft
SET _FTP_SITE_=rtsoft.com
SET WEB_SUB_DIR=web/dink


set CURPATH=%cd%
cd ..
call app_info_setup.bat
cd %CURPATH%

if not exist %APP_NAME%.js %RT_UTIL%\beeper.exe /p
:Get rid of files we don't actually need
del %APP_NAME%.js.orig.js
del temp.o
:SSH transfer, this assumes you have ssh and valid keys setup already
copy /Y %APP_NAME%.html index.html

:NOTE: manifest.webmanifest, the icon pngs and .htaccess in this web dir live on the server
:only (mirrored in d:\website\web\dink) - this script must never delete or overwrite them.
ssh %_FTP_USER_%@%_FTP_SITE_% "mkdir -p ~/www/%WEB_SUB_DIR%"
ssh %_FTP_USER_%@%_FTP_SITE_% "rm -rf ~/www/%WEB_SUB_DIR%/WebLoaderData"
:rsync isn't a thing on stock Windows, so we use OpenSSH's scp instead
scp %APP_NAME%.data %APP_NAME%.html %APP_NAME%.js %APP_NAME%.wasm index.html %_FTP_USER_%@%_FTP_SITE_%:www/%WEB_SUB_DIR%/
scp -r WebLoaderData %_FTP_USER_%@%_FTP_SITE_%:www/%WEB_SUB_DIR%/
ssh %_FTP_USER_%@%_FTP_SITE_% "chmod -R u=rwX,go=rX ~/www/%WEB_SUB_DIR%"

:Let's go ahead an open a browser to test it
:start http://www.%_FTP_SITE_%/%WEB_SUB_DIR%/%APP_NAME%.html
start http://www.%_FTP_SITE_%/%WEB_SUB_DIR%
