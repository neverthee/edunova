@echo off
setlocal

set "ROOT_DIR=%~dp0"
set "PYTHON_EXE=C:\Users\86152\.conda\envs\edunova2\python.exe"
if defined PYTHON_EXE_OVERRIDE set "PYTHON_EXE=%PYTHON_EXE_OVERRIDE%"
if exist "%PYTHON_EXE%" (
  for %%I in ("%PYTHON_EXE%") do set "CONDA_ENV_DIR=%%~dpI"
)

set PYTHONNOUSERSITE=1
if defined CONDA_ENV_DIR set "PATH=%CONDA_ENV_DIR%;%CONDA_ENV_DIR%Scripts;%CONDA_ENV_DIR%Library\bin;%PATH%"

if not exist "%ROOT_DIR%backend\main.py" goto :error
where "%PYTHON_EXE%" >nul 2>nul
if errorlevel 1 if not exist "%PYTHON_EXE%" goto :error_python

pushd "%ROOT_DIR%"
"%PYTHON_EXE%" backend\main.py
set "EXIT_CODE=%errorlevel%"
popd
exit /b %EXIT_CODE%

:error_python
echo Failed to start backend. Python executable was not found: %PYTHON_EXE%
exit /b 1

:error
echo Failed to start backend. backend\main.py was not found under: %ROOT_DIR%
exit /b 1
