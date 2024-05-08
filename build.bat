@ECHO OFF

odin build src -out:.build/editor.exe -debug -collection:bred=src -collection:user=user -strict-style

if %errorlevel% NEQ 0 exit /b %errorlevel%

cd .build
editor.exe
if %errorlevel% NEQ 0 echo Editor exited with code %errorlevel%
cd ..