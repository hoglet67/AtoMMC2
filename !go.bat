@echo off

del /Q atommc2.????.rom

atasm -v -r -f255 -oatommc2.rom cli.asm >trace.lst
if not "%errorlevel%" == "0" goto failed

rem bin2atm atommc2.rom load=0x8200 out=ri
rem crccitt atommc2.rom

copy atommc2.rom D:\_Dev_\dev\user\CharlieRobson\mess137\roms\atom\mmc.rom /Y

:done
pause
exit /B

:failed
@echo Failed to assemble (%ErrorLevel%)
pause
exit /B
