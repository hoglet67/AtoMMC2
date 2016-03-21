@echo off
del /Q *.rom

set ROMBOX=z:\retro\acorn\atom\roms\phsmmc
set CLONE=z:\retro\acorn\atom\roms\AtomClone
set MESS=g:\emulate\software\atom\roms

echo Converting constants
bin\htoasm ..\PICFirmware\atmmc2def.h atmmc2def.asm

echo Assembling
bin\ca65 -l -o a000.o atommc2.asm
if not "%errorlevel%" == "0" goto failed
bin\ca65 -l -o e000.o -D EOOO atommc2.asm
if not "%errorlevel%" == "0" goto failed

echo Linking
bin\ld65 a000.o -C atommc2-a000.lkr -o atommc2-3.0-a000.rom
if not "%errorlevel%" == "0" goto failed
bin\ld65 e000.o -C atommc2-e000.lkr -o atommc2-3.0-e000.rom
if not "%errorlevel%" == "0" goto failed

echo Copying
rem you might not want this section...
copy atommc2-3.0-a000.rom "%mess%" /Y
copy atommc2-3.0-e000.rom "%mess%" /Y

copy atommc2-3.0-a000.rom "%ROMBOX%\atommc2-3.0-a000.rom" /Y
copy atommc2-3.0-e000.rom "%ROMBOX%\atommc2-3.0-e000.rom" /Y
copy atommc2-3.0-e000.rom "%CLONE%\atommc2-3.0-e000.rom" /Y

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
