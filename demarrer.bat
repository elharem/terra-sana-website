@echo off
setlocal
cd /d "%~dp0"

echo ==========================================
echo          Demarrage de Terra Sana
echo ==========================================
echo.

if not exist "backend\mvnw.cmd" (
    echo ERREUR : backend\mvnw.cmd est introuvable.
    echo Placez ce fichier a la racine du depot Terra Sana.
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
    echo ERREUR : Java 21 est requis. Verifiez la version de Java installee.
    goto erreur
)

where node >nul 2>&1
if errorlevel 1 (
    echo ERREUR : Node.js est introuvable. Installez Node.js LTS.
    goto erreur
)

echo Verification de MySQL sur le port 3306...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=New-Object Net.Sockets.TcpClient; try{$c.Connect('127.0.0.1',3306);$c.Close();exit 0}catch{exit 1}"
if errorlevel 1 (
    echo ERREUR : MySQL ne repond pas sur le port 3306.
    echo Demarrez MySQL ou WampServer, puis relancez demarrer.bat.
    goto erreur
)

echo Lancement du backend dans une nouvelle fenetre...
start "Terra Sana - Backend" /D "%~dp0backend" "%ComSpec%" /k "call mvnw.cmd spring-boot:run"

echo Attente du demarrage du backend...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ok=$false; for($i=0;$i -lt 90;$i++){ $c=New-Object Net.Sockets.TcpClient; try{$c.Connect('127.0.0.1',8080);$c.Close();$ok=$true;break}catch{}; Start-Sleep -Seconds 1 }; if(-not $ok){exit 1}"
if errorlevel 1 (
    echo ERREUR : le backend n'a pas repondu sur le port 8080.
    echo Consultez la fenetre Terra Sana - Backend pour voir l'erreur.
    goto erreur
)

echo Lancement du frontend dans une nouvelle fenetre...
start "Terra Sana - Frontend" /D "%~dp0frontend" "%ComSpec%" /k "npm start"

echo Attente du demarrage du frontend...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ok=$false; for($i=0;$i -lt 90;$i++){ $c=New-Object Net.Sockets.TcpClient; try{$c.Connect('127.0.0.1',3000);$c.Close();$ok=$true;break}catch{}; Start-Sleep -Seconds 1 }; if(-not $ok){exit 1}"
if errorlevel 1 (
    echo ERREUR : le frontend n'a pas repondu sur le port 3000.
    echo Consultez la fenetre Terra Sana - Frontend pour voir l'erreur.
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
