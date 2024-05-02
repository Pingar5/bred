@ECHO OFF

odin build src -out:.build/editor.exe -debug -collection:bred=src -strict-style

if %errorlevel% NEQ 0 exit /b %errorlevel%

cd .build
editor.exe
cd ..