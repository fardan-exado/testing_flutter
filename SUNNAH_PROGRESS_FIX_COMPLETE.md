# Fix: Sholat Sunnah Progress - Multiple Bugs Fixed

## Masalah

Ketika progress sholat sunnah dihapus dari database, UI masih menampilkan checkmark (tercheklist) meskipun data sudah tidak ada di database.

## Root Cause - Multiple Bugs

### Bug 1: Wrong ID Source (Sunnah Hari Ini)

**Location:** `_currentProgressData` getter, line ~1065-1080

**Kode Bermasalah:**

```dart
final progressId = sholatSunnah['id'] ?? item['progress_id'] ?? item['progres_id'];
final progressStatus = sholatSunnah['status'] as String? ?? item['progress_status'] as String? ?? '';
```

**Masalah:**

- Mengambil `sholatSunnah['id']` yang adalah **ID jenis sholat sunnah** (1=Tahajud, 2=Witir, dst)
- Seharusnya ambil `item['id']` yang adalah **ID record progress** (123, 124, dst)
- `sholatSunnah` object tidak punya field `status` - status ada di level `item`

### Bug 2: Wrong String Replace (Multiple Locations)

**Locations:** Line ~1069, ~1270, ~2238

**Kode Bermasalah:**

```dart
final dbKey = slug.replaceAll('-', '-'); // BUG: Replace dash dengan dash (tidak berubah!)
```

**Masalah:**

- Harusnya `replaceAll('-', '_')` untuk convert slug ke dbKey format
- Contoh: `'tahajud'` ✓, `'qabliyah-subuh'` → `'qabliyah_subuh'`
- Dengan bug ini: `'qabliyah-subuh'` tetap `'qabliyah-subuh'` (salah!)

### Bug 3: Wrong Data Structure (Sunnah Riwayat)

**Location:** `_currentProgressData` getter, line ~1255-1295

**Kode Bermasalah:**

```dart
for (var item in riwayatData) {
  final sholatSunnah = item['sholat_sunnah'] as Map<String, dynamic>?;

  if (sholatSunnah != null) {
    // Code untuk handle nested sholat_sunnah (SALAH - tidak ada nested)
  } else {
    // Handle format langsung (INI YANG BENAR)
  }
}
```

**Masalah:**

- Response API riwayat **TIDAK** punya nested object `sholat_sunnah`
- Riwayat langsung berisi array dengan field `sholat_sunnah_id` (integer)
- Code mencoba handle format nested yang tidak pernah ada

## Format Response API

### Response Sunnah Hari Ini

```json
{
  "status": true,
  "message": "List progres sholat sunnah hari ini",
  "data": [
    {
      "sholat_sunnah": {
        // <- Nested object (ADA di hari ini)
        "id": 1, // <- Sunnah type ID
        "slug": "tahajud",
        "nama": "Tahajud",
        "deskripsi": "..."
      },
      "id": 123, // <- Progress record ID (root level)
      "progres": true, // <- Boolean flag
      "status": "tepat_waktu" // <- Status (root level)
    }
  ]
}
```

### Response Sunnah Riwayat (STRUKTUR BERBEDA!)

```json
{
  "status": true,
  "message": "Riwayat progres sholat sunnah",
  "data": {
    "2025-11-03": [
      {
        "id": 8, // <- Progress record ID
        "user_id": 8,
        "sholat_sunnah_id": 1, // <- Sunnah type ID (integer, bukan object!)
        "status": "tidak_sholat",
        "tanggal": "2025-11-03",
        "created_at": "...",
        "updated_at": "..."
      }
    ]
  }
}
```

**Perbedaan Kunci:**

- **Hari Ini**: Punya nested object `sholat_sunnah` dengan `id`, `slug`, `nama`, dll
- **Riwayat**: Hanya field integer `sholat_sunnah_id`, **TIDAK** ada nested object

## Solutions Applied

### Fix 1: Correct ID & Status Source (Sunnah Hari Ini)

```dart
if (sholatSunnah != null) {
  final slug = sholatSunnah['slug'] as String;
  final dbKey = slug.replaceAll('-', '_'); // FIX: _ bukan -

  // FIX: Ambil dari item (root level), bukan sholatSunnah (nested)
  final progressId = item['id'] as int?;
  final progressStatus = item['status'] as String? ?? '';

  formattedProgress[dbKey] = {
    'id': progressId,           // Correct progress record ID
    'completed': progres,
    'status': progressStatus,   // Correct status from item
  };
}
```

**Perbaikan:**

- ✅ Ambil `id` dari `item['id']` (progress record ID)
- ✅ Ambil `status` dari `item['status']` (bukan dari nested sholatSunnah)
- ✅ Fix `replaceAll('-', '_')` untuk convert slug ke dbKey

### Fix 2: Correct Data Parsing (Sunnah Riwayat)

```dart
// Riwayat: langsung array tanpa nested sholat_sunnah
if (riwayatData is List) {
  for (var item in riwayatData) {
    final sholatSunnahId = item['sholat_sunnah_id'] as int?; // Integer, bukan nested object

    if (sholatSunnahId != null) {
      // Cari info sholat dari jadwal berdasarkan ID
      final jadwal = ref.read(sholatProvider.notifier).getJadwalByDate(_selectedDate);
      final sunnahList = jadwal?.sunnah ?? [];

      final sunnahItem = sunnahList.firstWhere(
        (s) => s.id == sholatSunnahId,
        orElse: () => SholatSunnah(id: 0, nama: '', slug: '', deskripsi: ''),
      );

      if (sunnahItem.id != 0) {
        final dbKey = sunnahItem.slug.replaceAll('-', '_');

        formattedProgress[dbKey] = {
          'id': item['id'],                     // Progress record ID
          'sholat_sunnah_id': sholatSunnahId,   // Sunnah type ID
          'completed': true,
          'status': item['status'] as String? ?? 'tepat_waktu',
        };
      }
    }
  }
}
```

**Perbaikan:**

- ✅ Langsung ambil `sholat_sunnah_id` (integer) dari item
- ✅ Tidak lagi cari nested object `sholat_sunnah` yang tidak ada
- ✅ Lookup info sholat dari jadwal berdasarkan ID
- ✅ Fix `replaceAll('-', '_')` untuk convert slug

### Fix 3: Correct dbKey in UI Builder

```dart
// In _buildSunnahTab
final dbKey = slug.replaceAll('-', '_'); // FIX: _ bukan -
```

## Testing Checklist

### 1. Test Sunnah Hari Ini

- [ ] Tambah progress Tahajud → checkmark muncul
- [ ] Hapus progress Tahajud → checkmark hilang
- [ ] Tambah Dhuha → checkmark muncul
- [ ] Tambah Qabliyah Subuh (ada dash) → checkmark muncul
- [ ] Hapus Qabliyah Subuh → checkmark hilang (test bug #2)

### 2. Test Sunnah Riwayat

- [ ] Buka tanggal kemarin yang ada progress
- [ ] Progress ditampilkan dengan benar
- [ ] Detail progress bisa dibuka (test ID benar)
- [ ] Navigate ke hari yang berbeda → progress berubah sesuai tanggal

### 3. Test Multiple Sunnah

- [ ] Tambah 3 sholat sunnah berbeda
- [ ] Hapus yang tengah → hanya tengah yang hilang
- [ ] Yang lain tetap ada checkmark

### 4. Test Refresh

- [ ] Pull-to-refresh setelah add → checkmark tetap ada
- [ ] Pull-to-refresh setelah delete → checkmark tetap hilang

## Files Changed

- `lib/features/sholat/pages/sholat_page.dart`
  - Line ~1069: Fix replaceAll dan ID source (Sunnah Hari Ini)
  - Line ~1255-1295: Fix parsing structure (Sunnah Riwayat)
  - Line ~2238: Fix replaceAll (\_buildSunnahTab)

## Impact Analysis

### Before Fix

❌ Progress ID salah (type ID, bukan record ID)
❌ Status tidak bisa diambil (field tidak ada di nested object)
❌ dbKey format salah untuk slug dengan dash (qabliyah-subuh)
❌ Riwayat parsing error karena struktur data berbeda

### After Fix

✅ Progress ID benar (record ID dari database)
✅ Status diambil dari tempat yang benar
✅ dbKey format benar (qabliyah_subuh)
✅ Riwayat parsing sesuai struktur response API

## Commit Message

```
fix: sholat sunnah progress - multiple bugs fixed

- Fix ID source: use item['id'] (progress record) not sholatSunnah['id'] (type ID)
- Fix status source: use item['status'] not sholatSunnah['status'] (doesn't exist)
- Fix slug conversion: replaceAll('-', '_') not replaceAll('-', '-')
- Fix riwayat parsing: handle direct array format without nested sholat_sunnah
- Progress sunnah now correctly removed after deletion from database

Fixes #[issue-number]
```
