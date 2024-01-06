@echo off
set folder="build_output"
if exist %folder% rmdir /s /q %folder%
mkdir %folder%

move assets\debug_secrets.json .

:: Windows
echo Building Windows
call flutter build windows
if not exist %folder%\windows mkdir %folder%\windows
move build\windows\x64\runner\Release\* %folder%\windows

move debug_secrets.json assets