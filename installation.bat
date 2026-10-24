@echo off
setlocal
cd /d "%~dp0"

echo ==========================================
echo       Installation locale Terra Sana
echo ==========================================
echo.

if not exist "backend\mvnw.cmd" (
    echo ERREUR : backend\mvnw.cmd est introuvable.
    echo Placez les scripts a la racine du depot Terra Sana.
    goto erreur
)
if not exist "frontend\package.json" (
    echo ERREUR : frontend\package.json est introuvable.
    goto erreur
)
if not exist "frontend\package-lock.json" (
    echo ERREUR : frontend\package-lock.json est introuvable.
    goto erreur
)
if not exist "creer_base.bat" (
    echo ERREUR : creer_base.bat est introuvable.
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
where npm >nul 2>&1
if errorlevel 1 (
    echo ERREUR : npm est introuvable. Reinstallez Node.js LTS.
    goto erreur
)

echo [1/3] Installation des dependances du frontend...
pushd frontend
call npm ci
if errorlevel 1 (
    popd
    goto erreur
)
popd

echo.
echo [2/3] Compilation de verification du backend...
pushd backend
call mvnw.cmd -DskipTests package
if errorlevel 1 (
    popd
    goto erreur
)
popd

echo.
echo [3/3] Creation de la base terre_sana...
set "CALL_FROM_INSTALLER=1"
call creer_base.bat
set "CALL_FROM_INSTALLER="
if errorlevel 1 goto erreur

echo.
echo Installation terminee.
echo Verifiez que application.properties utilise le meme compte MySQL
echo que celui utilise lors de la creation de la base.
echo Vous pourrez ensuite lancer demarrer.bat.
pause
exit /b 0

:erreur
echo.
echo L'installation a echoue. Corrigez le probleme indique puis relancez le script.
pause
exit /b 1
