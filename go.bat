@echo off

del /Q atommc2*.rom

atasm -v -r -f255 -oatommc2.rom cli.asm >trace.lst
if not "%errorlevel%" == "0" goto failed

:done
rem pause
exit /B

:failed
@echo Failed to assemble (%ErrorLevel%)
rem pause
exit /B
