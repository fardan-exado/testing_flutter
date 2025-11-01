# Update Progress Sholat - Response API Structure

## 📋 Ringkasan Update

Update struktur response API untuk progress sholat wajib dan sunnah hari ini agar sesuai dengan backend terbaru.

## 🔄 Perubahan Response API

### 1. Progress Sholat Wajib Hari Ini

#### Response Structure Baru:
```json
{
    "status": true,
    "message": "Progres sholat wajib hari ini",
    "data": {
        "total": 2,
        "statistik": {
            "shubuh": true,
            "dzuhur": true,
            "ashar": false,
            "maghrib": false,
            "isya": false
        },
        "detail": [
            {
                "id": 3,
                "user_id": 8,
                "sholat_wajib_id": 1,  // 1=Shubuh, 2=Dzuhur, 3=Ashar, 4=Maghrib, 5=Isya
                "status": "tepat_waktu", // atau "terlambat", "tidak_sholat"
                "is_jamaah": 0,  // 0 atau 1
                "tanggal": "2025-11-01",
                "lokasi": "Masjid",
                "keterangan": "test",
                "created_at": "2025-11-01T16:19:34.000000Z",
                "updated_at": "2025-11-01T16:19:34.000000Z"
            }
        ]
    }
}
```

#### Key Changes:
- ✅ Menambah field `total` untuk jumlah sholat yang sudah dikerjakan
- ✅ Field `sholat_wajib_id` sebagai identifier (1-5)
- ✅ Field `status` dengan nilai: `tepat_waktu`, `terlambat`, `tidak_sholat`
- ✅ Field `keterangan` untuk catatan detail
- ✅ Struktur `statistik` tetap dengan boolean
- ✅ Struktur `detail` berisi array object lengkap

### 2. Progress Sholat Sunnah Hari Ini

#### Response Structure Baru:
```json
{
    "status": true,
    "message": "List progres sholat sunnah hari ini",
    "data": [
        {
            "sholat_sunnah": {
                "id": 1,
                "icon": null,
                "nama": "Tahajud",
                "slug": "tahajud",
                "deskripsi": "Sholat sunnah yang dilakukan pada sepertiga malam terakhir."
            },
            "progres": true  // boolean: true = sudah dikerjakan
        },
        {
            "sholat_sunnah": {
                "id": 2,
                "icon": null,
                "nama": "Witir",
                "slug": "witir",
                "deskripsi": "Sholat sunnah muakkad yang dilakukan setelah sholat Isya."
            },
            "progres": false
        }
    ]
}
```

#### Key Changes:
- ✅ Struktur berubah dari object ke array
- ✅ Setiap item berisi object `sholat_sunnah` dan field `progres`
- ✅ Field `progres` boolean (true/false) untuk status completion
- ✅ Tidak ada detail status seperti wajib (hanya boolean)

## 🔧 Perubahan Code

### File: `sholat_page.dart`

#### 1. Update Getter `_currentProgressData`

```dart
// SEBELUM: Struktur sama untuk wajib dan sunnah

// SESUDAH: Berbeda untuk wajib dan sunnah
Map<String, dynamic> get _currentProgressData {
  if (jenis == 'wajib') {
    // Struktur: { statistik: {...}, detail: [...] }
    // Map sholat_wajib_id ke key: 1=shubuh, 2=dzuhur, dst
    
    // Output format:
    // { 'shubuh': { id, completed, status, is_jamaah, lokasi, keterangan } }
  } else {
    // Struktur: Array [{ sholat_sunnah: {...}, progres: bool }]
    // Konversi slug ke dbKey (replace - dengan _)
    
    // Output format:
    // { 'tahajud': { completed: true, status: 'tepat_waktu' } }
  }
}
```

#### 2. Update Getter `_completedCount`

```dart
// WAJIB: Ambil dari field 'total'
if (jenis == 'wajib') {
  final total = progressToday['total'] as int? ?? 0;
  return total;
}

// SUNNAH: Hitung dari array yang progres = true
else {
  final progressToday = state.progressSunnahHariIni as List<dynamic>? ?? [];
  return progressToday.where((item) => item['progres'] == true).length;
}
```

#### 3. Update Getter `_totalCount`

```dart
// WAJIB: Fixed 5
if (_isWajibTab) return 5;

// SUNNAH: Hitung dari array length
else {
  final progressToday = state.progressSunnahHariIni as List<dynamic>? ?? [];
  return progressToday.length;
}
```

#### 4. Update Display Detail Progress

```dart
// Tambah display status
_buildInfoRow(
  'Status',
  _formatStatus(sholatProgress['status'] as String? ?? ''),
  Icons.info_outline,
),

// Field wajib only:
if (jenis == 'wajib') ...[
  _buildInfoRow('Berjamaah', ...),
  _buildInfoRow('Lokasi', ...),
  if (keterangan.isNotEmpty) _buildInfoRow('Keterangan', ...),
]
```

#### 5. Tambah Helper Method `_formatStatus`

```dart
String _formatStatus(String status) {
  switch (status) {
    case 'tepat_waktu': return 'Tepat Waktu';
    case 'terlambat': return 'Terlambat';
    case 'tidak_sholat': return 'Tidak Sholat';
    default: return status;
  }
}
```

#### 6. Update SholatCard Props

```dart
// WAJIB
isOnTime: (sholatProgress?['status'] as String? ?? 'tepat_waktu') == 'tepat_waktu',
isJamaah: sholatProgress?['is_jamaah'] as bool? ?? false,
lokasi: sholatProgress?['lokasi'] as String? ?? '',

// SUNNAH
isOnTime: (sholatProgress?['status'] as String? ?? 'tepat_waktu') == 'tepat_waktu',
isJamaah: false,  // sunnah tidak ada is_jamaah
lokasi: '',       // sunnah tidak ada lokasi
```

## 📊 Mapping Data

### Sholat Wajib ID Mapping
```dart
final Map<int, String> wajibIdToKey = {
  1: 'shubuh',
  2: 'dzuhur',
  3: 'ashar',
  4: 'maghrib',
  5: 'isya',
};
```

### Status Mapping
```dart
Status Values:
- 'tepat_waktu'  → Display: "Tepat Waktu"
- 'terlambat'    → Display: "Terlambat"
- 'tidak_sholat' → Display: "Tidak Sholat"
```

### Sholat Sunnah Slug to DB Key
```dart
// Konversi slug ke database key
slug.replaceAll('-', '_')

Examples:
- "tahajud" → "tahajud"
- "qabliyah-subuh" → "qabliyah_subuh"
- "badiyah-dzuhur" → "badiyah_dzuhur"
```

## ✅ Testing Checklist

### API Response Testing
- [ ] GET progress wajib hari ini return struktur: `{ total, statistik, detail }`
- [ ] Field `sholat_wajib_id` benar (1-5)
- [ ] Field `status` ada di detail wajib
- [ ] Field `keterangan` ada di detail wajib
- [ ] GET progress sunnah return array dengan struktur: `[{ sholat_sunnah, progres }]`
- [ ] Field `progres` boolean (true/false)

### UI Display Testing
- [ ] Completed count benar untuk wajib (dari field `total`)
- [ ] Completed count benar untuk sunnah (count array dengan progres=true)
- [ ] Total count dinamis untuk sunnah (sesuai array length)
- [ ] Status ditampilkan di modal detail
- [ ] Keterangan ditampilkan jika ada (wajib only)
- [ ] Sunnah tidak menampilkan berjamaah, lokasi, keterangan

### Data Mapping Testing
- [ ] Mapping `sholat_wajib_id` ke key benar (1=shubuh, dst)
- [ ] Mapping `status` ke display text benar
- [ ] Mapping slug sunnah ke dbKey benar (qabliyah-subuh → qabliyah_subuh)
- [ ] Statistik boolean mapping benar

## 🚀 Deployment Notes

### Backend Requirements
1. **Endpoint Progress Wajib** (`GET /sholat/progres/wajib/hari-ini`):
   - Return `{ total, statistik, detail }`
   - Field `sholat_wajib_id` (1-5)
   - Field `status`, `keterangan` di detail

2. **Endpoint Progress Sunnah** (`GET /sholat/progres/sunnah/hari-ini`):
   - Return array `[{ sholat_sunnah, progres }]`
   - Field `progres` boolean
   - Include all 12 sholat sunnah

### Frontend Updates
- ✅ Sudah disesuaikan dengan response structure baru
- ✅ Backward compatible untuk riwayat (tanggal lalu)
- ✅ No breaking changes untuk user experience

## 📝 Notes

1. **Field `total` vs Counting**:
   - Wajib: Gunakan field `total` dari API (lebih akurat)
   - Sunnah: Count manual dari array (tidak ada field total)

2. **Status Display**:
   - Wajib: Tampilkan status detail (tepat waktu/terlambat/tidak sholat)
   - Sunnah: Hanya boolean completion (sudah/belum)

3. **Detail Fields**:
   - Wajib: Full fields (status, berjamaah, lokasi, keterangan)
   - Sunnah: Minimal (hanya completion status)

---

**Version:** 2.2.0  
**Last Update:** 1 November 2025  
**Status:** ✅ Ready for Testing
