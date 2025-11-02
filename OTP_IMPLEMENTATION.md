# Implementasi OTP Authentication

## 📋 Overview

Implementasi sistem OTP (One-Time Password) yang reusable untuk dua kasus penggunaan:

1. **Verifikasi Registrasi** - User mendaftar → menerima OTP → verifikasi → login otomatis
2. **Reset Password** - User lupa password → menerima OTP → input password baru

## 🔄 Flow Diagram

### 1. Registration Flow dengan OTP

```
User → Register Page
    ↓ (input name, email, password)
    ↓ Submit
    ↓
Backend mengirim OTP ke email
    ↓
OTP Page (type: registration)
    ↓ (input 6-digit OTP)
    ↓ Verify
    ↓
Authenticated → Home Page
```

### 2. Forgot Password Flow dengan OTP

```
User → Login Page
    ↓ "Lupa Password?"
    ↓
Forgot Password Page
    ↓ (input email)
    ↓ Submit
    ↓
Backend mengirim OTP ke email
    ↓
OTP Page (type: forgotPassword)
    ↓ (input 6-digit OTP)
    ↓ Verify
    ↓
Reset Password Page
    ↓ (input password baru + OTP)
    ↓ Submit
    ↓
Password Reset Success → Login Page
```

## 📁 File Structure

```
lib/
├── features/
│   └── auth/
│       ├── pages/
│       │   ├── otp.dart                 # ✨ NEW - Reusable OTP Page
│       │   ├── signup_page.dart         # ✏️ UPDATED
│       │   ├── forgot_password.dart     # ✏️ UPDATED
│       │   └── reset_password.dart      # ✏️ UPDATED
│       ├── auth_service.dart            # ✏️ UPDATED - Added OTP endpoints
│       └── auth_provider.dart           # ✏️ UPDATED - Added OTP methods
└── app/
    └── router.dart                      # ✏️ UPDATED - Added OTP route
```

## 🔧 API Endpoints

### 1. Register (POST /register)

**Request:**

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```

**Response:**

```json
{
  "status": true,
  "message": "Registrasi berhasil! Kode OTP telah dikirim ke email Anda."
}
```

### 2. Verify OTP Registration (POST /verify-otp)

**Request:**

```json
{
  "email": "john@example.com",
  "otp": "123456"
}
```

**Response:**

```json
{
  "status": true,
  "message": "Verifikasi berhasil!",
  "data": {
    "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "phone": null,
      "auth_method": "email",
      "avatar": null
    }
  }
}
```

### 3. Forgot Password (POST /forgot-password)

**Request:**

```json
{
  "email": "john@example.com"
}
```

**Response:**

```json
{
  "status": true,
  "message": "Kode OTP telah dikirim ke email Anda."
}
```

### 4. Reset Password dengan OTP (POST /reset-password)

**Request:**

```json
{
  "otp": "123456",
  "email": "john@example.com",
  "password": "newpassword123",
  "password_confirmation": "newpassword123"
}
```

**Response:**

```json
{
  "status": true,
  "message": "Password berhasil direset. Silakan login dengan password baru Anda."
}
```

### 5. Resend OTP (POST /resend-otp)

**Request:**

```json
{
  "email": "john@example.com"
}
```

**Response:**

```json
{
  "status": true,
  "message": "Kode OTP telah dikirim ulang."
}
```

## 🎨 OTP Page Features

### Komponen Utama:

1. **6-Digit OTP Input**

   - Auto-focus ke field berikutnya setelah input
   - Auto-focus ke field sebelumnya ketika backspace
   - Only accepts numeric input
   - Visual feedback dengan border highlight

2. **Resend OTP Timer**

   - Countdown 60 detik
   - Button "Kirim Ulang" disabled selama countdown
   - Auto-enable setelah countdown selesai

3. **Animated UI**

   - Fade animation untuk smooth appearance
   - Slide animation untuk card form
   - Responsive design untuk semua ukuran layar

4. **Error Handling**
   - Toast notification untuk error
   - Toast notification untuk success
   - Clear dan informatif error messages

## 🔐 Auth States

```dart
enum AuthState {
  initial,           // State awal
  loading,           // Sedang proses
  authenticated,     // User sudah login
  unauthenticated,   // User belum login
  error,             // Terjadi error
  isRegistered,      // ✨ NEW - Registrasi berhasil, menunggu OTP
  forgotPasswordSent,// OTP untuk reset password terkirim
  passwordReset,     // Password berhasil direset
  otpSent,          // ✨ NEW - OTP berhasil dikirim ulang
  otpVerified,      // ✨ NEW - OTP berhasil diverifikasi
}
```

## 📱 Usage Examples

### 1. Navigate ke OTP Page untuk Registration

```dart
Navigator.pushReplacementNamed(
  context,
  '/otp',
  arguments: {
    'email': 'user@example.com',
    'type': 'registration',
  },
);
```

### 2. Navigate ke OTP Page untuk Forgot Password

```dart
Navigator.pushReplacementNamed(
  context,
  '/otp',
  arguments: {
    'email': 'user@example.com',
    'type': 'forgot_password',
  },
);
```

### 3. Navigate ke Reset Password dengan OTP

```dart
Navigator.pushReplacementNamed(
  context,
  '/reset-password',
  arguments: {
    'otp': '123456',
    'email': 'user@example.com',
  },
);
```

## 🧪 Testing Checklist

### Registration Flow:

- [ ] User dapat melakukan registrasi
- [ ] OTP dikirim ke email setelah registrasi
- [ ] User dapat input OTP 6 digit
- [ ] Auto-navigate antar input field
- [ ] Verifikasi OTP berhasil
- [ ] User otomatis login setelah verifikasi
- [ ] Navigate ke home page setelah verifikasi

### Forgot Password Flow:

- [ ] User dapat input email di forgot password page
- [ ] OTP dikirim ke email
- [ ] User dapat input OTP
- [ ] Navigate ke reset password page dengan OTP
- [ ] User dapat input password baru
- [ ] Password berhasil direset
- [ ] Navigate ke login page setelah reset

### Resend OTP:

- [ ] Timer countdown 60 detik berfungsi
- [ ] Button disabled selama countdown
- [ ] Button enabled setelah countdown selesai
- [ ] OTP baru terkirim setelah klik "Kirim Ulang"
- [ ] Timer reset setelah resend

### Error Handling:

- [ ] Error ditampilkan dengan toast
- [ ] Error message jelas dan informatif
- [ ] User tidak stuck di loading state
- [ ] Form dapat disubmit ulang setelah error

## 🎯 Best Practices

1. **Security**

   - OTP hanya valid untuk waktu tertentu (set di backend)
   - OTP hanya bisa digunakan sekali
   - Rate limiting untuk prevent brute force

2. **UX**

   - Clear instructions untuk user
   - Visual feedback untuk setiap action
   - Loading state yang jelas
   - Error messages yang helpful

3. **Code Quality**
   - Reusable components (OTPPage untuk 2 use cases)
   - Proper state management dengan Riverpod
   - Clean separation of concerns
   - Well-documented code

## 🚀 Future Enhancements

1. **Auto-read OTP dari SMS** (Android)
2. **Biometric verification** setelah OTP
3. **Multiple OTP delivery methods** (SMS, WhatsApp, Email)
4. **OTP input with paste functionality**
5. **Progressive countdown dengan progress bar**
6. **Haptic feedback** saat input OTP

## 📞 Support

Jika ada pertanyaan atau issue, silakan hubungi team development.

---

**Created:** 2025-10-30
**Last Updated:** 2025-10-30
**Version:** 1.0.0
