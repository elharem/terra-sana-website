@echo off
setlocal
cd /d "%~dp0"

echo ==========================================
echo       Installation locale Terra Sana
echo ==========================================
echo.

if not exist "backend\mvnw.cmd" (
    echo ERREUR : backend\mvnw.cmd est introuvable.
    echo Placez ce fichier a la racine du depot Terra Sana.
    goto erreur
)

if not exist "frontend\package.json" (
    echo ERREUR : frontend\package.json est introuvable.
    echo Placez ce fichier a la racine du depot Terra Sana.
    goto erreur
)

if not exist "frontend\package-lock.json" (
    echo ERREUR : frontend\package-lock.json est introuvable.
    goto erreur
)

where java >nul 2>&1
if errorlevel 1 (
    echo ERREUR : Java est introuvable. Installez le JDK 21, puis relancez ce script.
    goto erreur
)
java -version 2>&1 | findstr /C:"21." >nul
if errorlevel 1 (
    echo ERREUR : Java 21 est requis. Verifiez la version de Java installee.
    goto erreur
)

where node >nul 2>&1
if errorlevel 1 (
    echo ERREUR : Node.js est introuvable. Installez Node.js LTS, puis relancez ce script.
    goto erreur
)

where npm >nul 2>&1
if errorlevel 1 (
    echo ERREUR : npm est introuvable. Reinstallez Node.js LTS, puis relancez ce script.
    goto erreur
)

echo [1/2] Installation des dependances du frontend...
pushd frontend
call npm ci
if errorlevel 1 (
    popd
    goto erreur
)
popd

echo.
echo [2/2] Verification et compilation du backend...
pushd backend
call mvnw.cmd -DskipTests package
if errorlevel 1 (
    popd
    goto erreur
)
popd

echo.
echo Installation des dependances terminee.
echo.
echo Avant le premier demarrage, verifiez que :
echo - MySQL est installe et en fonctionnement ;
echo - la base terre_sana a ete creee ;
echo - backend\src\main\resources\application.properties contient
echo   les parametres de connexion MySQL de votre environnement.
echo.
echo Vous pourrez ensuite lancer demarrer.bat.
pause
exit /b 0

:erreur
echo.
echo L'installation a echoue. Corrigez le probleme indique puis relancez le script.
pause
exit /b 1
