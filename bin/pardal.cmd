@echo off
REM pardal - command interface of the ruby-sinatra educational server.
REM
REM Windows cannot run bin\pardal directly, because it is a Ruby file without
REM an extension. This wrapper calls the same script through Ruby and keeps the
REM exit code, so `bin\pardal.cmd setup` behaves like `bin/pardal setup`.

setlocal

ruby -v >nul 2>&1
if errorlevel 1 (
  echo Ruby not found. Install Ruby and make sure it is in the PATH:
  echo https://www.ruby-lang.org/en/downloads/
  exit /b 1
)

ruby "%~dp0pardal" %*
exit /b %ERRORLEVEL%