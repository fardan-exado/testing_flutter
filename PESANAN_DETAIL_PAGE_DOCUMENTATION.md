# Pesanan Detail Page Documentation

## 📋 Overview

Halaman detail pesanan yang menampilkan informasi lengkap dari sebuah transaksi pembelian paket premium. Halaman ini dirancang dengan style yang konsisten dengan transaction history page dan menggunakan responsive design untuk semua ukuran layar.

---

## 📁 File Structure

```
lib/features/subscription/pages/
├── pesanan_detail_page.dart          (NEW) - Detail pesanan page
├── transaction_history_page.dart     (UPDATED) - Navigation ke detail page
└── plan_page.dart
```

---

## 🎨 Design & Layout

### Header Section
- **Gradient Background**: Blue (#1E88E5) → Cyan (#00BCD4)
- **Back Button**: Styled button dengan white color dan transparent background
- **Title**: "Detail Pesanan"
- **Subtitle**: Order ID (misal: "ORDER-001")
- **Shadow Effect**: Drop shadow untuk depth

### Content Sections
1. **Status Card** - Status pesanan dengan icon dan warna status
2. **Paket Info Card** - Nama, durasi, dan deskripsi paket
3. **Order Details Card** - ID pesanan, Order ID, harga, tanggal
4. **Payment Info Card** - ID Transaksi Midtrans dengan copy button
5. **Action Buttons** - Salin Info & Kembali buttons

---

## 📊 Data Model

```dart
ActiveSubscription {
  int id,                              // ID Pesanan
  String orderId,                      // Order ID (ORDER-001)
  int userId,
  int paketId,
  int hargaTotal,                      // Total harga (100000)
  String status,                       // paid, pending, failed, cancelled, expired
  String midtransId,                   // MIDTRANS-123456
  String? dibayarPada,                 // 2025-11-16 02:14:25
  String? kadaluarsaPada,              // 2025-12-16 02:14:25
  String createdAt,
  String updatedAt,
  PaketInfo premiumPaket {
    int id,
    String nama,                       // Paket Basic
    String coverPath,
    String deskripsi,                  // Deskripsi paket
    int harga,
    int durasi                         // 3 (bulan)
  }
}
```

---

## 🚀 Usage

### Navigate dari Transaction History
```dart
// Di transaction_history_page.dart
void _handleDetailPesanan(BuildContext context, transaction) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PesananDetailPage(pesanan: transaction),
    ),
  );
}
```

### Direct Navigation
```dart
// Dari mana saja di app
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PesananDetailPage(pesanan: activeSubscription),
  ),
);
```

---

## 🎯 Features

### 1. Status Display Card
- Gradient background berdasarkan status
- Icon yang sesuai dengan status
- Status label dalam bahasa Indonesia
- Warna-warna status:
  - 🟢 **Paid/Success** - Green
  - 🟠 **Pending** - Orange
  - 🔴 **Failed/Cancelled** - Red
  - ⚫ **Expired** - Grey

### 2. Paket Information
- Nama paket
- Durasi paket (dalam bulan)
- Deskripsi paket lengkap
- Responsive text sizing

### 3. Order Details
- ID Pesanan (database ID)
- Order ID (customer-facing ID)
- Total Harga (formatted Rp)
- Dibeli Pada (formatted date)
- Kadaluarsa Pada (formatted date)

### 4. Payment Information
- ID Transaksi Midtrans
- Copy button untuk ID Transaksi
- Total pembayaran highlight

### 5. Action Buttons
- **Salin Info** - Copy order details ke clipboard
- **Kembali** - Navigate back ke halaman sebelumnya

---

## 🎨 UI Components

### Status Colors Mapping
```dart
'paid'      → Green (#4CAF50)
'success'   → Green (#4CAF50)
'pending'   → Orange (#FF9800)
'failed'    → Red (#F44336)
'cancelled' → Red (#F44336)
'expired'   → Grey (#9E9E9E)
```

### Responsive Breakpoints
- **Mobile**: Full width dengan padding
- **Tablet**: Max width 800px
- **Desktop**: Max width 900px

---

## 📱 Responsive Design

### Helper Methods
```dart
double _px(BuildContext c, double base)
  → Adaptive padding/sizing berdasarkan screen size

double _ts(BuildContext c, double base)
  → Adaptive text size

EdgeInsets _pageHPad(BuildContext c)
  → Horizontal page padding

double _contentMaxWidth(BuildContext c)
  → Content max width berdasarkan screen
```

---

## 🔄 Integration Points

### 1. Transaction History Page
```dart
// Button "Detail Pesanan" di setiap transaction card
ElevatedButton.icon(
  onPressed: () => _handleDetailPesanan(context, transaction),
  icon: const Icon(Icons.receipt_long_rounded),
  label: const Text('Detail Pesanan'),
)
```

### 2. Pesanan Provider
Menggunakan data dari `PesananState.riwayatPesanan` yang sudah di-fetch dari API.

### 3. Theme Integration
Menggunakan `AppTheme` colors:
- `AppTheme.primaryBlue` - #1E88E5
- `AppTheme.accentGreen` - #00BCD4
- `AppTheme.onSurface` - Text color
- `AppTheme.onSurfaceVariant` - Secondary text

---

## 📋 Date Formatting

Format: `dd MMMM yyyy` dalam bahasa Indonesia

**Examples:**
- Input: `2025-11-16 02:14:25`
- Output: `16 November 2025`

**Parsing:**
- Supports both formats:
  - `2025-11-16 02:14:25`
  - `2025-11-16T02:14:25.000000Z`

---

## 💰 Currency Formatting

Format: `Rp X.XXX` dengan locale `id_ID`

**Examples:**
- `100000` → `Rp 100.000`
- `250000` → `Rp 250.000`

---

## 📦 Dependencies

```yaml
flutter:
  - Material Design 3
intl:
  - DateFormat untuk tanggal lokal
  - NumberFormat untuk mata uang
test_flutter:
  - app/theme.dart → AppTheme colors
  - core/utils/responsive_helper.dart → Responsive sizing
  - core/widgets/toast.dart → Toast notifications
  - features/subscription/models/active_subscription.dart → Data model
```

---

## 🔗 Navigation Flow

```
Plan Page
    ↓
Transaction History Page
    ↓ (Klik "Detail Pesanan")
Pesanan Detail Page
    ↓
(Klik "Kembali") → Kembali ke Transaction History
```

---

## ✨ Toast Notifications

Digunakan saat user melakukan copy action:

```dart
showMessageToast(
  context,
  message: 'Detail pesanan disalin',
  type: ToastType.success,
);
```

---

## 🎨 Color Palette

| Element | Color | Hex |
|---------|-------|-----|
| Primary | Blue | #1E88E5 |
| Secondary | Cyan | #00BCD4 |
| Success | Green | #4CAF50 |
| Warning | Orange | #FF9800 |
| Error | Red | #F44336 |
| Neutral | Grey | #9E9E9E |
| Background | White | #FFFFFF |
| Divider | Light Grey | #E8E8E8 |

---

## 📝 Example Data

```json
{
  "id": 1,
  "order_id": "ORDER-001",
  "user_id": 2,
  "paket_id": 1,
  "harga_total": 100000,
  "status": "paid",
  "midtrans_id": "MIDTRANS-123456",
  "dibayar_pada": "2025-11-16 02:14:25",
  "kadaluarsa_pada": "2025-12-16 02:14:25",
  "created_at": "2025-11-16T02:14:25.000000Z",
  "updated_at": "2025-11-16T02:14:25.000000Z",
  "premium_paket": {
    "id": 1,
    "nama": "Paket Basic",
    "cover_path": "images/premium/paket/cover/example.jpg",
    "deskripsi": "Paket pembelajaran dasar untuk pemula yang ingin memulai perjalanan belajar Islam. Cocok untuk anak-anak dan remaja yang baru memulai.",
    "harga": 100000,
    "durasi": 3
  }
}
```

---

## ✅ Testing Checklist

- [ ] Header displays correctly with gradient
- [ ] Back button navigates back
- [ ] Status card displays correct color & icon
- [ ] All paket info displayed correctly
- [ ] Order details formatted properly
- [ ] Dates formatted as "dd MMMM yyyy"
- [ ] Currency formatted as "Rp X.XXX"
- [ ] Copy ID Transaksi works
- [ ] Salin Info button copies correct data
- [ ] Responsive on mobile, tablet, desktop
- [ ] Toast notifications appear on copy
- [ ] Navigation from transaction history works
- [ ] All error states handled

---

## 🔧 Troubleshooting

### Date not formatting correctly
- Check if date string is valid ISO format
- Verify locale 'id_ID' is available
- Check `_formatDate()` method implementation

### Copy button not working
- Verify `flutter/services.dart` is imported
- Check clipboard permissions on platform

### Navigation not working
- Verify `pesanan_detail_page.dart` is imported
- Check route setup in `_handleDetailPesanan()`

### Responsive sizing off
- Verify `ResponsiveHelper` methods are used
- Check screen size breakpoints
- Test on different devices

---

## 📈 Performance

- ✅ Minimal rebuilds (StatefulWidget)
- ✅ Efficient async date parsing
- ✅ No unnecessary state management
- ✅ Responsive without layout jank

---

## 🚀 Future Enhancements

1. Add download invoice button
2. Add share pesanan functionality
3. Add payment proof image gallery
4. Add support/chat button
5. Add print invoice feature
6. Add refund/cancel request form

---

## 📞 Support

Untuk issues atau pertanyaan, hubungi tim development.
