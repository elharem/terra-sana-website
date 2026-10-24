@echo off
setlocal
cd /d "%~dp0"

echo ==========================================
echo       Creation de la base Terra Sana
echo ==========================================
echo.

set "WAMP_ROOT="
if exist "C:\wamp64\wampmanager.exe" set "WAMP_ROOT=C:\wamp64"
if not defined WAMP_ROOT if exist "C:\wamp\wampmanager.exe" set "WAMP_ROOT=C:\wamp"
if not defined WAMP_ROOT if exist "C:\wampserver\wampmanager.exe" set "WAMP_ROOT=C:\wampserver"

if not defined WAMP_ROOT (
    echo ERREUR : WampServer n'a pas ete trouve dans son emplacement habituel.
    echo Modifiez la variable WAMP_ROOT dans creer_base.bat pour indiquer son dossier.
    goto erreur
)

set "MYSQL_EXE="
for /d %%D in ("%WAMP_ROOT%\bin\mysql\mysql*") do (
    if exist "%%~fD\bin\mysql.exe" set "MYSQL_EXE=%%~fD\bin\mysql.exe"
)
if not defined MYSQL_EXE (
    echo ERREUR : mysql.exe est introuvable dans %WAMP_ROOT%\bin\mysql.
    goto erreur
)

echo WampServer detecte dans %WAMP_ROOT%.
echo Verification de MySQL sur le port 3306...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=New-Object Net.Sockets.TcpClient; try{$c.Connect('127.0.0.1',3306);$c.Close();exit 0}catch{exit 1}" >nul 2>&1
if errorlevel 1 (
    echo Demarrage de WampServer...
    start "" "%WAMP_ROOT%\wampmanager.exe"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ok=$false; for($i=0;$i -lt 90;$i++){ $c=New-Object Net.Sockets.TcpClient; try{$c.Connect('127.0.0.1',3306);$c.Close();$ok=$true;break}catch{}; Start-Sleep -Seconds 1 }; if(-not $ok){exit 1}"
    if errorlevel 1 (
        echo ERREUR : MySQL n'a pas demarre sur le port 3306.
        echo Si WampServer demande des droits, relancez-le en tant qu'administrateur.
        goto erreur
    )
)

echo.
set "DB_USER=root"
set /p "DB_USER=Utilisateur MySQL [root] : "
if not defined DB_USER set "DB_USER=root"
echo Le client MySQL va demander le mot de passe. Si le compte root n'en a pas, appuyez simplement sur Entree.
echo.
"%MYSQL_EXE%" --host=127.0.0.1 --port=3306 --user="%DB_USER%" --password -e "CREATE DATABASE IF NOT EXISTS terre_sana CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
if errorlevel 1 (
    echo ERREUR : la base n'a pas pu etre creee. Verifiez le compte MySQL et son mot de passe.
    goto erreur
)

echo.
echo Base terre_sana creee ou deja presente.
echo Configurez application.properties avec un compte ayant acces a cette base.
if not defined CALL_FROM_INSTALLER pause
exit /b 0

:erreur
echo.
if not defined CALL_FROM_INSTALLER pause
exit /b 1
