@echo off
echo ========================================
echo Rebuild App Setelah Setup Alarm
echo ========================================
echo.

echo Step 1: Cleaning build cache...
call flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Flutter clean failed!
    pause
    exit /b 1
)
echo DONE: Build cache cleaned
echo.

echo Step 2: Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Flutter pub get failed!
    pause
    exit /b 1
)
echo DONE: Dependencies updated
echo.

echo Step 3: Building APK (Release mode)...
echo This may take a few minutes...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo ERROR: Build failed!
    pause
    exit /b 1
)
echo DONE: APK built successfully
echo.

echo ========================================
echo Build Complete!
echo ========================================
echo.
echo APK Location:
echo build\app\outputs\flutter-apk\app-release.apk
echo.
echo Next steps:
echo 1. Uninstall old app from device
echo 2. Run: flutter install
echo    OR
echo    Copy APK to device and install manually
echo.
echo 3. Test alarm by:
echo    - Set alarm 2 minutes from now
echo    - CLOSE app completely (swipe from recent apps)
echo    - Wait for notification + adzan sound
echo.
pause
