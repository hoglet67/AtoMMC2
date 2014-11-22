@echo off
del /Q *.rom

bin\ca65 -l atommc2.asm
if not "%errorlevel%" == "0" goto failed

bin\ld65 atommc2.o -C atommc2.lkr -o atommc2.rom
if not "%errorlevel%" == "0" goto failed

copy atommc2.rom "%mess137%\roms\atom\mmc.rom" /Y

del *.o

:done
exit /B

:failed
@echo Failed to assemble (%ErrorLevel%)
pause
exit /B
