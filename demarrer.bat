@echo off
setlocal
cd /d "%~dp0"

echo ==========================================
echo          Demarrage de Terra Sana
echo ==========================================
echo.

if not exist "backend\mvnw.cmd" (
    echo ERREUR : backend\mvnw.cmd est introuvable.
    echo Placez les scripts a la racine du depot Terra Sana.
    goto erreur
)
if not exist "frontend\node_modules" (
    echo Les dependances du frontend ne sont pas installees.
    echo Lancez d'abord installation.bat.
    goto erreur
)

where java >nul 2>&1
if errorlevel 1 (
    echo ERREUR : Java est introuvable. Installez le JDK 21.
    goto erreur
)
java -version 2>&1 | findstr /C:"21." >nul
if errorlevel 1 (
    echo ERREUR : Java 21 est requis. Verifiez la version installee.
    goto erreur
)
where node >nul 2>&1
if errorlevel 1 (
    echo ERREUR : Node.js est introuvable. Installez Node.js LTS.
    goto erreur
)

set "WAMP_ROOT="
if exist "C:\wamp64\wampmanager.exe" set "WAMP_ROOT=C:\wamp64"
if not defined WAMP_ROOT if exist "C:\wamp\wampmanager.exe" set "WAMP_ROOT=C:\wamp"
if not defined WAMP_ROOT if exist "C:\wampserver\wampmanager.exe" set "WAMP_ROOT=C:\wampserver"
if not defined WAMP_ROOT (
    echo ERREUR : WampServer n'a pas ete trouve dans son emplacement habituel.
    echo Modifiez la variable WAMP_ROOT dans demarrer.bat pour indiquer son dossier.
    goto erreur
)

echo Verification de MySQL sur le port 3306...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=New-Object Net.Sockets.TcpClient; try{$c.Connect('127.0.0.1',3306);$c.Close();exit 0}catch{exit 1}" >nul 2>&1
if errorlevel 1 (
    echo Demarrage de WampServer...
    start "" "%WAMP_ROOT%\wampmanager.exe"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ok=$false; for($i=0;$i -lt 90;$i++){ $c=New-Object Net.Sockets.TcpClient; try{$c.Connect('127.0.0.1',3306);$c.Close();$ok=$true;break}catch{}; Start-Sleep -Seconds 1 }; if(-not $ok){exit 1}"
    if errorlevel 1 (
        echo ERREUR : MySQL ne repond pas sur le port 3306.
        echo Verifiez WampServer. Si necessaire, lancez-le en tant qu'administrateur.
        goto erreur
    )
)

echo Verification de la base terre_sana...
echo Si le backend indique que la base est inconnue, lancez creer_base.bat une fois.

echo Lancement du backend dans une nouvelle fenetre...
start "Terra Sana - Backend" /D "%~dp0backend" "%ComSpec%" /k "call mvnw.cmd spring-boot:run"

echo Attente du demarrage du backend...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ok=$false; for($i=0;$i -lt 90;$i++){ $c=New-Object Net.Sockets.TcpClient; try{$c.Connect('127.0.0.1',8080);$c.Close();$ok=$true;break}catch{}; Start-Sleep -Seconds 1 }; if(-not $ok){exit 1}"
if errorlevel 1 (
    echo ERREUR : le backend n'a pas repondu sur le port 8080.
    echo Consultez la fenetre Terra Sana - Backend pour le detail.
    goto erreur
)

echo Lancement du frontend dans une nouvelle fenetre...
start "Terra Sana - Frontend" /D "%~dp0frontend" "%ComSpec%" /k "npm start"

echo Attente du demarrage du frontend...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ok=$false; for($i=0;$i -lt 90;$i++){ $c=New-Object Net.Sockets.TcpClient; try{$c.Connect('127.0.0.1',3000);$c.Close();$ok=$true;break}catch{}; Start-Sleep -Seconds 1 }; if(-not $ok){exit 1}"
if errorlevel 1 (
    echo ERREUR : le frontend n'a pas repondu sur le port 3000.
    echo Consultez la fenetre Terra Sana - Frontend pour le detail.
    goto erreur
)

echo Ouverture du site dans le navigateur...
start "" "http://localhost:3000"
echo Terra Sana est demarre. Gardez les fenetres Backend et Frontend ouvertes.
pause
exit /b 0

:erreur
echo.
pause
exit /b 1
