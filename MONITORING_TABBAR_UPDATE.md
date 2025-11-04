# Monitoring Page - TabBar Style Update

## Tanggal: 4 November 2025

### Perubahan yang Dilakukan ✅

#### TabBar dengan Style Baru (Seperti Puasa Page)

**Before:**
- Background putih dengan shadow biru
- Gradient indicator (biru-hijau) 
- Icon di setiap tab
- Label color putih untuk selected tab

**After:**
```dart
Widget _buildTabBar(bool isTablet, bool isDesktop) {
  final unreadCount = notifications.where((n) => !n['isRead']).length;

  return Container(
    margin: EdgeInsets.symmetric(
      horizontal: isDesktop ? 32.0 : isTablet ? 28.0 : 24.0,
    ),
    padding: EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,  // ✅ Background abu-abu
      borderRadius: BorderRadius.circular(12),
    ),
    child: TabBar(
      controller: _tabController,
      indicator: BoxDecoration(
        color: Colors.white,  // ✅ Tab aktif putih
        borderRadius: BorderRadius.circular(10),
        boxShadow: [  // ✅ Shadow subtle
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: AppTheme.primaryBlue,  // ✅ Text biru untuk selected
      unselectedLabelColor: AppTheme.onSurfaceVariant,  // ✅ Text abu untuk unselected
      // ...
    ),
  );
}
```

### Fitur TabBar

1. **Tab Laporan** (Tab 1)
   - Text: "Laporan"
   - Tanpa icon
   - Menampilkan monitoring report untuk anak

2. **Tab Anak-anak** (Tab 2)
   - Text: "Anak-anak"
   - Tanpa icon
   - List data anak dengan CRUD operations

3. **Tab Notifikasi** (Tab 3) ⭐
   - Text: "Notifikasi"
   - **Badge merah dengan angka** untuk notifikasi yang belum dibaca
   - Badge format:
     ```dart
     if (unreadCount > 0) {
       Container(
         padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
         decoration: BoxDecoration(
           color: Colors.red,
           borderRadius: BorderRadius.circular(10),
         ),
         child: Text(
           unreadCount > 99 ? '99+' : unreadCount.toString(),
           // Maksimal 99+
         ),
       )
     }
     ```
   - Badge hilang ketika semua notifikasi sudah dibaca

### Visual Design

```
┌─────────────────────────────────────────────────────┐
│  [  Laporan  ] [  Anak-anak  ] [  Notifikasi  🔴 3 ] │  ← Grey background
│     ↑ White tab with shadow                          │
└─────────────────────────────────────────────────────┘
```

Selected tab:
- Background: `Colors.white`
- Text color: `AppTheme.primaryBlue`
- Shadow: Subtle black shadow (alpha 0.05)
- Border radius: 10

Unselected tab:
- Background: Transparent (grey dari container)
- Text color: `AppTheme.onSurfaceVariant`
- No shadow

### Responsive Behavior

- **Mobile** (< 600px): horizontal margin 24
- **Tablet** (600-1024px): horizontal margin 28
- **Desktop** (> 1024px): horizontal margin 32

Font size sama untuk semua breakpoints: 13-14

### Integration Points

Method signature diupdate:
```dart
// OLD
Widget _buildTabBar(bool isTablet)

// NEW
Widget _buildTabBar(bool isTablet, bool isDesktop)
```

Pemanggilan di build method:
```dart
_buildTabBar(isTablet, isDesktop),  // ✅ Tambah parameter isDesktop
```

### Badge Logic

```dart
// Hitung notifikasi yang belum dibaca
final unreadCount = notifications.where((n) => !n['isRead']).length;

// Tampilkan badge jika ada yang belum dibaca
if (unreadCount > 0) {
  // Show badge with count
  // Max 99+ untuk angka > 99
}
```

Badge akan otomatis update ketika:
- User membaca notifikasi (klik item)
- User klik "Tandai Semua" di tab notifikasi
- Notifikasi baru masuk dari backend

### Style Guide

**Colors:**
- Tab background: `Colors.grey.shade100` (#F5F5F5)
- Selected tab: `Colors.white` (#FFFFFF)
- Selected text: `AppTheme.primaryBlue`
- Unselected text: `AppTheme.onSurfaceVariant`
- Badge background: `Colors.red`
- Badge text: `Colors.white`

**Spacing:**
- Container padding: 4px
- Tab border radius: 10px
- Badge horizontal padding: 6px
- Badge vertical padding: 2px
- Badge border radius: 10px

**Typography:**
- Font weight: 600 (semibold) untuk semua state
- Font size: 13-14 (responsive)
- Badge font: 10, bold

**Shadow:**
- Color: `Colors.black.withValues(alpha: 0.05)`
- Blur radius: 8
- Offset: (0, 2)

### Testing Checklist

- [x] TabBar renders with grey background
- [x] Selected tab shows white background with shadow
- [x] Tab text changes color based on selection
- [x] Badge shows correct unread count
- [x] Badge displays "99+" for counts > 99
- [x] Badge hides when unreadCount is 0
- [x] Responsive margins work on all screen sizes
- [x] Tab switching works smoothly
- [x] No compile errors

### Notes

- Style sekarang match dengan `puasa_page.dart`
- Icon dihapus dari tab untuk tampilan yang lebih clean
- Badge notifikasi lebih prominent dengan background merah
- Transition lebih smooth dengan white indicator vs gradient
- Accessibility: Contrast ratio tetap baik untuk readability

### Screenshots Location

(Untuk dokumentasi, tambahkan screenshot di sini)
- Mobile view: `docs/screenshots/monitoring_tabbar_mobile.png`
- Tablet view: `docs/screenshots/monitoring_tabbar_tablet.png`
- Desktop view: `docs/screenshots/monitoring_tabbar_desktop.png`
- Badge active: `docs/screenshots/monitoring_badge_active.png`
