@echo off
echo Starting local server for admin dashboard...
echo.
echo Open your browser and go to: http://localhost:8001
echo Press Ctrl+C to stop the server
echo.
cd /d %~dp0
python -m http.server 8001
