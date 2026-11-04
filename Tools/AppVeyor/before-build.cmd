@echo off
setlocal
pushd "%~dp0"
if errorlevel 1 exit /b 1

curl -fL --retry 3 --retry-delay 2 -sS https://drive.google.com/uc?id=17ZK6a1kxhTR-YOkWpAOqNJZA7UBUGkmu --output Microsoft.DriverKit.Build.Tasks.14.0.dll
if errorlevel 1 (
  echo Failed to download Microsoft.DriverKit.Build.Tasks.14.0.dll
  popd
  exit /b 1
)

if not exist Microsoft.DriverKit.Build.Tasks.14.0.dll (
  echo Microsoft.DriverKit.Build.Tasks.14.0.dll was not downloaded
  popd
  exit /b 1
)

for %%I in (Microsoft.DriverKit.Build.Tasks.14.0.dll) do if %%~zI EQU 0 (
  echo Microsoft.DriverKit.Build.Tasks.14.0.dll is empty
  popd
  exit /b 1
)

copy /y Microsoft.DriverKit.Build.Tasks.14.0.dll "C:\Program Files (x86)\Windows Kits\10\build\bin"
if errorlevel 1 (
  echo Failed to install Microsoft.DriverKit.Build.Tasks.14.0.dll
  popd
  exit /b 1
)
popd
endlocal
