@echo off
set GGAPP_ROOT=%~dp0
set SETX=setx
%SETX% GGAPP_ROOT %GGAPP_ROOT%

echo.
echo config:
echo.
echo GGAPP_ROOT = "%GGAPP_ROOT%"
echo.

pause
