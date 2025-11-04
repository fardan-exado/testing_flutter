# Troubleshooting: Alarm Sound Error

## Error: "Gagal memuat alarm karena sound tidak ditemukan di res/adzan.mp3"

### Root Cause

Android tidak menemukan file sound di native resources karena:

1. File `adzan.mp3` belum dicopy ke `android/app/src/main/res/raw/`
2. App belum di-rebuild setelah file dicopy
3. Nama resource salah (harus tanpa ekstensi `.mp3`)

---

## ✅ SOLUSI LENGKAP (Step by Step)

### Step 1: Copy File Adzan ke Native Resources

**Cara 1 - Otomatis (Recommended):**

```cmd
.\setup_alarm_sound.bat
```

**Cara 2 - Manual:**

```cmd
REM Buat folder jika belum ada
mkdir android\app\src\main\res\raw

REM Copy file
copy assets\audio\adzan.mp3 android\app\src\main\res\raw\adzan.mp3
```

### Step 2: Verifikasi File Sudah Ada

```cmd
ls android\app\src\main\res\raw\adzan.mp3
```

**Output yang benar:**

```
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        10/28/2025   3:36 PM        1423360 adzan.mp3
```

✅ File size: ~1.4 MB  
✅ Location: `android/app/src/main/res/raw/adzan.mp3`

### Step 3: Clean Build (WAJIB!)

```cmd
flutter clean
```

**Kenapa harus clean?**

- Android perlu rebuild untuk recognize resource baru di folder `raw/`
- Cache lama bisa menyebabkan resource tidak terdeteksi

### Step 4: Get Dependencies

```cmd
flutter pub get
```

### Step 5: Build APK

```cmd
flutter build apk --release
```

**Note:** Build release akan membuat APK yang optimal untuk testing di device

### Step 6: Install ke Device

```cmd
flutter install
```

Atau install manual:

1. APK ada di: `build/app/outputs/flutter-apk/app-release.apk`
2. Copy ke device
3. Install APK

### Step 7: Test Alarm

1. Buka app
2. Set alarm 2 menit dari sekarang
3. **Close app completely** (swipe dari recent apps)
4. Tunggu 2 menit
5. ✅ Notification + Adzan harus muncul

---

## 🔍 Debugging

### Check 1: File Exists?

```cmd
ls android\app\src\main\res\raw\
```

**Harus ada file:**

- `adzan.mp3` (1.4 MB)

### Check 2: File Permission?

```cmd
Get-Acl android\app\src\main\res\raw\adzan.mp3 | Format-List
```

**Pastikan:**

- FullControl: BUILTIN\Administrators
- Read & Execute: Everyone

### Check 3: Build Success?

Lihat log saat `flutter build apk`:

```
✓ Built build\app\outputs\flutter-apk\app-release.apk (XX.X MB).
```

Jika ada error tentang resource, berarti file tidak terdeteksi.

### Check 4: APK Contains Resource?

Extract APK dan check:

```cmd
REM Rename APK to ZIP
copy build\app\outputs\flutter-apk\app-release.apk app-release.zip

REM Extract dengan 7zip/WinRAR
REM Check folder: res/raw/adzan.mp3
```

---

## ⚠️ Common Mistakes

### ❌ Mistake 1: File di folder salah

```
SALAH: android/app/src/main/assets/adzan.mp3
BENAR: android/app/src/main/res/raw/adzan.mp3
```

### ❌ Mistake 2: Tidak rebuild

```
❌ Copy file → Run app (ERROR!)
✅ Copy file → Flutter clean → Build → Run app (OK!)
```

### ❌ Mistake 3: Nama file salah

```
❌ File: adzan_sound.mp3 → Code: 'adzan'
✅ File: adzan.mp3 → Code: 'adzan'
```

### ❌ Mistake 4: Include extension di code

```dart
❌ sound: RawResourceAndroidNotificationSound('adzan.mp3')
✅ sound: RawResourceAndroidNotificationSound('adzan')
```

---

## 📋 Verification Checklist

Sebelum report error, pastikan:

- [ ] ✅ File `adzan.mp3` ada di `android/app/src/main/res/raw/`
- [ ] ✅ File size ~1.4 MB (not 0 bytes)
- [ ] ✅ Sudah jalankan `flutter clean`
- [ ] ✅ Sudah jalankan `flutter pub get`
- [ ] ✅ Sudah rebuild APK (`flutter build apk`)
- [ ] ✅ Uninstall app lama dari device
- [ ] ✅ Install APK baru
- [ ] ✅ Close app completely saat test
- [ ] ✅ Wait for notification (tidak buka app dulu)

---

## 🎯 Expected Behavior

### Test 1: App Foreground ✅

```
Set Alarm → Keep app open → Notification muncul → Adzan play via AudioPlayer
```

### Test 2: App Background ✅

```
Set Alarm → Minimize app → Notification muncul → Adzan play dari native
```

### Test 3: App Closed ✅ (MOST IMPORTANT)

```
Set Alarm → Close app completely → Notification muncul → Adzan play dari native
```

---

## 🐛 Still Not Working?

### Debug Log

Lihat Android logcat:

```cmd
adb logcat | findstr "Alarm"
adb logcat | findstr "notification"
adb logcat | findstr "sound"
```

Look for errors like:

- `Resource not found: adzan`
- `Unable to play notification sound`
- `ResourceNotFoundException`

### Alternative Solution: Use Default Sound

Jika masih error, temporary gunakan default sound:

```dart
// Temporary workaround
sound: null, // Use default notification sound
playSound: true,
```

Lalu:

1. Build & test dulu dengan default sound
2. Jika notification + default sound work → masalahnya di custom sound
3. Re-check file location & rebuild

---

## 📞 Report Issue

Jika masih error, berikan info:

1. Output dari `ls android\app\src\main\res\raw\`
2. Output dari `flutter build apk` (full log)
3. Output dari `adb logcat | findstr "Alarm"`
4. Screenshot error message
5. Device info: Model, Android version

---

## ✅ Success Indicators

Jika berhasil, Anda akan lihat:

```
[AlarmService] Notification scheduled for Shubuh at 04:30
[AlarmService] Notification verified for Shubuh: true
```

Dan saat waktu tiba:

```
[System] Playing notification sound: adzan
[AlarmService] Notification shown for Shubuh
```

**Alhamdulillah! 🎉**
