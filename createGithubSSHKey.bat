@echo off
set SSH_DIR=%USERPROFILE%\.ssh
set KEY_NAME=githubKeyWindows
set PUB_KEY_NAME=%KEY_NAME%.pub
set CONFIG_FILE=%SSH_DIR%\config

REM Check if .ssh directory exists, and create it if not
if not exist "%SSH_DIR%" mkdir "%SSH_DIR%"

REM Prompt user to press Enter twice for no passphrase
echo Please enter twice for no passphrase

REM Generate SSH key pair
ssh-keygen -t rsa -f "%SSH_DIR%\%KEY_NAME%"

REM Create or append to the config file
echo Host github.com >> "%CONFIG_FILE%"
echo     User git >> "%CONFIG_FILE%"
echo     Hostname github.com >> "%CONFIG_FILE%"
echo     PreferredAuthentications publickey >> "%CONFIG_FILE%"
echo     IdentityFile "%SSH_DIR%\%KEY_NAME%" >> "%CONFIG_FILE%"

REM Copy public key to clipboard
type "%SSH_DIR%\%PUB_KEY_NAME%" | clip
color 2
echo SSH key pair generated, config file updated, and public key copied to clipboard
pause
