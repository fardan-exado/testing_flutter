# Update Sholat Feature - Integrasi API Kemenag

## Ringkasan Perubahan

Telah dilakukan update pada fitur sholat untuk mengintegrasikan API Kementerian Agama RI, memperbaiki struktur code, dan menambahkan input form yang lebih lengkap untuk tracking progress sholat.

## File yang Diubah

### 1. `sholat_service.dart`
**Perubahan:**
- ✅ Menambahkan import `intl` untuk format tanggal
- ✅ Update method `getJadwalSholat()` untuk format tanggal sesuai API Kemenag (yyyy-MM-dd)
- ✅ Menggabungkan method `addProgressSholatWajib` dan `addProgressSholatSunnah` menjadi satu method universal `addProgressSholat()`
- ✅ Menggabungkan method `deleteProgressSholatWajib` dan `deleteProgressSholatSunnah` menjadi satu method universal `deleteProgressSholat()`
- ✅ Menambahkan dokumentasi lengkap tentang integrasi API Kemenag
- ✅ Update parameter method `addProgressSholat()` untuk mendukung status yang lebih lengkap dan keterangan

**Detail Perubahan:**

#### Method `getJadwalSholat()`
```dart
// SEBELUM: Format tanggal tidak eksplisit
queryParameters: {
  'latitude': latitude,
  'longitude': longitude,
  'start_date': startDate,
  'end_date': endDate,
}

// SESUDAH: Format tanggal eksplisit untuk API Kemenag
final formatter = DateFormat('yyyy-MM-dd');
final startDateStr = formatter.format(startDate);
final endDateStr = formatter.format(endDate);

queryParameters: {
  'latitude': latitude,
  'longitude': longitude,
  'start_date': startDateStr,
  'end_date': endDateStr,
}
```

#### Method `addProgressSholat()` (Universal)
```dart
// SEBELUM: Dua method terpisah dengan parameter boolean

// SESUDAH: Satu method universal dengan status dan keterangan
static Future<Map<String, dynamic>> addProgressSholat({
  required String jenis,  // 'wajib' atau 'sunnah'
  required String sholat,
  required String status, // 'tepat_waktu', 'terlambat', 'tidak_sholat'
  bool? isJamaah,        // nullable, hanya untuk wajib
  String? lokasi,        // nullable, hanya untuk wajib
  String? keterangan,    // nullable, hanya untuk wajib
}) async {
  final endpoint = jenis.toLowerCase() == 'wajib'
      ? '/sholat/wajib/progres'
      : '/sholat/sunnah/progres';

  final data = jenis.toLowerCase() == 'wajib'
      ? {
          'sholat': sholat,
          'status': status, // tepat_waktu, terlambat, tidak_sholat
          'is_jamaah': isJamaah == true ? 1 : 0,
          'lokasi': lokasi ?? '',
          'keterangan': keterangan ?? '',
        }
      : {
          'sholat': sholat,
          'status': status,
        };
  // ...
}
```

#### Method `deleteProgressSholat()` (Universal)
```dart
// SEBELUM: Dua method terpisah

// SESUDAH: Satu method universal
static Future<Map<String, dynamic>> deleteProgressSholat({
  required int id,
  String jenis = 'wajib',  // default 'wajib'
}) async {
  final endpoint = jenis.toLowerCase() == 'wajib'
      ? '/sholat/wajib/progres/$id'
      : '/sholat/sunnah/progres/$id';
  // ...
}
```

### 2. `sholat_provider.dart`
**Perubahan:**
- ✅ Update method `addProgressSholat()` untuk menggunakan `Future.wait()` saat refresh progress
- ✅ Update method `deleteProgressSholat()` untuk menerima parameter `jenis` dan menggunakan `Future.wait()`
- ✅ Menambahkan dokumentasi lengkap tentang strategi caching dan integrasi API Kemenag
- ✅ Optimasi refresh progress dengan parallel execution

**Detail Perubahan:**

#### Method `addProgressSholat()`
```dart
// SEBELUM: Sequential refresh
if (jenis.toLowerCase() == 'wajib') {
  await fetchProgressSholatWajibHariIni(forceRefresh: true);
  await fetchProgressSholatWajibRiwayat(forceRefresh: true);
}

// SESUDAH: Parallel refresh untuk performa lebih baik
if (jenis.toLowerCase() == 'wajib') {
  await Future.wait([
    fetchProgressSholatWajibHariIni(forceRefresh: true),
    fetchProgressSholatWajibRiwayat(forceRefresh: true),
  ]);
}
```

#### Method `deleteProgressSholat()`
```dart
// SEBELUM: Refresh semua progress (wajib & sunnah)
Future<bool> deleteProgressSholat({required int id}) async {
  await SholatService.deleteProgressSholat(id: id);
  
  // Refresh semua
  await fetchProgressSholatWajibHariIni(forceRefresh: true);
  await fetchProgressSholatWajibRiwayat(forceRefresh: true);
  await fetchProgressSholatSunnahHariIni(forceRefresh: true);
  await fetchProgressSholatSunnahRiwayat(forceRefresh: true);
}

// SESUDAH: Refresh hanya sesuai jenis dengan parallel execution
Future<bool> deleteProgressSholat({
  required int id,
  required String jenis,  // TAMBAH parameter jenis
}) async {
  await SholatService.deleteProgressSholat(id: id, jenis: jenis);
  
  // Refresh hanya yang relevan
  if (jenis.toLowerCase() == 'wajib') {
    await Future.wait([
      fetchProgressSholatWajibHariIni(forceRefresh: true),
      fetchProgressSholatWajibRiwayat(forceRefresh: true),
    ]);
  } else {
    await Future.wait([
      fetchProgressSholatSunnahHariIni(forceRefresh: true),
      fetchProgressSholatSunnahRiwayat(forceRefresh: true),
    ]);
  }
}
```

### 3. `sholat_page.dart`
**Perubahan:**
- ✅ Update pemanggilan `deleteProgressSholat()` untuk menyertakan parameter `jenis`
- ✅ Update modal input sholat wajib dengan form lengkap (status, berjamaah, lokasi, keterangan)
- ✅ Update modal input sholat sunnah dengan form sederhana (hanya sholat dan status)
- ✅ Menambahkan 3 pilihan status: Tepat Waktu, Terlambat, Tidak Sholat
- ✅ Menambahkan input keterangan untuk tracking detail (contoh: kesiangan, di perjalanan)

**Detail Perubahan:**

#### Modal Input Sholat Wajib
```dart
// Input fields untuk sholat wajib:
1. Status (required):
   - Tepat Waktu
   - Terlambat
   - Tidak Sholat

2. Berjamaah (required):
   - Ya (is_jamaah = 1)
   - Tidak (is_jamaah = 0)

3. Tempat (required):
   - Masjid
   - Rumah
   - Kantor
   - Lainnya

4. Keterangan (optional):
   - TextField untuk input bebas
   - Contoh: "Kesiangan", "Di perjalanan", dll
```

#### Modal Input Sholat Sunnah
```dart
// Input fields untuk sholat sunnah (lebih sederhana):
1. Status (required):
   - Tepat Waktu
   - Terlambat
   - Tidak Sholat

// Tidak ada input berjamaah, lokasi, dan keterangan
```

#### Update Pemanggilan API
```dart
// SEBELUM
await ref.read(sholatProvider.notifier)
    .addProgressSholat(
      jenis: jenis,
      sholat: 'shubuh',
      isOnTime: true,
      isJamaah: true,
      lokasi: 'Masjid',
    );

// SESUDAH
await ref.read(sholatProvider.notifier)
    .addProgressSholat(
      jenis: jenis,
      sholat: 'shubuh',
      status: 'tepat_waktu', // atau 'terlambat', 'tidak_sholat'
      isJamaah: berjamaah,   // hanya untuk wajib
      lokasi: tempat,         // hanya untuk wajib
      keterangan: keterangan, // hanya untuk wajib
    );
```

### 4. `sholat_header.dart`
**Perubahan:**
- ✅ Menambahkan badge "Waktu dari Kemenag RI" di header
- ✅ Badge ditampilkan dengan icon verified untuk kredibilitas

**Detail Perubahan:**
```dart
// Menambahkan info di bawah lokasi
Row(
  children: [
    Icon(Icons.verified_rounded, ...),
    Text('Waktu dari Kemenag RI', ...),
  ],
)
```

## Integrasi API Kemenag

### Cara Kerja
1. **Frontend** mengirim koordinat lokasi (latitude & longitude) ke backend
2. **Backend** meneruskan request ke API resmi Kementerian Agama RI
3. **API Kemenag** mengembalikan waktu sholat akurat berdasarkan lokasi
4. **Backend** memproses dan mengirim data ke frontend
5. **Frontend** menyimpan ke cache untuk akses offline
6. **Frontend** menampilkan badge verifikasi bahwa data dari Kemenag RI

### Endpoint Backend
```
GET /sholat/jadwal
Query Parameters:
- latitude: double (koordinat lintang)
- longitude: double (koordinat bujur)
- start_date: string (format: yyyy-MM-dd)
- end_date: string (format: yyyy-MM-dd)

Response:
{
  "status": "success",
  "message": "Jadwal sholat berhasil diambil",
  "data": [
    {
      "tanggal": "01-11-2025",
      "wajib": {
        "shubuh": "04:30",
        "dzuhur": "12:00",
        "ashar": "15:15",
        "maghrib": "18:00",
        "isya": "19:15"
      },
      "sunnah": [...]
    }
  ]
}
```

## Keuntungan Perubahan

### 1. Konsistensi Code
- ✅ Method yang sejenis digabungkan menjadi satu (DRY principle)
- ✅ Parameter lebih konsisten dan mudah dipahami
- ✅ Mengurangi code duplication

### 2. Performa Lebih Baik
- ✅ Menggunakan `Future.wait()` untuk parallel execution
- ✅ Hanya refresh data yang relevan (wajib/sunnah) saat delete
- ✅ Cache strategy yang optimal untuk offline access

### 3. Maintainability
- ✅ Lebih mudah untuk maintenance karena logic terpusat
- ✅ Dokumentasi yang jelas tentang integrasi API Kemenag
- ✅ Type safety dengan parameter required

### 4. Akurasi Data
- ✅ Waktu sholat dari API resmi Kemenag RI
- ✅ Akurat berdasarkan koordinat lokasi pengguna
- ✅ Update otomatis sesuai dengan data terbaru dari Kemenag
- ✅ Badge verifikasi untuk kredibilitas sumber data

### 5. User Experience
- ✅ Form input lebih detail untuk tracking yang akurat
- ✅ 3 pilihan status: Tepat Waktu, Terlambat, Tidak Sholat
- ✅ Input keterangan untuk catatan pribadi (contoh: kesiangan)
- ✅ Form berbeda untuk wajib dan sunnah sesuai kebutuhan
- ✅ UI yang lebih informatif dengan badge Kemenag RI

## Testing Checklist

Setelah update ini, pastikan untuk test:

### Fetch & Display
- [ ] Fetch jadwal sholat dengan lokasi baru
- [ ] Refresh jadwal sholat
- [ ] Display badge "Waktu dari Kemenag RI"
- [ ] Format tanggal sudah benar (yyyy-MM-dd)
- [ ] Offline mode (cache)

### Form Input Sholat Wajib
- [ ] Tampilkan modal dengan 4 section (Status, Berjamaah, Tempat, Keterangan)
- [ ] Pilih status: Tepat Waktu
- [ ] Pilih status: Terlambat
- [ ] Pilih status: Tidak Sholat
- [ ] Toggle berjamaah (Ya/Tidak)
- [ ] Pilih tempat: Masjid, Rumah, Kantor, Lainnya
- [ ] Input keterangan (contoh: "Kesiangan")
- [ ] Submit form dengan semua data terisi
- [ ] Validasi tempat wajib diisi

### Form Input Sholat Sunnah
- [ ] Tampilkan modal dengan 1 section (Status saja)
- [ ] Pilih status: Tepat Waktu
- [ ] Pilih status: Terlambat
- [ ] Pilih status: Tidak Sholat
- [ ] Submit form (tidak ada berjamaah, lokasi, keterangan)

### Delete Progress
- [ ] Hapus progress sholat wajib
- [ ] Hapus progress sholat sunnah
- [ ] Progress refresh hanya untuk jenis yang relevan
- [ ] Konfirmasi dialog muncul sebelum delete

### API Integration
- [ ] POST data wajib dengan semua field (sholat, status, is_jamaah, lokasi, keterangan)
- [ ] POST data sunnah dengan field minimal (sholat, status)
- [ ] DELETE dengan parameter jenis yang benar
- [ ] Response handling untuk success dan error

## Migration Guide

Jika ada code lain yang memanggil method-method ini, update seperti berikut:

### Menambah Progress Sholat Wajib
```dart
// SEBELUM
await SholatService.addProgressSholatWajib(
  sholat: 'shubuh',
  status: 'tepat_waktu',
  isJamaah: true,
  lokasi: 'Masjid',
  keterangan: '',
);

// SESUDAH
await SholatService.addProgressSholat(
  jenis: 'wajib',
  sholat: 'shubuh',
  status: 'tepat_waktu', // atau 'terlambat', 'tidak_sholat'
  isJamaah: true,        // nullable untuk wajib
  lokasi: 'Masjid',      // nullable untuk wajib
  keterangan: 'Kesiangan', // nullable, optional
);
```

### Menambah Progress Sholat Sunnah
```dart
// SESUDAH (Sunnah lebih sederhana)
await SholatService.addProgressSholat(
  jenis: 'sunnah',
  sholat: 'dhuha',
  status: 'tepat_waktu', // atau 'terlambat', 'tidak_sholat'
  // Tidak perlu isJamaah, lokasi, keterangan
);
```

### Menghapus Progress
```dart
// SEBELUM
await SholatService.deleteProgressSholatWajib(id: 123);

// SESUDAH
await SholatService.deleteProgressSholat(id: 123, jenis: 'wajib');
```

## Catatan Backend

Backend harus mengimplementasikan integrasi dengan API Kemenag dan update endpoint progress:

### 1. Jadwal Sholat (GET)
- **Endpoint:** `GET /sholat/jadwal`
- **API Kemenag:** https://api.kemenag.go.id atau endpoint resmi lainnya
- **Format Response:** Sesuai dengan model `Sholat` di frontend
- **Error Handling:** Handle ketika API Kemenag down atau timeout
- **Caching:** Backend sebaiknya juga implement caching untuk mengurangi hit ke API Kemenag

### 2. Progress Sholat Wajib (POST)
- **Endpoint:** `POST /sholat/wajib/progres`
- **Request Body:**
  ```json
  {
    "sholat": "shubuh",
    "status": "tepat_waktu", // atau "terlambat", "tidak_sholat"
    "is_jamaah": 1, // 1 atau 0
    "lokasi": "Masjid",
    "keterangan": "Kesiangan"
  }
  ```

### 3. Progress Sholat Sunnah (POST)
- **Endpoint:** `POST /sholat/sunnah/progres`
- **Request Body:**
  ```json
  {
    "sholat": "dhuha",
    "status": "tepat_waktu" // atau "terlambat", "tidak_sholat"
  }
  ```

### 4. Database Schema Update
Pastikan tabel progress sholat mendukung:
- `status` enum: 'tepat_waktu', 'terlambat', 'tidak_sholat'
- `is_jamaah` tinyint: 1 atau 0
- `lokasi` varchar: Masjid, Rumah, Kantor, Lainnya
- `keterangan` text: untuk catatan detail

## Link Referensi

- API Kemenag: https://api.kemenag.go.id (sesuaikan dengan endpoint resmi)
- Dokumentasi Flutter Dio: https://pub.dev/packages/dio
- State Management Riverpod: https://riverpod.dev

---

**Update Date:** 1 November 2025
**Version:** 2.0.0
**Status:** ✅ Ready for Testing
