# Quick Start: Fix Alarm Sholat

## 🚀 Langkah Cepat (5 Menit)

### 1. Copy File Adzan ke Native Resources

#### Windows

```cmd
setup_alarm_sound.bat
```

#### Manual (jika script error)

```cmd
REM Buat folder
mkdir android\app\src\main\res\raw

REM Copy file
copy assets\audio\adzan.mp3 android\app\src\main\res\raw\adzan.mp3
```

### 2. Rebuild App

```cmd
flutter clean
flutter pub get
flutter build apk
```

### 3. Install & Test

```cmd
flutter install
```

## ✅ Apa yang Sudah Diperbaiki

### Before (❌ Broken)

- ❌ Test alarm: suara muncul
- ❌ Waktu sholat: **HANYA notifikasi, TIDAK ada suara**
- ❌ App ditutup: **TIDAK ada notifikasi & suara**

### After (✅ Fixed)

- ✅ Test alarm: suara muncul
- ✅ Waktu sholat: **notifikasi + suara adzan muncul**
- ✅ App ditutup: **notifikasi + suara adzan tetap muncul**

## 🎯 Cara Kerja Baru

### Saat App Terbuka (Foreground)

```
Waktu Sholat Tiba
    ↓
Timer Checker Detect (setiap menit)
    ↓
Play Adzan via AudioPlayer
    +
Show Notification dengan button "Stop Alarm"
```

### Saat App Ditutup (Background/Closed) ⭐ NEW!

```
Waktu Sholat Tiba
    ↓
Scheduled Notification Trigger (Android System)
    ↓
Play Adzan dari Native Resource (android/app/src/main/res/raw/adzan.mp3)
    +
Show Full Screen Notification dengan button "Stop Alarm"
    ↓
User Buka App (opsional)
    ↓
AudioPlayer juga play (double sound prevention handled)
```

## 🧪 Testing Checklist

### Test 1: App Terbuka

1. Set alarm 2 menit dari sekarang
2. Biarkan app tetap terbuka
3. ✅ Saat waktu tiba: Notifikasi + Adzan play

### Test 2: App di Background

1. Set alarm 2 menit dari sekarang
2. Minimize app (tekan Home button)
3. ✅ Saat waktu tiba: Notifikasi + Adzan play dari system

### Test 3: App Ditutup Completely ⭐ CRITICAL

1. Set alarm 2 menit dari sekarang
2. **Close app completely** (swipe dari recent apps)
3. ✅ Saat waktu tiba: Notifikasi + Adzan play dari system
4. ✅ Notification muncul full screen
5. ✅ Button "Stop Alarm" berfungsi

### Test 4: Stop Alarm

1. Saat adzan play
2. Tap button "Stop Alarm"
3. ✅ Adzan stop immediately
4. ✅ Notification hilang

### Test 5: Repeating Daily

1. Set alarm untuk besok pagi
2. Cek: Pasti ada 1 pending notification
3. ✅ Besok pagi notification + adzan muncul
4. ✅ Setelah alarm berbunyi, masih ada pending notification (karena repeat daily)

## 🔧 Troubleshooting

### Suara tidak muncul saat app closed

**Check 1: File adzan ada?**

```cmd
dir android\app\src\main\res\raw\adzan.mp3
```

Jika tidak ada → jalankan `setup_alarm_sound.bat`

**Check 2: Permission granted?**

```
Settings → Apps → Shollover → Permissions
- Exact Alarms: ✅ Allowed
- Notifications: ✅ Allowed
```

**Check 3: Battery optimization?**

```
Settings → Apps → Shollover → Battery
- ⚙️ Set to: Unrestricted
```

### Notification tidak muncul saat app closed

**Solusi:**

1. Uninstall app completely
2. Rebuild & reinstall
3. Grant all permissions saat pertama buka app

### Sound terlalu keras/pelan

**Sementara:** Atur volume device

**Future:** Akan ditambah setting volume alarm di app

## 📱 Tested On

- ✅ Android 13 (API 33)
- ✅ Android 12 (API 31)
- ✅ Android 11 (API 30)
- ⚠️ iOS (belum ditest - perlu Xcode setup)

## 🎉 Selesai!

Alarm sholat sekarang:

- ✅ Suara adzan muncul saat waktu sholat
- ✅ Bekerja bahkan saat app ditutup
- ✅ Full screen notification untuk alarm critical
- ✅ Button "Stop Alarm" yang jelas
- ✅ Repeat otomatis setiap hari

**Alhamdulillah! 🤲**
