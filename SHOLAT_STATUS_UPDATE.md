# Update Sholat Wajib - Status Field Implementation

## Tanggal: 1 November 2025

## Perubahan

### 1. Response API Structure (Sholat Wajib Hari Ini)
Struktur response dari endpoint `/sholat/progres/wajib/hari-ini`:

```json
{
    "status": true,
    "message": "Progres sholat wajib hari ini",
    "data": {
        "total": 2,
        "statistik": {
            "shubuh": true,
            "dzuhur": true,
            "ashar": false,
            "maghrib": false,
            "isya": false
        },
        "detail": [
            {
                "id": 3,
                "user_id": 8,
                "sholat_wajib_id": 1,
                "status": "tepat_waktu",
                "is_jamaah": 0,
                "tanggal": "2025-11-01",
                "lokasi": "Masjid",
                "keterangan": "test",
                "created_at": "2025-11-01T16:19:34.000000Z",
                "updated_at": "2025-11-01T16:19:34.000000Z"
            },
            {
                "id": 4,
                "user_id": 8,
                "sholat_wajib_id": 2,
                "status": "terlambat",
                "is_jamaah": 1,
                "tanggal": "2025-11-01",
                "lokasi": "Masjid",
                "keterangan": "jsjsjs",
                "created_at": "2025-11-01T16:19:48.000000Z",
                "updated_at": "2025-11-01T16:19:48.000000Z"
            }
        ]
    }
}
```

### 2. Perubahan di `sholat_page.dart`

#### Getter `_currentProgressData`
- **Sebelumnya**: Menggunakan field `statistik` untuk menentukan `completed`
- **Sekarang**: Jika ada di array `detail`, maka `completed: true`
- **Logic**:
  - Loop `detail` array untuk mendapatkan progress yang sudah ada
  - Gunakan mapping `sholat_wajib_id` (1-5) ke key (shubuh, dzuhur, dst)
  - Jika tidak ada di `detail`, tandai sebagai belum ada progress (`completed: false`)

```dart
// Loop detail untuk build progress data dengan informasi lengkap
for (var item in detail) {
  final sholatWajibId = item['sholat_wajib_id'] as int;
  final sholatKey = wajibIdToKey[sholatWajibId];

  if (sholatKey != null) {
    formattedProgress[sholatKey] = {
      'id': item['id'],
      'completed': true, // Ada di detail = sudah ada progress
      'status': item['status'] as String? ?? 'tepat_waktu',
      'is_jamaah': item['is_jamaah'] == 1,
      'lokasi': item['lokasi'] as String? ?? '',
      'keterangan': item['keterangan'] as String? ?? '',
    };
  }
}
```

#### Perubahan Pemanggilan `SholatCard`
- **Dihapus**: Parameter `isOnTime` (boolean)
- **Ditambahkan**: Parameter `status` (string: 'tepat_waktu', 'terlambat', 'tidak_sholat')

```dart
// SEBELUMNYA
SholatCard(
  isOnTime: (sholatProgress?['status'] as String? ?? 'tepat_waktu') == 'tepat_waktu',
  // ...
)

// SEKARANG
SholatCard(
  status: sholatProgress?['status'] as String? ?? 'tepat_waktu',
  // ...
)
```

### 3. Perubahan di `sholat_card.dart`

#### Property Class
```dart
// SEBELUMNYA
final bool isOnTime;

// SEKARANG
final String status; // tepat_waktu, terlambat, tidak_sholat
```

#### Badge Display Logic
Sekarang menampilkan 3 jenis badge status:

1. **Tepat Waktu** (hijau) - `status == 'tepat_waktu'`
   - Icon: `Icons.check_circle`
   - Warna: `Colors.green`

2. **Terlambat** (oranye) - `status == 'terlambat'`
   - Icon: `Icons.access_time`
   - Warna: `Colors.orange`

3. **Tidak Sholat** (merah) - `status == 'tidak_sholat'`
   - Icon: `Icons.cancel`
   - Warna: `Colors.red`

```dart
if (isCompleted) ...[
  // Status Badge
  if (status == 'tepat_waktu')
    _buildBadge(context, 'Tepat Waktu', Icons.check_circle, Colors.green)
  else if (status == 'terlambat')
    _buildBadge(context, 'Terlambat', Icons.access_time, Colors.orange)
  else if (status == 'tidak_sholat')
    _buildBadge(context, 'Tidak Sholat', Icons.cancel, Colors.red),
  
  // Jamaah Badge (hanya wajib)
  if (isJamaah && jenis == 'wajib')
    _buildBadge(context, 'Jamaah', Icons.groups, Colors.blue),
  
  // Lokasi Badge (hanya wajib)
  if (lokasi.isNotEmpty && jenis == 'wajib')
    _buildBadge(context, 'Lokasi', Icons.location_on, Colors.purple),
]
```

### 4. Mapping `sholat_wajib_id`

Backend menggunakan ID numerik untuk sholat wajib:
```dart
final Map<int, String> wajibIdToKey = {
  1: 'shubuh',
  2: 'dzuhur',
  3: 'ashar',
  4: 'maghrib',
  5: 'isya',
};
```

### 5. Logging
Ditambahkan logging untuk debugging:
```dart
logger.info('=== PARSING PROGRESS WAJIB ===');
logger.info('Statistik: $statistik');
logger.info('Detail count: ${detail.length}');
// ... untuk setiap item
logger.info('=== FORMATTED PROGRESS: $formattedProgress ===');
```

## Testing Checklist

- [x] Sholat wajib dengan progress terchecklist
- [x] Badge status ditampilkan dengan benar (Tepat Waktu, Terlambat, Tidak Sholat)
- [x] Badge jamaah ditampilkan untuk wajib
- [x] Badge lokasi ditampilkan dengan warna berbeda
- [x] Sholat tanpa progress tidak terchecklist
- [x] Tidak ada compilation errors

## Catatan Penting

1. **Field `statistik`** di response API sudah tidak digunakan untuk menentukan `completed`, tapi tetap ada untuk backward compatibility
2. **Field `total`** di response API menunjukkan jumlah sholat yang sudah dikerjakan (dari backend)
3. **Array `detail`** berisi informasi lengkap progress dengan `sholat_wajib_id`
4. **Jika `detail` kosong** untuk sebuah sholat, maka sholat tersebut belum ada progressnya
5. **Color palette badge**:
   - Status Tepat Waktu: Green
   - Status Terlambat: Orange  
   - Status Tidak Sholat: Red
   - Jamaah: Blue
   - Lokasi: Purple

## File yang Diubah

1. `lib/features/sholat/pages/sholat_page.dart`
   - Getter `_currentProgressData` - logic parsing untuk wajib
   - Pemanggilan `SholatCard` (wajib & sunnah)

2. `lib/features/sholat/widgets/sholat_card.dart`
   - Property class: `isOnTime` → `status`
   - Badge display logic dengan 3 status

## Backward Compatibility

- Sholat sunnah masih menggunakan struktur lama (array dengan `progres` boolean)
- Riwayat sholat masih menggunakan struktur lama
- Default value `status` adalah `'tepat_waktu'` jika tidak ada data
