# 🌟 Dokumentasi Fitur Premium & Subscription

## 📋 Overview

Fitur subscription ini menggunakan integrasi **Midtrans** sebagai payment gateway. User dapat membeli paket premium untuk mengakses fitur **Tahajud Tracker** dan **Monitoring Anak**.

---

## 🏗️ Struktur File

```
lib/features/subscription/
├── models/
│   ├── plan_model.dart              # Model paket subscription
│   ├── subscription_model.dart      # Model status subscription user
│   └── transaction_model.dart       # Model riwayat transaksi
├── pages/
│   ├── plan_page.dart               # Halaman pilihan paket
│   └── transaction_history_page.dart # Halaman riwayat transaksi
├── widgets/
│   └── premium_gate.dart            # Widget proteksi fitur premium
└── subscription_provider.dart       # State management

lib/features/tahajud/pages/
└── tahajud_page.dart                # Wrapped dengan PremiumGate

lib/features/monitoring/pages/
└── monitoring_page.dart             # Wrapped dengan PremiumGate
```

---

## 🎯 Fitur Utama

### 1. Plan Page (Halaman Paket)
**File**: `lib/features/subscription/pages/plan_page.dart`

**Fitur**:
- ✅ Menampilkan 3 pilihan paket (Basic, Premium, Family)
- ✅ Info status subscription aktif (jika ada)
- ✅ Detail fitur setiap paket
- ✅ Harga dengan diskon (jika ada)
- ✅ Badge "Paling Populer" untuk paket terpopuler
- ✅ Tombol "Beli Paket" dengan integrasi Midtrans
- ✅ Navigasi ke Transaction History
- ✅ Responsive design (mobile, tablet, desktop)

**Mock Data Paket**:
```dart
Basic: Rp 29.000 / 30 hari
Premium: Rp 79.000 / 90 hari (Hemat 10%)
Family: Rp 299.000 / 365 hari (Hemat 20%)
```

**Flow Pembelian**:
1. User pilih paket → klik "Beli Paket"
2. Konfirmasi dialog muncul
3. Create transaction ke backend (API call)
4. Backend create Midtrans transaction & return Snap URL
5. Open Snap URL di browser eksternal
6. User melakukan pembayaran di Midtrans
7. User kembali ke app → cek status di Transaction History

---

### 2. Transaction History Page
**File**: `lib/features/subscription/pages/transaction_history_page.dart`

**Fitur**:
- ✅ List semua transaksi user (pending, success, failed, expired)
- ✅ Detail transaksi: Order ID, Plan, Amount, Payment Method
- ✅ Nomor VA dengan tombol copy (untuk bank transfer)
- ✅ Countdown expired time (untuk pending)
- ✅ Tombol "Cek Status Pembayaran" untuk refresh status
- ✅ Pull to refresh
- ✅ Status indicator dengan warna (hijau=success, orange=pending, dll)

**Status Transaksi**:
```dart
'pending'  → Menunggu Pembayaran (orange)
'success'  → Berhasil (green)
'failed'   → Gagal (red)
'expired'  → Kadaluarsa (grey)
```

---

### 3. Premium Gate (Proteksi Fitur)
**File**: `lib/features/subscription/widgets/premium_gate.dart`

**Fungsi**: Widget wrapper untuk proteksi fitur premium

**Cara Pakai**:
```dart
return PremiumGate(
  featureName: 'Tahajud Tracker',
  child: ActualFeaturePage(),
);
```

**Behavior**:
- Jika user **premium** → show child widget (fitur aktual)
- Jika user **not premium** → show locked screen dengan:
  - Lock icon
  - Deskripsi fitur premium
  - List benefit premium
  - Tombol "Upgrade ke Premium" → navigate to PlanPage

---

### 4. Subscription Provider
**File**: `lib/features/subscription/subscription_provider.dart`

**State**:
```dart
SubscriptionState {
  List<PlanModel> plans;
  List<TransactionModel> transactions;
  SubscriptionModel? activeSubscription;
  bool isLoading;
  String? error;
  String? message;
  bool isPremium; // computed getter
}
```

**Methods**:
```dart
loadPlans()                          // Load available plans
loadActiveSubscription()             // Check current subscription
createTransaction(planId)            // Create Midtrans transaction
loadTransactions()                   // Load transaction history
checkTransactionStatus(orderId)      // Refresh status dari Midtrans
```

---

## 🔌 Integrasi API (Backend)

### 1. GET /api/subscription/plans
**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "1",
      "name": "Basic",
      "description": "Akses fitur dasar selama 1 bulan",
      "price": 29000,
      "duration_days": 30,
      "features": [
        "Akses Tahajud Tracker",
        "Monitoring Anak (Max 2 anak)",
        "Notifikasi Basic",
        "Support Email"
      ],
      "is_popular": false,
      "discount": null
    },
    ...
  ]
}
```

---

### 2. GET /api/subscription/active
**Headers**: `Authorization: Bearer {token}`

**Response** (jika ada subscription aktif):
```json
{
  "success": true,
  "data": {
    "id": "sub123",
    "user_id": "user123",
    "plan_id": "2",
    "plan_name": "Premium",
    "start_date": "2024-11-01T00:00:00Z",
    "end_date": "2025-01-30T23:59:59Z",
    "is_active": true,
    "status": "active"
  }
}
```

**Response** (jika tidak ada):
```json
{
  "success": true,
  "data": null
}
```

---

### 3. POST /api/subscription/transaction
**Headers**: `Authorization: Bearer {token}`

**Body**:
```json
{
  "plan_id": "2"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "transaction_id": "trx123",
    "order_id": "ORD-2024-001",
    "snap_token": "abc123xyz",
    "snap_url": "https://app.sandbox.midtrans.com/snap/v2/vtweb/abc123xyz",
    "amount": 79000,
    "expired_at": "2024-11-05T23:59:59Z"
  }
}
```

**Flow Backend**:
1. Validasi plan_id & user authentication
2. Create order di database (status: pending)
3. Create Midtrans transaction via Snap API:
   ```php
   $params = [
     'transaction_details' => [
       'order_id' => 'ORD-2024-001',
       'gross_amount' => 79000,
     ],
     'customer_details' => [
       'first_name' => $user->name,
       'email' => $user->email,
     ],
     'item_details' => [[
       'id' => $plan->id,
       'price' => $plan->price,
       'quantity' => 1,
       'name' => $plan->name,
     ]],
   ];
   $snapToken = \Midtrans\Snap::getSnapToken($params);
   ```
4. Save snap_token & snap_url ke database
5. Return snap_url ke frontend

---

### 4. GET /api/subscription/transactions
**Headers**: `Authorization: Bearer {token}`

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "1",
      "order_id": "ORD-2024-001",
      "user_id": "user123",
      "plan_id": "2",
      "plan_name": "Premium",
      "amount": 79000,
      "status": "pending",
      "payment_type": "bank_transfer",
      "va_number": "8277123456789012",
      "bank_name": "BCA",
      "created_at": "2024-11-01T10:00:00Z",
      "paid_at": null,
      "expired_at": "2024-11-02T10:00:00Z",
      "snap_token": "abc123xyz",
      "snap_url": "https://app.sandbox.midtrans.com/snap/v2/vtweb/abc123xyz"
    },
    ...
  ]
}
```

---

### 5. POST /api/subscription/check-status
**Headers**: `Authorization: Bearer {token}`

**Body**:
```json
{
  "order_id": "ORD-2024-001"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "order_id": "ORD-2024-001",
    "status": "success",
    "payment_type": "bank_transfer",
    "transaction_time": "2024-11-01T11:30:00Z"
  }
}
```

**Flow Backend**:
1. Check status via Midtrans API:
   ```php
   $status = \Midtrans\Transaction::status($orderId);
   ```
2. Update transaction di database
3. Jika status = 'settlement':
   - Update transaction.status = 'success'
   - Create/update subscription:
     ```sql
     INSERT INTO subscriptions (user_id, plan_id, start_date, end_date, is_active, status)
     VALUES (user_id, plan_id, NOW(), NOW() + INTERVAL duration_days DAY, 1, 'active')
     ```
4. Return updated status

---

### 6. Webhook Midtrans (Notification Handler)
**Endpoint**: POST /api/webhook/midtrans

**Body** (dari Midtrans):
```json
{
  "transaction_status": "settlement",
  "order_id": "ORD-2024-001",
  "gross_amount": "79000.00",
  "payment_type": "bank_transfer",
  "transaction_time": "2024-11-01 11:30:00",
  "signature_key": "..."
}
```

**Flow Backend**:
1. Verify signature key (security)
2. Find transaction by order_id
3. Update status based on transaction_status:
   - `settlement` → success, activate subscription
   - `pending` → pending
   - `deny` / `cancel` / `expire` → failed/expired
4. Send notification to user (optional: email/push notif)

---

## 🧪 Testing Mode

### Mock Data (Saat Ini)
Provider menggunakan **mock data** untuk development. Uncomment di `subscription_provider.dart`:

```dart
// Test subscription aktif
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
```

### Midtrans Sandbox
Untuk testing payment:
1. Gunakan **Sandbox Mode** di Midtrans
2. Kredensial sandbox:
   - Server Key: `SB-Mid-server-xxxxx`
   - Client Key: `SB-Mid-client-xxxxx`
3. Test card number: `4811 1111 1111 1114`
4. Test VA number: akan generate otomatis

---

## 🎨 UI/UX Features

### Responsive Design
- **Mobile** (< 600px): 1 kolom grid, compact spacing
- **Tablet** (600-1024px): 2 kolom grid, medium spacing
- **Desktop** (> 1024px): 3 kolom grid, large spacing

### Color Scheme
```dart
Primary Blue:   #1E88E5
Secondary Teal: #26A69A
Success Green:  Colors.green
Warning Orange: Colors.orange
Error Red:      Colors.red
```

### Animations
- Fade transition pada page load
- Smooth scroll untuk lists
- Pull to refresh gesture
- Loading indicators saat API call

---

## 🔐 Security

### Authentication
Semua API endpoint subscription butuh authentication:
```dart
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
}
```

### Midtrans Security
- Verify signature key di webhook
- Gunakan HTTPS untuk production
- Simpan Server Key di environment variable (jangan hardcode)

---

## 🚀 Deployment Checklist

### Frontend
- [ ] Update API base URL dari mock ke production
- [ ] Update environment variables (.env):
  ```
  MIDTRANS_CLIENT_KEY=your-production-client-key
  API_BASE_URL=https://api.yourdomain.com
  ```
- [ ] Remove mock data dari provider
- [ ] Test semua flow dengan real API
- [ ] Enable error tracking (Sentry/Firebase Crashlytics)

### Backend
- [ ] Setup Midtrans production account
- [ ] Configure webhook URL di Midtrans dashboard:
  ```
  https://api.yourdomain.com/api/webhook/midtrans
  ```
- [ ] Setup database tables:
  - plans
  - subscriptions
  - transactions
- [ ] Implement cron job untuk check expired subscriptions
- [ ] Setup email notifications

---

## 📱 User Flow Diagram

```
┌─────────────┐
│  Home Page  │
└──────┬──────┘
       │ User click "Tahajud" / "Monitoring"
       ▼
┌──────────────┐
│ PremiumGate  │ ◄── Check isPremium
└──────┬───────┘
       │ Not Premium
       ▼
┌────────────────┐
│ Locked Screen  │
└──────┬─────────┘
       │ Click "Upgrade"
       ▼
┌───────────────┐
│   Plan Page   │ ◄── Show 3 plans
└──────┬────────┘
       │ Select plan & click "Beli"
       ▼
┌─────────────────┐
│ Confirmation    │
│    Dialog       │
└──────┬──────────┘
       │ Confirm
       ▼
┌─────────────────┐
│  API: Create    │
│  Transaction    │
└──────┬──────────┘
       │ Return Snap URL
       ▼
┌─────────────────┐
│ Open Browser    │
│ (Midtrans Snap) │
└──────┬──────────┘
       │ Complete payment
       ▼
┌─────────────────┐
│ Back to App     │
│ → Transaction   │
│    History      │
└──────┬──────────┘
       │ Click "Cek Status"
       ▼
┌─────────────────┐
│  API: Check     │
│     Status      │
└──────┬──────────┘
       │ Status: Success
       ▼
┌─────────────────┐
│ Subscription    │
│    Activated!   │
└─────────────────┘
       │
       ▼
┌─────────────────┐
│ Access Premium  │
│    Features     │
└─────────────────┘
```

---

## 🐛 Troubleshooting

### Issue: Premium Gate tidak muncul
**Solution**: Pastikan subscription provider sudah di-wrap di main app:
```dart
runApp(
  ProviderScope(
    child: MyApp(),
  ),
);
```

### Issue: Payment URL tidak terbuka
**Solution**: 
1. Check permission di `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   ```
2. Verify `url_launcher` package sudah diinstall

### Issue: Status transaksi tidak update
**Solution**: 
1. Check webhook URL di Midtrans dashboard
2. Verify webhook handler di backend
3. Test manual dengan "Cek Status" button

---

## 📞 Support

Jika ada pertanyaan atau issue:
- Email: support@shollover.com
- WhatsApp: +62 xxx xxxx xxxx
- GitHub Issues: [Link repo]

---

## 📄 License

© 2024 Shollover. All rights reserved.
