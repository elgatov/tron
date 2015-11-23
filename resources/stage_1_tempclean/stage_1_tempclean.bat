:: Purpose:       Sub-script containing all commands for Tron's Stage 1: Temp Cleanup stage. Is called by tron.bat and then returns control to tron.bat when finished
:: Requirements:  1. Administrator access
::                2. Safe mode is strongly recommended (though not required)
::                3. Called from tron.bat. If you try to run this script directly
:: Author:        vocatus on reddit.com/r/TronScript ( vocatus.gate at gmail ) // PGP key: 0x07d1490f82a211a2
:: Version:       0.9.0 + Initial write

:: Quick check to see if we inherited the appropriate variables from Tron.bat
if /i "%LOGFILE%"=="" (
	color 0c
	echo.
	echo  ERROR
	echo.
	echo   Missing the LOGFILE variable from Tron.bat
	echo   You cannot run this script directly - it must be 
	echo   called from Tron.bat during a Tron run.
	echo.
	pause
	exit /b 1
	)

	
	
	

::::::::::::::::::::::::
:: STAGE 1: TEMPCLEAN :: // Begin jobs
::::::::::::::::::::::::

:: JOB: Clean Internet Explorer; Windows built-in method. Only works on Vista and up
if /i not "%WIN_VER:~0,9%"=="Microsoft" (
	title TRON v%SCRIPT_VERSION% [stage_1_tempclean] [Clean Internet Explorer]
	call :log "%CUR_DATE% %TIME%    Launch job 'Clean Internet Explorer'..."
	if /i %DRY_RUN%==no rundll32.exe inetcpl.cpl,ClearMyTracksByProcess 4351
	call :log "%CUR_DATE% %TIME%    Done."
)


:: JOB: TempFileCleanup.bat
title TRON v%SCRIPT_VERSION% [stage_1_tempclean] [TempFileCleanup]
call :log "%CUR_DATE% %TIME%    Launch job 'TempFileCleanup'..."
if /i %DRY_RUN%==no call stage_1_tempclean\tempfilecleanup\TempFileCleanup.bat >> "%LOGPATH%\%LOGFILE%" 2>NUL
:: Reset window title since TempFileCleanup clobbers it
title TRON v%SCRIPT_VERSION% [stage_1_tempclean]
call :log "%CUR_DATE% %TIME%    Done."


:: JOB: CCLeaner
title TRON v%SCRIPT_VERSION% [stage_1_tempclean] [CCleaner]
call :log "%CUR_DATE% %TIME%    Launch job 'CCleaner'..."
if /i %DRY_RUN%==no (
	start "" /wait stage_1_tempclean\ccleaner\ccleaner.exe /auto>> "%LOGPATH%\%LOGFILE%" 2>NUL
	ping 127.0.0.1 -n 12 >NUL
	)
call :log "%CUR_DATE% %TIME%    Done."


:: JOB: BleachBit
title TRON v%SCRIPT_VERSION% [stage_1_tempclean] [BleachBit]
call :log "%CUR_DATE% %TIME%    Launch job 'BleachBit'..."
if /i %DRY_RUN%==no (
	if %VERBOSE%==yes stage_1_tempclean\bleachbit\bleachbit_console.exe -p --preset
	stage_1_tempclean\bleachbit\bleachbit_console.exe --preset -c >> "%LOGPATH%\%LOGFILE%" 2>NUL
	ping 127.0.0.1 -n 12 >NUL
	)
call :log "%CUR_DATE% %TIME%    Done."


:: JOB: USB Device Cleanup
title TRON v%SCRIPT_VERSION% [stage_1_tempclean] [USB Device Cleanup]
call :log "%CUR_DATE% %TIME%    Launch job 'USB Device Cleanup'..."
if /i %DRY_RUN%==no (
if /i '%PROCESSOR_ARCHITECTURE%'=='AMD64' (
	if %VERBOSE%==yes "stage_1_tempclean\usb_cleanup\DriveCleanup x64.exe" -t -n
	"stage_1_tempclean\usb_cleanup\DriveCleanup x64.exe" -n >> "%LOGPATH%\%LOGFILE%" 2>NUL
) else (
	if %VERBOSE%==yes "stage_1_tempclean\usb_cleanup\DriveCleanup x86.exe" -t -n
	"stage_1_tempclean\usb_cleanup\DriveCleanup x86.exe" -n >> "%LOGPATH%\%LOGFILE%" 2>NUL
	)
)
call :log "%CUR_DATE% %TIME%    Done."


:: JOB: Clear Windows event logs
title TRON v%SCRIPT_VERSION% [stage_1_tempclean] [Clear Windows Event Logs]
call :log "%CUR_DATE% %TIME%    Launch job 'Clear Windows event logs'..."
if /i %SKIP_EVENT_LOG_CLEAR%==yes (
	call :log "%CUR_DATE% %TIME% ! SKIP_EVENT_LOG_CLEAR ^(-se^) set. Skipping Event Log clear."
	goto skip_event_log_clear
	)
call :log "%CUR_DATE% %TIME%    Saving logs to "%BACKUPS%" first..."
:: Backup all logs first. Redirect error output to NUL (2>nul) because due to the way WMI formats lists, there is
:: a trailing blank line which messes up the last iteration of the FOR loop, but we can safely suppress errors from it
SETLOCAL ENABLEDELAYEDEXPANSION
if /i %DRY_RUN%==no for /f %%i in ('%WMIC% nteventlog where "filename like '%%'" list instance') do %WMIC% nteventlog where "filename like '%%%%i%%'" backupeventlog "%BACKUPS%\%%i.evt" >> "%LOGPATH%\%LOGFILE%" 2>NUL
ENDLOCAL DISABLEDELAYEDEXPANSION
call :log "%CUR_DATE% %TIME%    Backups done, now clearing..."
:: Clear the logs
if /i %DRY_RUN%==no %WMIC% nteventlog where "filename like '%%'" cleareventlog >> "%LOGPATH%\%LOGFILE%"
:: Alternate Vista-and-up only method
:: if /i %DRY_RUN%==no for /f %%x in ('wevtutil el') do wevtutil cl "%%x" 2>NUL

call :log "%CUR_DATE% %TIME%    Done."
:skip_event_log_clear



:: JOB: Clear Windows Update cache
title TRON v%SCRIPT_VERSION% [stage_1_tempclean] [Clear Windows Update cache]
call :log "%CUR_DATE% %TIME%    Launch job 'Clear Windows Update cache'..."
if /i %DRY_RUN%==no (
	:: Allow us to start the service in Safe Mode. Thanks to /u/GrizzlyWinter
	reg add "HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\%SAFEBOOT_OPTION%\WUAUSERV" /ve /t reg_sz /d Service /f >> "%LOGPATH%\%LOGFILE%" 2>&1
	net stop WUAUSERV >> "%LOGPATH%\%LOGFILE%" 2>&1
	if exist %windir%\softwaredistribution\download rmdir /s /q %windir%\softwaredistribution\download >> "%LOGPATH%\%LOGFILE%" 2>&1
	net start WUAUSERV >> "%LOGPATH%\%LOGFILE%" 2>&1
	)
call :log "%CUR_DATE% %TIME%    Done."







:::::::::::::::
:: FUNCTIONS ::
:::::::::::::::
:: We have to duplicate the log function since it doesn't get inherited from tron.bat when the script is called
:log
echo:%~1 >> "%LOGPATH%\%LOGFILE%"
echo:%~1
goto :eof