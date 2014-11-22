@echo off
del /Q *.rom

set CLONE=z:\retro\acorn\atom\roms\AtomClone

echo Converting constants
bin\htoasm ..\PICFirmware\atmmc2def.h atmmc2def.asm

echo Assembling
rem bin\ca65 -DAVR -l -o a000.o atommc2.asm
rem if not "%errorlevel%" == "0" goto failed
bin\ca65 -DAVR -l -o e000.o -D EOOO atommc2.asm
if not "%errorlevel%" == "0" goto failed

echo Linking
rem bin\ld65 a000.o -C atommc2-a000.lkr -o atommc2-2.9-a000.rom
rem if not "%errorlevel%" == "0" goto failed
bin\ld65 e000.o -C atommc2-e000.lkr -o atommc2-2.9-e000.rom
if not "%errorlevel%" == "0" goto failed

echo Copying
rem you might not want this section...

copy atommc2-2.9-e000.rom "%CLONE%\atommc2-2.9-e000.rom" /Y

echo Cleaning
del /Q *.o

:done
echo OK
REM pause
exit /B

:failed
@echo Failed to assemble (%ErrorLevel%)
REM pause
exit /B
