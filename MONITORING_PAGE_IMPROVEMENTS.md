# Monitoring Page Improvements - Update Summary

## Tanggal: 4 November 2025

### Perubahan yang Telah Dilakukan ✅

#### 1. **TabBar dengan Badge Notifikasi**
- ✅ Tab "Dashboard" diganti menjadi "Laporan"
- ✅ Menambahkan badge notifikasi di tab "Notifikasi" yang menampilkan jumlah notifikasi yang belum dibaca
- ✅ Badge merah dengan jumlah (max 99+)
- ✅ Styling sesuai dengan puasa_page

#### 2. **Report Type Selector**
- ✅ Menambahkan pemilihan jenis laporan dengan chip selector
- ✅ 6 jenis laporan:
  - Sholat Wajib
  - Sholat Sunnah
  - Al-Qur'an
  - Tahajud
  - Puasa
  - Zakat & Sedekah
- ✅ Hanya menampilkan 1 laporan sesuai pilihan (tidak semua sekaligus)
- ✅ Gradient background untuk item yang dipilih

#### 3. **Child Selector**
- ✅ Dropdown untuk memilih anak yang ingin dimonitor
- ✅ Default: anak pertama jika ada
- ✅ Widget "Belum Ada Data Anak" jika list kosong dengan tombol navigasi ke tab Anak-anak
- ✅ Styling dengan gradient dan icon avatar

#### 4. **Enhanced Table Styling**
- ✅ Alternating row colors (zebra striping)
- ✅ Hover effect pada rows
- ✅ Border horizontal antar rows
- ✅ Height yang lebih besar untuk keterbacaan
- ✅ Status chips dengan warna:
  - Hijau untuk "Ya" / success
  - Merah untuk "Tidak" / failed
  - Orange untuk "Terlambat"
- ✅ Bold text untuk kolom penting
- ✅ Italic text untuk keterangan
- ✅ Currency formatting dengan container hijau untuk nilai zakat

#### 5. **Enhanced Date Picker**
- ✅ Custom theme dengan primary color AppTheme.primaryBlue
- ✅ Rounded corners (20px)
- ✅ Button styling yang konsisten
- ✅ Elevation effect

#### 6. **Filter System**
- ✅ Daily, Weekly, Monthly, Custom options
- ✅ Custom date range picker dengan 2 tombol (Start Date, End Date)
- ✅ Styling yang konsisten dengan chip design

### Fitur Yang Perlu Dilanjutkan 🚧

#### 1. **Children Tab CRUD Operations**
Status: Belum diimplementasikan

Rencana implementasi:
```dart
// Tambah tombol floating action button
FloatingActionButton(
  child: Icon(Icons.add),
  onPressed: () => _showAddChildDialog(),
)

// Di setiap child card, tambahkan action buttons:
Row([
  IconButton(icon: Icons.edit, onPressed: _editChild),
  IconButton(icon: Icons.delete, onPressed: _deleteChild),
  IconButton(icon: Icons.arrow_forward, onPressed: _viewDetail),
])
```

Dialog yang perlu dibuat:
- `_showAddChildDialog()` - Form: Nama, Usia, Avatar (pilih dari icon)
- `_showEditChildDialog(child)` - Pre-fill dengan data existing
- `_showDeleteConfirmDialog(child)` - Konfirmasi hapus

#### 2. **Child Detail Page Enhancement**
File: `child_detail_page.dart`

Konten yang perlu ditampilkan berdasarkan data yang ada:
1. **Header Card** (sudah ada, lengkapi)
   - Foto/Avatar anak
   - Nama & Usia
   - Progress hari ini

2. **Tab 1: Summary** (sudah ada struktur, perlu data real)
   ```
   - Sholat Summary Card (5/5 hari ini, 140/150 bulan ini)
   - Quran Summary Card (2 halaman hari ini, 45/60 target)
   - Tahajud Summary Card (18/30 bulan ini, streak 7 hari)
   - Puasa Summary Card (15 hari bulan ini)
   - Zakat Summary Card (Rp 150,000 total)
   ```

3. **Tab 2: Activities** (sudah ada struktur)
   - Timeline aktivitas terakhir
   - Setiap aktivitas dengan icon, waktu, status

4. **Achievement Section** (tambahan)
   - Badge pencapaian
   - Milestone yang sudah dicapai

#### 3. **Backend Integration**
```dart
// Contoh struktur API call yang perlu dibuat:
Future<void> _fetchReportData() async {
  final childId = selectedChildId;
  final filter = selectedFilter;
  final reportType = selectedReportType;
  
  // Call API berdasarkan filter
  if (filter == 'Custom') {
    await fetchCustomReport(
      childId, 
      reportType, 
      customStartDate, 
      customEndDate
    );
  } else {
    await fetchReport(childId, reportType, filter);
  }
}
```

### Code Structure

```
monitoring_page.dart
├── State Variables
│   ├── selectedChildId (String?)
│   ├── selectedReportType (String)
│   ├── selectedFilter (String)
│   └── customStartDate/End (DateTime?)
│
├── Build Method
│   ├── TabBar (dengan badge)
│   └── TabBarView
│       ├── Laporan Tab
│       │   ├── _buildNoChildrenView() [if no children]
│       │   ├── _buildChildSelector()
│       │   ├── _buildReportTypeSelector()
│       │   ├── _buildFilterSection()
│       │   └── _buildCurrentReport()
│       │       └── _buildReportSection()
│       │           ├── Title Header
│       │           ├── _buildDataTable()
│       │           │   ├── Styled columns
│       │           │   └── _buildDataRow() [with zebra & chips]
│       │           └── Results & Suggestions
│       ├── Anak-anak Tab
│       │   └── List of children (needs CRUD buttons)
│       └── Notifikasi Tab
│           └── List with unread count
│
└── Helper Methods
    ├── _selectDate() [enhanced with custom theme]
    ├── _formatDate()
    ├── _getIconForType()
    ├── _getResultColor()
    ├── _getResult()
    ├── _getSuggestions()
    ├── _getColumnsForType()
    ├── _buildDataRow() [with index for zebra]
    └── _getTimeAgo()
```

### Next Steps (Priority Order)

1. **High Priority**
   - [ ] Implement CRUD operations di Children Tab
     - Add child dialog dengan form
     - Edit child dialog
     - Delete confirmation dialog
     - State management untuk children list

2. **Medium Priority**
   - [ ] Complete Child Detail Page
     - Populate Summary tab dengan data real
     - Improve Activities tab dengan better timeline
     - Add Achievement section

3. **Low Priority (Nice to Have)**
   - [ ] Add animation transitions
   - [ ] Export report to PDF feature
   - [ ] Share report feature
   - [ ] Push notification settings

### Testing Checklist

- [x] Tab navigation works
- [x] Badge shows correct unread count
- [x] Report type selector changes display
- [x] Child selector works with dropdown
- [x] No children view shows correctly
- [x] Filter chips work
- [x] Custom date picker opens and sets dates
- [x] Table displays with proper styling
- [x] Zebra striping renders correctly
- [x] Status chips show correct colors
- [ ] Add child dialog saves data
- [ ] Edit child updates correctly
- [ ] Delete child removes from list
- [ ] Child detail page opens with correct data

### Dependencies

No new dependencies needed. Current implementation uses:
- flutter/material.dart (core widgets)
- flutter_riverpod (state management)
- Existing AppTheme (colors and styles)

### Notes

- File sudah sangat panjang (2300+ lines)
- Consider refactoring ke multiple files untuk maintainability:
  ```
  monitoring/
    ├── pages/
    │   ├── monitoring_page.dart (main)
    │   ├── child_detail_page.dart
    │   └── child_form_page.dart (new)
    ├── widgets/
    │   ├── child_selector.dart
    │   ├── report_type_selector.dart
    │   ├── filter_section.dart
    │   └── styled_data_table.dart
    └── models/
        └── child_model.dart
  ```
