@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "APP_PROPS=backend\src\main\resources\application.properties"

echo ==========================================
echo          Demarrage de Terra Sana
echo ==========================================
echo.

if not exist "backend\mvnw.cmd" (
    echo ERREUR : backend\mvnw.cmd est introuvable.
    echo Place ce script a la racine du depot Terra Sana.
    goto erreur
)

if not exist "frontend\package.json" (
    echo ERREUR : frontend\package.json est introuvable.
    goto erreur
)

if not exist "frontend\node_modules" (
    echo ERREUR : les dependances frontend ne sont pas installees.
    echo Lance d'abord installation.bat.
    goto erreur
)

where java >nul 2>&1
if errorlevel 1 (
    echo ERREUR : Java est introuvable. Installe un JDK 21 ou plus recent.
    goto erreur
)

where node >nul 2>&1
if errorlevel 1 (
    echo ERREUR : Node.js est introuvable.
    goto erreur
)

where npm.cmd >nul 2>&1
if errorlevel 1 (
    echo ERREUR : npm.cmd est introuvable. Reinstalle Node.js.
    goto erreur
)

rem Creer le fichier de configuration s'il n'existe pas.
rem Les identifiants ci-dessous correspondent a une configuration WampServer courante.
rem Si MySQL utilise un autre compte ou mot de passe, modifie application.properties.
if not exist "%APP_PROPS%" (
    echo Creation de la configuration locale du backend...
    if not exist "backend\src\main\resources" mkdir "backend\src\main\resources"
    if errorlevel 1 (
        echo ERREUR : impossible de creer le dossier resources du backend.
        goto erreur
    )
    (
        echo spring.datasource.url=jdbc:mysql://localhost:3306/terre_sana
        echo spring.datasource.username=root
        echo spring.datasource.password=
        echo spring.jpa.hibernate.ddl-auto=update
        echo spring.jpa.show-sql=true
        echo spring.jpa.database-platform=org.hibernate.dialect.MySQL8Dialect
        echo server.port=8080
    ) > "%APP_PROPS%"
    if errorlevel 1 (
        echo ERREUR : impossible de creer application.properties.
        goto erreur
    )
)

rem Ajouter les parametres minimaux manquants et creer/reparer les secrets JWT.
rem Les secrets valides deja presents sont conserves entre les demarrages.
echo Verification de la configuration locale et des cles JWT...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$path='backend\src\main\resources\application.properties';" ^
 "$lines=New-Object 'System.Collections.Generic.List[string]'; [IO.File]::ReadAllLines($path) | ForEach-Object { [void]$lines.Add($_) };" ^
 "$defaults=@('spring.datasource.url=jdbc:mysql://localhost:3306/terre_sana','spring.datasource.username=root','spring.datasource.password=','spring.jpa.hibernate.ddl-auto=update','spring.jpa.show-sql=true','spring.jpa.database-platform=org.hibernate.dialect.MySQL8Dialect','server.port=8080');" ^
 "foreach($line in $defaults){$key=$line.Substring(0,$line.IndexOf('='));$found=$false;foreach($old in $lines){if($old.StartsWith($key+'=')){$found=$true;break}};if(-not $found){[void]$lines.Add($line)}};" ^
 "$rng=[Security.Cryptography.RandomNumberGenerator]::Create();" ^
 "foreach($key in @('jwt.admin.secret','jwt.volunteer.secret')){$idx=-1;for($i=0;$i -lt $lines.Count;$i++){if($lines[$i].StartsWith($key+'=')){$idx=$i;break}};$needs=$true;if($idx -ge 0){$value=$lines[$idx].Substring($key.Length+1);try{$decoded=[Convert]::FromBase64String($value);if($decoded.Length -ge 32 -and $value -notmatch 'REPLACE_WITH'){$needs=$false}}catch{$needs=$true}};if($needs){$bytes=New-Object byte[] 32;$rng.GetBytes($bytes);$secret=[Convert]::ToBase64String($bytes);if($idx -ge 0){$lines[$idx]=$key+'='+$secret}else{[void]$lines.Add($key+'='+$secret)};Write-Host ('Cle JWT generee/mise a jour : '+$key)}};" ^
 "[IO.File]::WriteAllLines($path,$lines.ToArray(),([System.Text.UTF8Encoding]::new($false)));$rng.Dispose();"

if errorlevel 1 (
    echo ERREUR : impossible de preparer application.properties et les cles JWT.
    goto erreur
)

set "WAMP_ROOT="
if exist "C:\wamp64\wampmanager.exe" set "WAMP_ROOT=C:\wamp64"
if not defined WAMP_ROOT if exist "C:\wamp\wampmanager.exe" set "WAMP_ROOT=C:\wamp"
if not defined WAMP_ROOT if exist "C:\wampserver\wampmanager.exe" set "WAMP_ROOT=C:\wampserver"

if not defined WAMP_ROOT (
    echo ERREUR : WampServer n'a pas ete trouve dans son emplacement habituel.
    echo Modifie WAMP_ROOT dans demarrer.bat si WampServer est ailleurs.
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
        echo Verifie WampServer et son icone.
        goto erreur
    )
)

echo.
echo Lancement du backend dans une nouvelle fenetre...
start "Terra Sana - Backend" /D "%~dp0backend" "%ComSpec%" /k "call mvnw.cmd spring-boot:run"

echo Attente du demarrage du backend...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ok=$false; for($i=0;$i -lt 120;$i++){ $c=New-Object Net.Sockets.TcpClient; try{$c.Connect('127.0.0.1',8080);$c.Close();$ok=$true;break}catch{}; Start-Sleep -Seconds 1 }; if(-not $ok){exit 1}"
if errorlevel 1 (
    echo ERREUR : le backend ne repond pas sur le port 8080.
    echo Consulte la fenetre Terra Sana - Backend.
    echo Verifie MySQL, la base terre_sana et application.properties.
    goto erreur
)

echo.
echo Si aucun compte administrateur n'existe encore, tu peux le creer maintenant.
set /p "CREER_ADMIN=Creer le premier compte administrateur ? (O/N) : "
if /I "%CREER_ADMIN%"=="O" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$u=Read-Host 'Nom d utilisateur'; $e=Read-Host 'Adresse e-mail'; $s1=Read-Host 'Mot de passe (8 caracteres minimum)' -AsSecureString; $s2=Read-Host 'Confirmer le mot de passe' -AsSecureString; $ptr1=[IntPtr]::Zero; $ptr2=[IntPtr]::Zero; try{$ptr1=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($s1);$ptr2=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($s2);$p1=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr1);$p2=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr2);if($p1 -ne $p2){throw 'Les mots de passe ne correspondent pas.'};if($p1.Length -lt 8){throw 'Le mot de passe doit contenir au moins 8 caracteres.'};$body=@{username=$u;email=$e;password=$p1}|ConvertTo-Json -Compress;$resultat=Invoke-RestMethod -Uri 'http://localhost:8080/api/auth/register' -Method POST -ContentType 'application/json' -Body $body;$resultat|ConvertTo-Json}catch{if($_.ErrorDetails.Message){Write-Host $_.ErrorDetails.Message}else{Write-Host $_.Exception.Message};exit 1}finally{if($ptr1 -ne [IntPtr]::Zero){[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr1)};if($ptr2 -ne [IntPtr]::Zero){[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr2)}}"
    if errorlevel 1 (
        echo La creation du compte admin a echoue.
        echo Si un admin existe deja, reponds N au prochain lancement.
        goto erreur
    )
)

echo.
echo Lancement du frontend dans une nouvelle fenetre...
start "Terra Sana - Frontend" /D "%~dp0frontend" "%ComSpec%" /k "npm.cmd start"

echo Attente du demarrage du frontend...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ok=$false; for($i=0;$i -lt 120;$i++){ $c=New-Object Net.Sockets.TcpClient; try{$c.Connect('127.0.0.1',3000);$c.Close();$ok=$true;break}catch{}; Start-Sleep -Seconds 1 }; if(-not $ok){exit 1}"
if errorlevel 1 (
    echo ERREUR : le frontend ne repond pas sur le port 3000.
    echo Consulte la fenetre Terra Sana - Frontend.
    echo Si react-scripts est introuvable, relance installation.bat.
    goto erreur
)

echo.
echo Ouverture du site dans le navigateur...
start "" "http://localhost:3000"
echo Terra Sana est demarre. Garde les fenetres Backend et Frontend ouvertes.
pause
exit /b 0

:erreur
echo.
echo Le demarrage a echoue. Corrige le probleme indique ci-dessus puis relance le script.
pause
exit /b 1
