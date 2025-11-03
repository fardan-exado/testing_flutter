# Setup Guide: Alarm Sholat dengan Suara Adzan

## Masalah yang Diperbaiki

1. ✅ Suara adzan tidak muncul saat waktu sholat tiba
2. ✅ Notifikasi tidak muncul saat aplikasi ditutup
3. ✅ Suara adzan bisa diputar saat app di background/closed

## Perubahan yang Dilakukan

### 1. File: `alarm_service.dart`

#### A. Scheduled Notification (line ~211-287)

**Sebelum:**

```dart
playSound: false, // Tidak play sound
sound: null,
```

**Sesudah:**

```dart
playSound: true, // FIX: Aktifkan sound
sound: const RawResourceAndroidNotificationSound('adzan'), // Custom sound dari raw resource
ongoing: true, // Prevent swipe dismiss
autoCancel: false,
vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
```

**iOS:**

```dart
sound: 'adzan.mp3', // Custom sound
presentSound: true,
```

#### B. Notification Response Handler (line ~79-93)

**Perubahan:**

- Play adzan otomatis saat notification muncul (baik scheduled maupun manual tap)
- Improved stop alarm logic untuk cancel semua notification terkait

### 2. Setup Native Sound Files

#### Android Setup (REQUIRED)

1. **Buat folder raw resources:**

   ```
   android/app/src/main/res/raw/
   ```

2. **Copy file adzan:**

   - Copy file `assets/audio/adzan.mp3`
   - Paste ke `android/app/src/main/res/raw/adzan.mp3`
   - ⚠️ **PENTING:** Nama file harus lowercase, no spaces, no special chars

3. **Format file:**

   - Recommended: MP3 atau OGG
   - Duration: Max 5 minutes (untuk background alarm)
   - Bitrate: 128kbps recommended (balance between quality & size)

4. **Permissions di AndroidManifest.xml:**
   ```xml
   <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
   <uses-permission android:name="android.permission.WAKE_LOCK" />
   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
   <uses-permission android:name="android.permission.VIBRATE" />
   <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   ```

#### iOS Setup

1. **Copy file adzan:**

   - File: `ios/Runner/adzan.mp3`
   - Or add via Xcode: Runner → Add Files to "Runner"

2. **Info.plist permissions:**
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>audio</string>
       <string>fetch</string>
   </array>
   ```

### 3. Cara Kerja Sistem Alarm

#### Skenario 1: App Terbuka (Foreground)

1. Timer checker (`_checkPrayerTimes`) berjalan setiap menit
2. Ketika waktu cocok → trigger `_playAdzan()` + show notification
3. Adzan play via AudioPlayer
4. Notification muncul dengan button "Stop Alarm"

#### Skenario 2: App di Background

1. Scheduled notification trigger di waktu yang tepat
2. Android/iOS play sound dari native resource (adzan.mp3)
3. Notification muncul dengan button "Stop Alarm"
4. Jika user buka app → AudioPlayer bisa play juga

#### Skenario 3: App Ditutup (Closed)

1. ✅ Scheduled notification tetap trigger (exact alarm)
2. ✅ Sound adzan play dari native resource
3. ✅ Notification muncul full screen
4. ✅ User tap notification → app buka → AudioPlayer bisa play

### 4. Testing Checklist

#### Test Scheduled Notification

- [ ] Set alarm 2 menit dari sekarang
- [ ] Tunggu app di foreground → notification + adzan muncul
- [ ] Set alarm lagi, minimize app → notification + sound muncul
- [ ] Set alarm lagi, close app completely → notification + sound muncul

#### Test Stop Alarm

- [ ] Adzan sedang play
- [ ] Tap "Stop Alarm" → adzan stop + notification hilang
- [ ] Verify tidak ada notification yang menggantung

#### Test Daily Repeat

- [ ] Set alarm untuk besok jam 08:00
- [ ] Cek pending notifications → harus ada 1 notification
- [ ] Besok jam 08:00 → notification muncul + adzan play
- [ ] Setelah alarm berbunyi, cek lagi pending notifications → masih ada (karena repeating)

### 5. Troubleshooting

#### Sound tidak muncul saat app closed

**Penyebab:**

- File adzan.mp3 tidak ada di `android/app/src/main/res/raw/`
- Permission exact alarm tidak granted

**Solusi:**

1. Check file exists: `android/app/src/main/res/raw/adzan.mp3`
2. Rebuild app: `flutter clean && flutter build apk`
3. Install ulang app
4. Grant permission exact alarm di Settings

#### Notification tidak muncul saat app closed

**Penyebab:**

- Battery optimization killing background tasks
- Permission denied

**Solusi:**

1. Settings → Apps → [App Name] → Battery → Unrestricted
2. Settings → Apps → [App Name] → Notifications → Enable All
3. Settings → Apps → Special Access → Alarms & Reminders → Enable

#### Sound terlalu panjang/besar

**Solusi:**

1. Compress MP3: Use online tool atau ffmpeg
   ```bash
   ffmpeg -i adzan.mp3 -b:a 128k -ar 44100 adzan_compressed.mp3
   ```
2. Trim duration jika terlalu panjang (max 5 min recommended)

### 6. Production Considerations

#### Battery Impact

- Timer checker setiap 1 menit minimal impact
- Scheduled notification menggunakan exact alarm (efficient)
- Sound file di native resource (no loading delay)

#### Storage Impact

- Adzan MP3 (128kbps, 3-5 min): ~3-5 MB
- Total app size increase: ~5 MB

#### User Experience

- Full screen notification untuk alarm critical
- Can't swipe dismiss (ongoing notification)
- Clear "Stop Alarm" button
- Vibration pattern for attention

### 7. Future Improvements

#### Pilihan Suara Adzan

```dart
// Bisa tambah multiple adzan
enum AdzanType {
  mekah, // adzan_mekah.mp3
  madinah, // adzan_madinah.mp3
  indonesia, // adzan_indonesia.mp3
}

// User bisa pilih via settings
```

#### Volume Control

```dart
// User bisa set volume alarm
SharedPreferences prefs = await SharedPreferences.getInstance();
double volume = prefs.getDouble('alarm_volume') ?? 1.0;
await audioPlayer.setVolume(volume);
```

#### Snooze Feature

```dart
// Tambah snooze button
const AndroidNotificationAction snoozeAction = AndroidNotificationAction(
  'snooze_alarm',
  'Snooze 5 min',
);
```

## Commit Message

```
fix: alarm sholat - enable sound saat app closed

- Enable notification sound dengan custom adzan dari native resource
- Add vibration pattern untuk perhatian user
- Set ongoing notification (can't swipe dismiss)
- Improved notification response handler untuk play adzan
- Add comprehensive setup guide untuk native sound files

BREAKING CHANGE: Requires manual setup of adzan.mp3 in native resources
- Android: android/app/src/main/res/raw/adzan.mp3
- iOS: ios/Runner/adzan.mp3

Fixes notification sound not playing when app is closed/background
```
