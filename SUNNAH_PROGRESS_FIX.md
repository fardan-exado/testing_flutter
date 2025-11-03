# Fix: Sholat Sunnah Progress Masih Tercheklist Setelah Dihapus

## Masalah

Ketika progress sholat sunnah dihapus dari database, UI masih menampilkan checkmark (tercheklist) meskipun data sudah tidak ada di database.

## Penyebab

Bug terjadi pada file `sholat_page.dart` di fungsi getter `_currentProgressData`, tepatnya di bagian parsing progress sunnah hari ini (line 1055-1070).

### Kode Bermasalah (Sebelum)

```dart
// Try to get id from various possible field names
// IMPORTANT: Check item['id'] first (progress record ID), NOT sholatSunnah['id'] (sunnah type ID)
final progressId =
    sholatSunnah['id'] ?? item['progress_id'] ?? item['progres_id'];

// Try to get status from various possible field names
final progressStatus =
    sholatSunnah['status'] as String? ??
    item['progress_status'] as String? ??
    '';
```

**Masalahnya:**

- Kode mengambil `sholatSunnah['id']` sebagai prioritas pertama untuk `progressId`
- `sholatSunnah['id']` adalah **ID jenis sholat sunnah** (misal: 1 untuk Tahajud, 2 untuk Witir, dst)
- Yang seharusnya diambil adalah `item['id']` yang merupakan **ID record progress** (misal: 123 untuk entry progress tertentu)

**Dampak:**
Ketika progress dihapus:

1. Database berhasil menghapus record dengan ID progress (misal: 123)
2. Data di-refresh dari database (sudah benar - data kosong)
3. Tapi UI masih menyimpan referensi ke ID jenis sholat (misal: 1) bukan ID progress
4. UI berpikir masih ada progress karena ID yang tersimpan tidak cocok dengan yang dihapus

## Solusi

### Kode yang Diperbaiki (Sesudah)

```dart
// FIX: Get progress record ID from item['id'], NOT sholatSunnah['id']
// sholatSunnah['id'] is the sunnah TYPE ID (e.g., 1 for Tahajud)
// item['id'] is the progress RECORD ID (e.g., 123 for the actual progress entry)
final progressId = item['id'] as int?;

// Try to get status from various possible field names
final progressStatus =
    item['status'] as String? ??
    '';
```

**Perbaikan:**

- Langsung mengambil `item['id']` sebagai `progressId`
- `item['id']` adalah ID record progress yang benar
- Status juga diambil langsung dari `item['status']` tanpa fallback yang tidak perlu

## Testing

Setelah fix ini diterapkan, pastikan untuk test:

1. **Test Normal Flow:**

   - Tambah progress sholat sunnah → harus muncul checkmark ✓
   - Hapus progress sholat sunnah → checkmark harus hilang ✓

2. **Test Multiple Sunnah:**

   - Tambah beberapa sholat sunnah (misal: Tahajud, Dhuha, Witir)
   - Hapus salah satu (misal: Dhuha)
   - Pastikan hanya Dhuha yang hilang checkmark-nya
   - Tahajud dan Witir tetap ada checkmark

3. **Test Refresh:**
   - Tambah progress sholat sunnah
   - Pull-to-refresh halaman
   - Checkmark tetap ada ✓
   - Hapus progress
   - Pull-to-refresh lagi
   - Checkmark harus hilang ✓

## File yang Diubah

- `lib/features/sholat/pages/sholat_page.dart` (line ~1055-1070)

## Catatan Tambahan

- Bug ini **HANYA** terjadi pada sholat sunnah hari ini
- Sholat sunnah riwayat (history) sudah benar karena menggunakan `item['id']` dengan benar
- Sholat wajib tidak terpengaruh karena struktur data berbeda

## Commit Message

```
fix: sholat sunnah progress tidak hilang setelah dihapus

- Perbaiki pengambilan ID progress sunnah di _currentProgressData
- Menggunakan item['id'] (progress record ID) bukan sholatSunnah['id'] (sunnah type ID)
- Progress sunnah sekarang hilang dengan benar setelah dihapus dari database
```
