# Monitoring Page - Report Format Update

## Overview
Halaman monitoring telah diubah dari format grafik ke format laporan tabel yang detail, sesuai dengan permintaan format laporan harian/mingguan/bulanan dengan filter dan custom date range.

## Perubahan Utama

### 1. **Filter System**
Ditambahkan 4 jenis filter:
- ✅ **Daily** - Laporan harian
- ✅ **Weekly** - Laporan mingguan  
- ✅ **Monthly** - Laporan bulanan
- ✅ **Custom** - Pilih tanggal mulai dan akhir sendiri

### 2. **User Info Header**
```
User: [Nama Anak / Semua Anak]
Lokasi: Tangerang, [Tanggal]
```

### 3. **Format Laporan Tabel**

#### A. Laporan Sholat Wajib
| Tgl | Waktu Sholat | Jenis Sholat | Tepat waktu | Dilakukan | Tempat | Keterangan |
|-----|--------------|--------------|-------------|-----------|--------|------------|
| Data sample termasuk: Fajr, Duhr, Asr, Maghrib, Isha |

**Hasil**: Good 75%
**Saran**: 
- Tingkatkan lagi Sholatnya
- Berhenti cari masjid terdekat saat pulang kantor

#### B. Laporan Sholat Sunnah
| Tgl | Waktu Sholat | Jenis Sholat | Rakaat | Dilakukan | Tempat | Keterangan |
|-----|--------------|--------------|--------|-----------|--------|------------|
| Data sample: Tahajud (8 rakaat), Duha (4 rakaat) |

**Hasil**: Excellent 100%
**Saran**: Tingkatkan lagi Sholatnya

#### C. Laporan Baca Al Quran
| Tgl | Waktu Baca | Halaman | Surat Favorit | Dilakukan | Tempat | Keterangan |
|-----|------------|---------|---------------|-----------|--------|------------|

**Hasil**: Excellent 100%
**Saran**: Alhamdulillah

#### D. Laporan Tahajud Challenge
| Tgl | Waktu Sholat | Rakaat | Makan terakhir | Tidur | Keterangan |
|-----|--------------|--------|----------------|-------|------------|

**Hasil**: Good 80%
**Saran**: Tidur lebih awal maksimal jam 22.00 PM

#### E. Laporan Puasa
| Tgl | Jenis Puasa | Keterangan |
|-----|-------------|------------|
| Data sample: Puasa Ramadhan, Puasa Senin Kamis |

**Hasil**: Excellent
**Saran**: Tingkatkan lagi Puasa

#### F. Laporan Zakat dan Sedekah
| Tgl | Jenis Sedekah | Nilai |
|-----|---------------|-------|
| Data sample: Sedekah Subuh (Rp 50.000), Infaq Masjid (Rp 20.000) |

**Jumlah**: Rp 70.000

**Hasil**: Excellent
**Saran**: Terus tingkatkan sedekah

### 4. **Tab Structure**

#### Tab 1: Dashboard (Laporan)
- User info header
- Filter section
- 6 tipe laporan dengan tabel lengkap
- Hasil dan saran untuk setiap laporan

#### Tab 2: Anak-anak
- List semua anak
- Klik untuk memilih anak dan lihat laporannya
- Menampilkan nama, usia, dan avatar

#### Tab 3: Notifikasi
- Notifikasi aktivitas anak
- Tipe: missed_prayer, achievement, quran_target
- Tandai semua sebagai dibaca
- Badge untuk notifikasi belum dibaca

## Fitur Yang Dihilangkan

❌ **Grafik mingguan** - Diganti dengan tabel detail
❌ **Achievement cards** - Diganti dengan hasil & saran per laporan
❌ **Child summary cards dengan progress bars** - Diganti dengan tabel aktivitas detail
❌ **FAB button untuk reward** - Akan diimplementasikan di tempat lain

## Data Structure

### Sample Data yang Ditambahkan:

```dart
// Filter state
String selectedFilter = 'Daily';
DateTime? customStartDate;
DateTime? customEndDate;
String? selectedChildId; // null = semua anak

// Report data arrays
List<Map<String, dynamic>> sholatWajibReports;
List<Map<String, dynamic>> sholatSunnahReports;
List<Map<String, dynamic>> quranReports;
List<Map<String, dynamic>> tahajudReports;
List<Map<String, dynamic>> puasaReports;
List<Map<String, dynamic>> zakatReports;
```

## Methods Baru

### 1. `_buildUserInfoHeader(bool isTablet)`
Menampilkan informasi user dan lokasi

### 2. `_buildFilterSection(bool isTablet)`
Section untuk memilih filter Daily/Weekly/Monthly/Custom

### 3. `_buildFilterChip(String label, bool isTablet)`
Chip button untuk filter yang bisa diklik

### 4. `_buildDateButton(...)`
Button untuk memilih tanggal custom

### 5. `_selectDate(bool isStartDate)`
Show date picker untuk custom date range

### 6. `_formatDate(DateTime date)`
Format tanggal ke DD/MM/YYYY

### 7. `_buildReportSection(...)`
Container utama untuk setiap laporan (judul + tabel + hasil & saran)

### 8. `_buildDataTable(...)`
DataTable widget dengan columns dan rows dinamis

### 9. `_getColumnsForType(String type, ...)`
Return DataColumn list sesuai tipe laporan

### 10. `_buildDataRow(...)`
Return DataRow dengan DataCell sesuai tipe laporan

### 11. Helper Methods:
- `_getIconForType()` - Icon untuk setiap tipe laporan
- `_getResultColor()` - Warna untuk hasil (green, orange, etc)
- `_getResult()` - Text hasil (Good 75%, Excellent 100%, etc)
- `_getSuggestions()` - List saran untuk setiap tipe

### 12. Simplified Tab Methods:
- `_buildChildrenTab()` - List anak dengan tombol pilih
- `_buildNotificationsTab()` - List notifikasi dengan status read/unread

## Responsive Design

### Mobile (<600px)
- Tabel bisa di-scroll horizontal
- Padding 24px
- Font size lebih kecil
- Filter chips scrollable

### Tablet (600-1024px)
- Padding 28px
- Font size sedang
- Layout lebih luas
- Fixed filter chips

### Desktop (>1024px)
- Padding 32px
- Font size lebih besar
- Maximum width untuk readability

## Color Scheme

### Report Types:
- **Sholat Wajib**: Green (Good 75%)
- **Sholat Sunnah**: Accent Green (Excellent 100%)
- **Quran**: Accent Green (Excellent 100%)
- **Tahajud**: Orange (Good 80%)
- **Puasa**: Accent Green (Excellent)
- **Zakat**: Accent Green (Excellent)

### UI Elements:
- **Selected Filter**: Primary Blue background, white text
- **Unselected Filter**: Light blue background, dark text
- **Table Header**: Light blue background
- **Result Section**: Color-coded based on report type

## Integration Points

### TODO: Backend Integration
```dart
// Filter berdasarkan selectedFilter
if (selectedFilter == 'Daily') {
  // Fetch today's data
} else if (selectedFilter == 'Weekly') {
  // Fetch this week's data
} else if (selectedFilter == 'Monthly') {
  // Fetch this month's data
} else if (selectedFilter == 'Custom') {
  // Fetch data between customStartDate and customEndDate
}

// Filter berdasarkan selectedChildId
if (selectedChildId != null) {
  // Fetch data for specific child
} else {
  // Fetch data for all children
}
```

### API Endpoints Needed:
1. `GET /api/reports/sholat-wajib?filter={daily|weekly|monthly}&child_id={id}&start_date={date}&end_date={date}`
2. `GET /api/reports/sholat-sunnah?...`
3. `GET /api/reports/quran?...`
4. `GET /api/reports/tahajud?...`
5. `GET /api/reports/puasa?...`
6. `GET /api/reports/zakat?...`

## Testing Checklist

### Filters:
- [ ] Daily filter menampilkan data hari ini
- [ ] Weekly filter menampilkan data minggu ini
- [ ] Monthly filter menampilkan data bulan ini
- [ ] Custom filter bisa pilih tanggal mulai dan akhir
- [ ] Date picker berfungsi dengan benar

### Reports:
- [ ] Semua 6 tipe laporan ditampilkan
- [ ] Tabel bisa di-scroll horizontal di mobile
- [ ] Data ditampilkan sesuai format
- [ ] Hasil dan saran sesuai dengan tipe laporan

### Child Selection:
- [ ] Bisa pilih "Semua Anak" atau anak spesifik
- [ ] User info header update saat ganti anak
- [ ] Data laporan berubah sesuai anak yang dipilih

### Responsive:
- [ ] Layout baik di mobile, tablet, desktop
- [ ] Font size sesuai dengan screen size
- [ ] Padding dan spacing konsisten

### Notifications:
- [ ] Notifikasi ditampilkan dengan benar
- [ ] Badge untuk unread notifications
- [ ] Tandai semua sebagai dibaca berfungsi

## Files Modified
- `lib/features/monitoring/pages/monitoring_page.dart`

## Dependencies
- `flutter/material.dart` - DataTable widget
- Existing providers (auth, connection)
- Existing theme and utilities

---

**Status**: ✅ Complete
**Date**: 2025-01-04
**Format**: Table-based Reports with Filters
**Features**: Daily/Weekly/Monthly/Custom filters, 6 report types, Results & Suggestions
