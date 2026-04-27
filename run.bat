@echo off
setlocal
title EduNova Launcher

set "ROOT_DIR=%~dp0"
set "FRONTEND_SCRIPT=%ROOT_DIR%start_frontend.bat"
set "BACKEND_SCRIPT=%ROOT_DIR%start_backend.bat"

if not exist "%FRONTEND_SCRIPT%" (
  echo [ERROR] Frontend launcher not found: %FRONTEND_SCRIPT%
  exit /b 1
)

if not exist "%BACKEND_SCRIPT%" (
  echo [ERROR] Backend launcher not found: %BACKEND_SCRIPT%
  exit /b 1
)

start "EduNova Frontend" cmd /k call "%FRONTEND_SCRIPT%"
start "EduNova Backend" cmd /k call "%BACKEND_SCRIPT%"

endlocal
exit /b 0
