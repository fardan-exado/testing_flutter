# 🚀 Quick Start - Subscription Feature

## Setup Cepat (5 Menit)

### 1. Navigasi ke Plan Page

Dari mana saja di aplikasi, Anda bisa akses Plan Page:

**Dari Profile Page**:
```dart
Navigator.pushNamed(context, '/plan');
```

**Dari Home Page** (custom button):
```dart
ElevatedButton(
  onPressed: () => Navigator.pushNamed(context, '/plan'),
  child: Text('Upgrade Premium'),
)
```

---

### 2. Testing Premium Features

#### Option A: Test dengan Mock Premium
Uncomment ini di `subscription_provider.dart` (line ~125):

```dart
Future<void> loadActiveSubscription() async {
  // ...
  
  // UNCOMMENT INI UNTUK TESTING PREMIUM
  final subscription = SubscriptionModel(
    id: '1',
    userId: 'user123',
    planId: '2',
    planName: 'Premium',
    startDate: DateTime.now().subtract(const Duration(days: 10)),
    endDate: DateTime.now().add(const Duration(days: 80)),
    isActive: true,
    status: 'active',
  );

  state = state.copyWith(
    activeSubscription: subscription, // Ganti dari null ke subscription
  );
}
```

Setelah itu:
- Restart app
- Navigate ke Tahajud/Monitoring page
- Fitur akan langsung accessible (tidak ada lock screen)

---

#### Option B: Test Flow Lengkap (Locked → Purchase)

Biarkan `activeSubscription: null` (default):
1. Buka Tahajud/Monitoring page → akan tampil Locked Screen
2. Click "Upgrade ke Premium"
3. Pilih paket → Click "Beli Paket"
4. Akan redirect ke Midtrans Snap URL (sandbox mode)

---

### 3. Melihat Status Premium

**Di Plan Page**:
```dart
// Jika premium, akan tampil card hijau:
┌─────────────────────────────┐
│ 🌟 Status Premium Aktif     │
│ Premium                     │
│                             │
│ Berlaku Hingga: 30 Jan 2025│
│ Sisa Hari: 80 hari          │
└─────────────────────────────┘
```

**Di Profile Page**:
- Menu "Paket Premium" akan show status aktif

---

### 4. Testing Transaction Flow

#### Buat Transaksi:
```dart
// Di plan_page.dart, function _handleBuyPlan sudah handle:
final snapUrl = await ref
    .read(subscriptionProvider.notifier)
    .createTransaction(planId);

// snapUrl akan open di browser
```

#### Lihat Riwayat:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const TransactionHistoryPage(),
  ),
);
```

#### Cek Status:
```dart
// Di transaction_history_page.dart, click button:
await ref
    .read(subscriptionProvider.notifier)
    .checkTransactionStatus(orderId);
```

---

## 📦 Install Dependencies

Pastikan package ini sudah ada di `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  intl: ^0.18.1
  url_launcher: ^6.2.1
  
  # Jika belum ada, jalankan:
  # flutter pub add url_launcher
```

---

## 🔗 Integration dengan API

### Step 1: Update Base URL
Di `subscription_provider.dart`, ganti mock API dengan real API:

```dart
Future<void> loadPlans() async {
  state = state.copyWith(isLoading: true, clearError: true);

  try {
    // GANTI INI:
    // await Future.delayed(const Duration(seconds: 1));
    
    // DENGAN INI:
    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}/api/subscription/plans'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final plans = (data['data'] as List)
          .map((json) => PlanModel.fromJson(json))
          .toList();
      
      state = state.copyWith(plans: plans, isLoading: false);
    } else {
      throw Exception('Failed to load plans');
    }
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: 'Gagal memuat paket: ${e.toString()}',
    );
  }
}
```

### Step 2: Update All Methods
Apply same pattern untuk:
- `loadActiveSubscription()`
- `createTransaction()`
- `loadTransactions()`
- `checkTransactionStatus()`

---

## 🎨 Customization

### Ubah Warna Plan Card
Di `plan_page.dart`, method `_buildPlanCard`:

```dart
border: Border.all(
  color: plan.isPopular
      ? const Color(0xFF1E88E5)  // Ganti warna border
      : Colors.grey.shade300,
  width: plan.isPopular ? 2 : 1,
),
```

### Ubah Text Premium Gate
Di `premium_gate.dart`, line ~80:

```dart
Text(
  'Fitur $featureName hanya tersedia untuk pengguna premium',
  // Ganti dengan text custom Anda
)
```

### Tambah Menu Plan di Home
Di `home_page.dart`, tambahkan card/button:

```dart
Card(
  child: ListTile(
    leading: Icon(Icons.workspace_premium_rounded),
    title: Text('Upgrade Premium'),
    subtitle: Text('Akses fitur eksklusif'),
    onTap: () => Navigator.pushNamed(context, '/plan'),
  ),
)
```

---

## ✅ Testing Checklist

### UI Testing
- [ ] Plan Page tampil 3 paket
- [ ] Badge "Paling Populer" muncul di paket Premium
- [ ] Harga format correct (Rp 29.000)
- [ ] Duration tampil (30/90/365 hari)
- [ ] Features list complete
- [ ] Button "Beli Paket" clickable
- [ ] Navigation ke Transaction History works

### Flow Testing
- [ ] Non-premium user → Tahajud → Locked Screen
- [ ] Click "Upgrade" → Navigate to Plan Page
- [ ] Select plan → Confirmation dialog
- [ ] Confirm → API call → Snap URL opens
- [ ] Back to app → Transaction History tampil
- [ ] Click "Cek Status" → Status update

### Premium Testing
- [ ] Premium user → Tahajud → Direct access (no lock)
- [ ] Premium user → Monitoring → Direct access
- [ ] Premium card tampil di Plan Page
- [ ] Button "Beli Paket" disabled (text: "Sudah Premium")

### Edge Cases
- [ ] No internet → Error message
- [ ] API timeout → Error toast
- [ ] Invalid plan_id → Error handling
- [ ] Expired transaction → Grey badge + "Kadaluarsa"
- [ ] Empty transaction list → Empty state

---

## 🔥 Quick Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Build release
flutter build apk --release

# Check for errors
flutter analyze

# Format code
flutter format lib/
```

---

## 📞 Bantuan Cepat

**Error: PremiumGate not found**
```dart
// Pastikan import di tahajud_page.dart:
import 'package:test_flutter/features/subscription/widgets/premium_gate.dart';
```

**Error: url_launcher not working**
```bash
flutter pub add url_launcher
flutter pub get
```

**Premium tidak aktif padahal sudah bayar**
```dart
// Check di subscription_provider.dart:
bool get isPremium => activeSubscription?.isPremium ?? false;

// Debug:
print('Active Sub: ${activeSubscription?.toJson()}');
```

**Transaction History kosong**
```dart
// Check API response di loadTransactions()
// Pastikan backend return array of transactions
```

---

## 🎯 Next Steps

1. **Integrate dengan Backend**
   - Setup Laravel/Node.js backend
   - Implement semua API endpoints
   - Setup Midtrans account

2. **Setup Webhook**
   - Configure Midtrans webhook URL
   - Test payment notifications
   - Verify signature security

3. **Production Deploy**
   - Update environment variables
   - Test di real device
   - Submit ke Play Store/App Store

---

## 📚 Dokumentasi Lengkap

Lihat `SUBSCRIPTION_DOCUMENTATION.md` untuk:
- API Specifications
- Database Schema
- Security Guidelines
- Troubleshooting Guide

---

**Happy Coding! 🚀**
