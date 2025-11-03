@echo off
echo ========================================
echo Setup Alarm Sholat - Copy Adzan Sound
echo ========================================
echo.

REM Check if source file exists
if not exist "assets\audio\adzan.mp3" (
    echo ERROR: Source file not found: assets\audio\adzan.mp3
    echo Please make sure adzan.mp3 exists in assets/audio/ folder
    pause
    exit /b 1
)

echo Found source file: assets\audio\adzan.mp3
echo.

REM Create Android raw folder if not exists
if not exist "android\app\src\main\res\raw" (
    echo Creating Android raw resources folder...
    mkdir "android\app\src\main\res\raw"
    echo Created: android\app\src\main\res\raw
) else (
    echo Android raw folder exists
)

REM Copy to Android
echo Copying to Android resources...
copy /Y "assets\audio\adzan.mp3" "android\app\src\main\res\raw\adzan.mp3"
if %errorlevel% equ 0 (
    echo SUCCESS: Copied to android\app\src\main\res\raw\adzan.mp3
) else (
    echo ERROR: Failed to copy to Android
)
echo.

REM Create iOS Runner folder if not exists
if not exist "ios\Runner" (
    echo WARNING: iOS Runner folder not found
    echo Skipping iOS setup
) else (
    echo Copying to iOS resources...
    copy /Y "assets\audio\adzan.mp3" "ios\Runner\adzan.mp3"
    if %errorlevel% equ 0 (
        echo SUCCESS: Copied to ios\Runner\adzan.mp3
        echo.
        echo IMPORTANT for iOS:
        echo 1. Open Xcode project: ios/Runner.xcworkspace
        echo 2. Right-click on Runner folder
        echo 3. Add Files to "Runner"
        echo 4. Select adzan.mp3
        echo 5. Check "Copy items if needed"
    ) else (
        echo ERROR: Failed to copy to iOS
    )
)

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Check that files are copied correctly
echo 2. For iOS: Add file via Xcode (see instructions above)
echo 3. Run: flutter clean
echo 4. Run: flutter build apk (for Android)
echo 5. Install and test the app
echo.
echo See ALARM_SETUP_GUIDE.md for more details
echo.
pause
