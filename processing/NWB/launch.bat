@echo off
REM Launch the widefield NWB metadata parser in MATLAB (batch mode).
REM
REM Defaults assume MATLAB R2019a and that parse_widefield.m sits next to this
REM .bat file. Override either by setting environment variables before running:
REM   set "MATLAB_EXE=C:\Program Files\MATLAB\R2023b\bin\matlab.exe"
REM   set "WF_PARSE_SCRIPT=C:\path\to\parse_widefield.m"

if "%MATLAB_EXE%"=="" set "MATLAB_EXE=C:\Program Files\MATLAB\R2019a\bin\matlab.exe"
if "%WF_PARSE_SCRIPT%"=="" set "WF_PARSE_SCRIPT=%~dp0parse_widefield.m"

"%MATLAB_EXE%" -nosplash -nodesktop -r "run('%WF_PARSE_SCRIPT%'); exit;"
