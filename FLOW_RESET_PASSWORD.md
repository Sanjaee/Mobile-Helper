# Flow Reset Password

Dokumentasi ini menjelaskan flow reset password yang telah dibuat sesuai struktur folder.

## Struktur Flow

### 1. **Reset Password Request** (`/reset-password`)

- **File**: `lib/presentation/auth/reset_password_page.dart`
- **Fungsi**: User memasukkan email untuk request reset password
- **API Call**: `POST /api/v1/auth/request-reset-password`
- **Next Step**: Navigate ke halaman verify OTP

### 2. **Verify OTP** (`/verify-otp?isPasswordReset=true`)

- **File**: `lib/presentation/auth/verify_otp_page.dart`
- **Fungsi**: User memasukkan OTP yang dikirim ke email
- **Parameter**: `isPasswordReset=true` untuk membedakan dari OTP registrasi
- **Next Step**: Navigate ke halaman change password dengan email dan OTP

### 3. **Change Password** (`/change-password`)

- **File**: `lib/presentation/auth/change_password_page.dart`
- **Fungsi**: User memasukkan password baru dan konfirmasi password
- **Parameter**: `email` dan `otpCode` dari URL
- **API Call**: `POST /api/v1/auth/verify-reset-password`
- **Next Step**: Navigate ke home page

## Flow Update Password (Terpisah)

### **Update Password** (`/update-password`)

- **File**: `lib/presentation/auth/update_password_page.dart`
- **Fungsi**: User yang sudah login ingin mengubah password
- **Input**: Current password, new password, confirm password
- **Access**: Dari halaman home (button "Change Password")

## Perbedaan Flow

| Flow                | Akses                   | Input                           | API Endpoint                                         |
| ------------------- | ----------------------- | ------------------------------- | ---------------------------------------------------- |
| **Reset Password**  | Public (lupa password)  | Email → OTP → New Password      | `/request-reset-password` → `/verify-reset-password` |
| **Update Password** | Protected (sudah login) | Current Password → New Password | `/update-password` (TODO)                            |

## Routing Configuration

```dart
// Routes yang sudah ditambahkan
static const String resetPassword = '/reset-password';
static const String verifyOtp = '/verify-otp';
static const String changePassword = '/change-password';
static const String updatePassword = '/update-password';
```

## API Endpoints

### Reset Password Flow

1. `POST /api/v1/auth/request-reset-password`

   - Body: `{"email": "user@example.com"}`
   - Response: Success message

2. `POST /api/v1/auth/verify-reset-password`
   - Body: `{"email": "user@example.com", "otp_code": "123456", "new_password": "newpass123"}`
   - Response: AuthResponse dengan tokens

### Update Password Flow (TODO)

- `POST /api/v1/auth/update-password`
  - Body: `{"current_password": "oldpass", "new_password": "newpass123"}`
  - Response: Success message

## Testing Flow

1. **Test Reset Password**:

   - Buka app → Login page → "Forgot Password?"
   - Input email → "Send Reset Code"
   - Input OTP → "Verify OTP"
   - Input new password → "Change Password"
   - Should redirect to home page

2. **Test Update Password**:
   - Login → Home page → "Change Password"
   - Input current password, new password, confirm password
   - "Update Password" (TODO: implement API)

## Security Notes

- OTP hanya valid untuk waktu tertentu
- Password baru harus memenuhi kriteria validasi
- Reset password flow tidak memerlukan authentication
- Update password flow memerlukan authentication (current password)
