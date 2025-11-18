# Subscription & Payment Implementation

## Overview
Implementasi fitur subscription premium dengan integrasi Midtrans payment gateway menggunakan Midtrans SDK.

## Features
- ✅ Check premium status dari server
- ✅ Simpan status premium di local storage (flutter_secure_storage)
- ✅ Buy package dengan Midtrans payment
- ✅ Handle payment callback
- ✅ Auto refresh premium status setelah payment

## Files Created/Modified

### 1. State Management
- **pesanan_state.dart** - State untuk pesanan (loading, error, isPremium, dll)
- **pesanan_provider.dart** - Provider untuk manage pesanan state

### 2. Page Updates
- **plan_page.dart** - Updated dengan:
  - Midtrans SDK initialization
  - Premium status check
  - Payment flow dengan Midtrans UI

## Environment Variables Required

Tambahkan ke file `.env`:

```env
# Midtrans Configuration
MIDTRANS_CLIENT_KEY=your_midtrans_client_key
MIDTRANS_MERCHANT_BASE_URL=your_backend_url

# Storage URL for plan covers
STORAGE_URL=your_storage_url
```

## API Endpoints Required

Backend harus menyediakan endpoints berikut:

### 1. Check Premium Status
```
GET /premium/pesanan/status
Response: {
  "status": true,
  "message": "Success",
  "data": {
    "is_premium": true/false
  }
}
```

### 2. Buy Package
```
POST /premium/pesanan/beli-paket
Body: { "paket_id": "uuid" }
Response: {
  "status": true,
  "message": "Success",
  "data": {
    "snap_token": "midtrans_snap_token"
  }
}
```

### 3. Get Riwayat Pesanan
```
GET /premium/pesanan/riwayat
Response: {
  "status": true,
  "message": "Success",
  "data": [
    {
      "id": 1,
      "order_id": "ORDER-123",
      "user_id": 1,
      "paket_id": 1,
      "harga_total": 50000,
      "status": "settlement",
      "midtrans_id": "midtrans-id",
      "dibayar_pada": "2024-01-01",
      "kadaluarsa_pada": "2024-02-01",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z",
      "premium_paket": { ... }
    }
  ]
}
```

## Usage Flow

### 1. Initialize (App Start)
```dart
// Automatically called in plan_page.dart initState
ref.read(pesananProvider.notifier).checkStatusPremium();
```

### 2. Buy Package Flow
```dart
// User clicks "Beli Sekarang" button
// -> Show confirmation dialog
// -> Call buyPackage() to get snap_token
// -> Launch Midtrans UI with snap_token
// -> Handle payment result in callback
// -> Auto refresh premium status
```

### 3. Access Premium Status
```dart
final pesananState = ref.watch(pesananProvider);
final isPremium = pesananState.isPremium;

// Use isPremium to show/hide premium features
if (isPremium) {
  // Show premium content
} else {
  // Show upgrade prompt
}
```

## Local Storage

Premium status disimpan di `flutter_secure_storage` dengan key:
- `is_premium` - Boolean string ("true" or "false")

## Midtrans Callback

Ketika user selesai payment, callback akan:
1. Otomatis refresh premium status dari server
2. Show toast notification dengan status payment
3. Update UI accordingly

## Payment Status Handling

Status yang mungkin dari Midtrans:
- `settlement` - Payment sukses
- `pending` - Menunggu payment
- `deny` - Payment ditolak
- `cancel` - Payment dibatalkan
- `expire` - Payment expired

## Security Notes

⚠️ **Important:**
- Client key hanya untuk initialization
- Snap token harus selalu di-generate dari backend
- Premium status selalu di-validasi dari server
- Local storage hanya untuk caching, bukan source of truth

## Testing

### Test Premium Status
```dart
// Call manually from any widget
await ref.read(pesananProvider.notifier).checkStatusPremium();
```

### Test Payment Flow
1. Ensure Midtrans sandbox credentials di `.env`
2. Click "Beli Sekarang" pada plan card
3. Complete payment di Midtrans UI
4. Verify callback dan status update

## Troubleshooting

### Issue: Midtrans UI tidak muncul
- Check MIDTRANS_CLIENT_KEY di `.env`
- Verify snap_token dari backend tidak null
- Check logs untuk initialization errors

### Issue: Premium status tidak update
- Verify API endpoint `/premium/pesanan/status` working
- Check network connection
- Verify token authentication

### Issue: Payment callback tidak triggered
- Ensure `setTransactionFinishedCallback` dipanggil
- Check Midtrans SDK version compatibility
- Verify callback tidak di-remove premature

## Next Steps

1. ✅ Implement premium feature gating di app
2. ✅ Add transaction history page
3. ✅ Handle subscription expiry
4. ✅ Add subscription renewal flow
