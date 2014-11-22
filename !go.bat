@echo off
del /Q *.rom

set VSN="2.7"

echo Assembling
bin\ca65 -l -o a000.o atommc2.asm
if not "%errorlevel%" == "0" goto failed
bin\ca65 -l -o e000.o -D EOOO atommc2.asm
if not "%errorlevel%" == "0" goto failed

echo Linking
bin\ld65 a000.o -C atommc2-a000.lkr -o atommc2-%VSN%-a000.rom
if not "%errorlevel%" == "0" goto failed
bin\ld65 e000.o -C atommc2-e000.lkr -o atommc2-%VSN%-e000.rom
if not "%errorlevel%" == "0" goto failed

echo Copying
rem you might not want this section...
copy atommc2-%VSN%-a000.rom "%mess%\roms\atom-a000\mmc.rom" /Y
copy atommc2-%VSN%-e000.rom "%mess%\roms\atom-e000\dosrom.u15" /Y
rem copy atommc2-%VSN%-a000.rom ..\..\..\ramoth\ /y
rem copy atommc2-%VSN%-e000.rom ..\..\..\ramoth\ /y

echo Cleaning
del /Q *.o

:done
echo OK
pause
exit /B

:failed
@echo Failed to assemble (%ErrorLevel%)
pause
exit /B
