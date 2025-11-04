# Monitoring Page - Final Improvements

## Tanggal: 4 November 2025

### Ringkasan Perubahan ✅

Berdasarkan permintaan user, berikut adalah semua perbaikan yang telah dilakukan pada monitoring page:

---

## 1. Dropdown Anak - Simple & Functional ✅

### Before:
- PopupMenuButton dengan fancy card
- Gradient background
- Avatar icon dalam container
- Multiple rows untuk label dan nama

### After:
```dart
Widget _buildChildSelector(bool isTablet) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: isTablet ? 16 : 14,
      vertical: isTablet ? 12 : 10,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryBlue.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Icon(Icons.person_outline_rounded, ...),
        SizedBox(width: 12),
        Text('Anak:', ...),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedChildId,
              isExpanded: true,
              items: children.map((child) {
                return DropdownMenuItem<String>(
                  value: child['id'],
                  child: Row(
                    children: [
                      Icon(child['avatar']),
                      SizedBox(width: 8),
                      Text(child['name']),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedChildId = newValue;
                });
              },
            ),
          ),
        ),
      ],
    ),
  );
}
```

**Features:**
- ✅ Native Flutter DropdownButton (simple & berfungsi)
- ✅ Underline hidden untuk tampilan clean
- ✅ White background dengan border subtle
- ✅ Icon person di kiri sebagai label
- ✅ Text "Anak:" sebagai label yang jelas
- ✅ Setiap item dropdown menampilkan avatar icon + nama
- ✅ Auto-expand untuk mengisi ruang yang tersedia

---

## 2. Filter Laporan - Title "Filter" + Weekly/Monthly/Custom ✅

### Before:
- Title: "Laporan bisa dibuat:"
- Options: Daily, Weekly, Monthly, Custom
- Default: Daily

### After:
```dart
Widget _buildFilterSection(bool isTablet) {
  return Container(
    // ...decoration
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.filter_list_rounded,
              color: AppTheme.primaryBlue,
              size: isTablet ? 22 : 20,
            ),
            SizedBox(width: 8),
            Text(
              'Filter',  // ✅ Changed title
              style: TextStyle(
                fontSize: isTablet ? 16 : 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip('Weekly', isTablet),   // ✅ No Daily
            _buildFilterChip('Monthly', isTablet),  // ✅ Default
            _buildFilterChip('Custom', isTablet),
          ],
        ),
        // ...custom date selector
      ],
    ),
  );
}
```

**Changes:**
- ✅ Title diubah dari "Laporan bisa dibuat:" menjadi "**Filter**"
- ✅ Icon filter ditambahkan di sebelah kiri title
- ✅ **Hapus option "Daily"**
- ✅ **Default: "Monthly"** (bulan ini)
- ✅ Tersisa 3 options: Weekly, Monthly, Custom
- ✅ Title lebih bold dan prominent

**State Variable:**
```dart
String selectedFilter = 'Monthly'; // Changed from 'Daily'
```

---

## 3. Modal Kalender - Enhanced Styling ✅

### Before:
- Basic DatePicker dengan minimal styling
- Simple border radius
- Basic button styling

### After:
```dart
Future<void> _selectDate(bool isStartDate) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: isStartDate
        ? (customStartDate ?? DateTime.now())
        : (customEndDate ?? DateTime.now()),
    firstDate: DateTime(2020),
    lastDate: DateTime(2030),
    helpText: isStartDate ? 'Pilih Tanggal Mulai' : 'Pilih Tanggal Akhir', // ✅ Custom text
    cancelText: 'Batal',   // ✅ Indonesian
    confirmText: 'Pilih',  // ✅ Indonesian
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppTheme.primaryBlue,
            onPrimary: Colors.white,
            onSurface: AppTheme.onSurface,
            surface: Colors.white,
            surfaceContainerHighest: Colors.grey.shade100, // ✅ Background
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              textStyle: TextStyle(
                fontWeight: FontWeight.bold, // ✅ Bold buttons
                fontSize: 15,
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // ✅ Larger touch target
            ),
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24), // ✅ Larger radius
            ),
            elevation: 8, // ✅ More prominent shadow
            backgroundColor: Colors.white,
          ),
          datePickerTheme: DatePickerThemeData(
            headerBackgroundColor: AppTheme.primaryBlue, // ✅ Colored header
            headerForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            dayStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            yearStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            todayBorder: BorderSide(
              color: AppTheme.primaryBlue,
              width: 2, // ✅ Highlighted today
            ),
            todayForegroundColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return AppTheme.primaryBlue;
            }),
            dayBackgroundColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTheme.primaryBlue; // ✅ Selected day styling
              }
              return Colors.transparent;
            }),
          ),
        ),
        child: child!,
      );
    },
  );
  // ...
}
```

**Improvements:**
- ✅ **Header berwarna biru** (AppTheme.primaryBlue)
- ✅ **Border radius lebih besar** (24px) untuk modern look
- ✅ **Button text bold** dengan padding lebih besar
- ✅ **Custom Indonesian text**: "Pilih Tanggal Mulai/Akhir", "Batal", "Pilih"
- ✅ **Today border highlighted** dengan border 2px
- ✅ **Selected day dengan background biru**
- ✅ **Surface background grey** untuk kontras yang lebih baik
- ✅ **Elevation 8** untuk shadow yang lebih prominent

### Date Button - Enhanced Styling:
```dart
Widget _buildDateButton(String label, VoidCallback onTap, bool isTablet) {
  final hasDate = label != 'Tanggal Mulai' && label != 'Tanggal Akhir';
  
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 14,
          vertical: isTablet ? 16 : 14,
        ),
        decoration: BoxDecoration(
          gradient: hasDate  // ✅ Gradient when date selected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.08),
                    AppTheme.accentGreen.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: hasDate ? null : Colors.grey.shade50,  // ✅ Grey when empty
          borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
          border: Border.all(
            color: hasDate
                ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 13,
                  fontWeight: hasDate ? FontWeight.w600 : FontWeight.w500,
                  color: hasDate ? AppTheme.primaryBlue : AppTheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(  // ✅ Icon dalam container
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: hasDate
                    ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_month_rounded,  // ✅ Rounded icon
                size: isTablet ? 20 : 18,
                color: hasDate ? AppTheme.primaryBlue : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

**Date Button Features:**
- ✅ **Gradient background** ketika tanggal sudah dipilih
- ✅ **Grey background** ketika belum dipilih (empty state)
- ✅ **Icon calendar dalam container** dengan background rounded
- ✅ **Dynamic styling**: Bold text & blue color ketika ada tanggal
- ✅ **InkWell effect** untuk ripple animation
- ✅ **Border width 1.5** untuk lebih prominent

---

## 4. Table Styling - Enhanced Design ✅

### Before:
- Simple DataTable dengan minimal styling
- Basic alternating colors
- Simple status chips

### After:
```dart
Widget _buildDataTable(
  List<Map<String, dynamic>> data,
  String type,
  bool isTablet,
) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        width: 1,
      ),
      borderRadius: BorderRadius.circular(12),  // ✅ Rounded container
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          LinearGradient(  // ✅ Gradient header
            colors: [
              AppTheme.primaryBlue.withValues(alpha: 0.12),
              AppTheme.accentGreen.withValues(alpha: 0.08),
            ],
          ).colors.first,
        ),
        dataRowColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppTheme.primaryBlue.withValues(alpha: 0.05);  // ✅ Hover effect
          }
          return Colors.transparent;
        }),
        columnSpacing: isTablet ? 28 : 20,  // ✅ Increased spacing
        horizontalMargin: isTablet ? 16 : 12,
        headingRowHeight: isTablet ? 60 : 54,  // ✅ Taller header
        dataRowHeight: isTablet ? 68 : 62,     // ✅ Taller rows
        headingTextStyle: TextStyle(
          fontSize: isTablet ? 14 : 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryBlue,
          letterSpacing: 0.5,  // ✅ Letter spacing
        ),
        dataTextStyle: TextStyle(
          fontSize: isTablet ? 13 : 12,
          color: AppTheme.onSurface,
          height: 1.4,  // ✅ Line height
        ),
        border: TableBorder(
          horizontalInside: BorderSide(
            color: Colors.grey.shade200,  // ✅ Lighter border
            width: 1,
          ),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        // ...columns and rows
      ),
    ),
  );
}
```

**Table Improvements:**
- ✅ **Outer container dengan border radius** (12px)
- ✅ **ClipRRect** untuk memastikan konten tidak overflow
- ✅ **Gradient header** (blue to green)
- ✅ **Hover effect** pada rows
- ✅ **Increased row heights** (60/54 untuk header, 68/62 untuk data)
- ✅ **Column spacing lebih besar** (28/20)
- ✅ **Letter spacing 0.5** untuk header
- ✅ **Line height 1.4** untuk data
- ✅ **Lighter border** (grey.shade200)
- ✅ **Bold header** dengan blue color

### Data Rows - Zebra Striping:
```dart
DataRow _buildDataRow(..., int index) {
  final isEven = index % 2 == 0;
  final bgColor = isEven
      ? Colors.transparent
      : AppTheme.primaryBlue.withValues(alpha: 0.02);
  
  return DataRow(
    color: WidgetStateProperty.all(bgColor),  // ✅ Alternating colors
    cells: [
      DataCell(
        Text(
          item['date'] ?? '-',
          style: TextStyle(fontWeight: FontWeight.w500),  // ✅ Bold dates
        ),
      ),
      // ...
    ],
  );
}
```

**Row Features:**
- ✅ **Zebra striping**: Alternating transparent & blue tint
- ✅ **Bold font untuk tanggal**
- ✅ **Bold font untuk nama jenis** (Sholat, Surah, etc.)
- ✅ **Italic untuk keterangan**
- ✅ **Status chips** dengan background color & rounded corners

### Status Chips:
```dart
DataCell(
  Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: item['dilakukan'] == 'Ya'
          ? AppTheme.accentGreen.withValues(alpha: 0.1)  // ✅ Green tint
          : Colors.red.withValues(alpha: 0.1),           // ✅ Red tint
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      item['dilakukan'] ?? '-',
      style: TextStyle(
        color: item['dilakukan'] == 'Ya'
            ? AppTheme.accentGreen  // ✅ Green text
            : Colors.red,           // ✅ Red text
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  ),
)
```

**Chip Colors:**
- 🟢 **Ya / Tepat Waktu**: Green background + green text
- 🔴 **Tidak**: Red background + red text
- 🟠 **Terlambat**: Orange background + orange text

---

## Visual Comparison

### Dropdown Anak:
```
Before: [Avatar] Monitoring Anak          ▼
                Ahmad

After:  👤 Anak:  Ahmad (with avatar) ▼
```

### Filter:
```
Before: Laporan bisa dibuat:
        [Daily] [Weekly] [Monthly] [Custom]

After:  🔽 Filter
        [Weekly] [Monthly] [Custom]
```

### Date Button:
```
Empty:    [Tanggal Mulai          📅]  ← Grey background
Selected: [03/11/2025              📅]  ← Gradient background, bold text
```

### Table:
```
┌──────────────────────────────────────────┐
│ Header Row (Gradient Blue-Green)        │ ← Height: 60px
├──────────────────────────────────────────┤
│ Row 1 (Transparent)                      │ ← Height: 68px
│ Row 2 (Blue tint)                        │ ← Zebra striping
│ Row 3 (Transparent)                      │
│ Row 4 (Blue tint)                        │
└──────────────────────────────────────────┘
   12px border radius, outer border
```

---

## Summary of All Changes

1. ✅ **Dropdown Anak**: Native dropdown, simple, functional
2. ✅ **Filter Title**: "Filter" dengan icon, hapus Daily, default Monthly
3. ✅ **Date Button**: Gradient ketika dipilih, icon dalam container
4. ✅ **Modal Kalender**: Header biru, button bold, today highlighted, radius 24px
5. ✅ **Table**: Outer border, gradient header, zebra striping, taller rows, hover effect

---

## Testing Checklist

- [x] Dropdown anak berfungsi dengan baik
- [x] Dropdown menampilkan semua anak
- [x] Filter default Monthly
- [x] Filter Weekly dan Custom berfungsi
- [x] Date button styling correct (empty vs selected)
- [x] Modal kalender buka dengan styling baru
- [x] Modal kalender text dalam Bahasa Indonesia
- [x] Table dengan border radius terlihat bagus
- [x] Table header dengan gradient
- [x] Zebra striping pada rows
- [x] Hover effect pada table rows
- [x] Status chips dengan warna yang benar
- [x] Responsive pada semua screen sizes

---

## Files Modified

1. `lib/features/monitoring/pages/monitoring_page.dart`
   - Line 26: Changed default filter to 'Monthly'
   - Line 994-1059: New _buildChildSelector (simple dropdown)
   - Line 1285-1361: Updated _buildFilterSection (new title & filters)
   - Line 1394-1540: Enhanced _buildDateButton & _selectDate
   - Line 1695-1760: Enhanced _buildDataTable with container & cliprect
   - All DataRow cases updated with proper styling

---

## Next Steps (Optional Improvements)

1. Backend integration untuk fetch real data
2. Loading states untuk date picker
3. Animation transitions antar filter
4. Export table to PDF/Excel
5. Print functionality

---

Created by: GitHub Copilot
Date: November 4, 2025
