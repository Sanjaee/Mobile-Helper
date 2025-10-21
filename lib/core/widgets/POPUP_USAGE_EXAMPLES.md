# Custom Popup Component - Panduan Penggunaan

Component popup yang reusable dan bisa digunakan di mana pun dalam aplikasi.

## Import

```dart
import '../../core/widgets/custom_popup.dart';
```

## 1. Success Popup

Untuk menampilkan pesan sukses:

```dart
CustomPopup.showSuccess(
  context: context,
  title: 'Berhasil!',
  message: 'Data berhasil disimpan.',
  buttonText: 'OK', // optional, default: 'OK'
  onConfirm: () {
    // Aksi setelah user klik OK
    print('User clicked OK');
  },
);
```

## 2. Error Popup

Untuk menampilkan pesan error:

```dart
CustomPopup.showError(
  context: context,
  title: 'Gagal!',
  message: 'Terjadi kesalahan saat menyimpan data.',
  buttonText: 'Tutup', // optional
  onConfirm: () {
    // Aksi setelah user klik tombol
  },
);
```

## 3. Warning Popup

Untuk menampilkan pesan peringatan:

```dart
CustomPopup.showWarning(
  context: context,
  title: 'Perhatian!',
  message: 'Anda yakin ingin melanjutkan?',
  buttonText: 'Mengerti',
);
```

## 4. Info Popup

Untuk menampilkan informasi:

```dart
CustomPopup.showInfo(
  context: context,
  title: 'Informasi',
  message: 'Fitur ini akan segera hadir.',
);
```

## 5. Confirmation Popup

Untuk konfirmasi dengan pilihan Yes/No:

```dart
final confirmed = await CustomPopup.showConfirmation(
  context: context,
  title: 'Konfirmasi',
  message: 'Apakah Anda yakin ingin menghapus data ini?',
  confirmText: 'Hapus', // optional
  cancelText: 'Batal', // optional
);

if (confirmed == true) {
  // User klik confirm
  print('User confirmed');
} else {
  // User klik cancel atau dismiss
  print('User cancelled');
}
```

## 6. Rating Success Popup

Popup khusus untuk menampilkan ucapan setelah rating:

```dart
CustomPopup.showRatingSuccess(
  context: context,
  rating: 5, // 1-5 bintang
  onConfirm: () {
    // Navigate setelah popup
    context.go('/home');
  },
);
```

**Pesan berdasarkan rating:**
- **5 bintang**: "Terima Kasih! ⭐⭐⭐⭐⭐" - Senang sekali Anda puas
- **4 bintang**: "Terima Kasih! ⭐⭐⭐⭐" - Kami senang Anda menyukai
- **3 bintang**: "Terima Kasih atas Rating Anda ⭐⭐⭐" - Akan berusaha lebih baik
- **2 bintang**: "Mohon Maaf ⭐⭐" - Akan memperbaiki layanan
- **1 bintang**: "Mohon Maaf ⭐" - Sangat menyesal

## 7. Custom Popup

Untuk popup dengan widget custom:

```dart
CustomPopup.showCustom(
  context: context,
  child: Container(
    padding: EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Custom Content'),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    ),
  ),
);
```

## Opsi Tambahan

### Barrier Dismissible

Kontrol apakah popup bisa ditutup dengan tap di luar:

```dart
CustomPopup.showSuccess(
  context: context,
  title: 'Success',
  message: 'Data saved',
  barrierDismissible: false, // User harus klik tombol untuk tutup
);
```

### Async/Await Pattern

Tunggu sampai popup ditutup:

```dart
await CustomPopup.showSuccess(
  context: context,
  title: 'Success',
  message: 'Order created',
);

// Kode ini akan dijalankan setelah popup ditutup
print('Popup closed');
```

## Contoh Real Case

### Accept Order dengan Confirmation

```dart
Future<void> _acceptOrder() async {
  // Tampilkan confirmation popup
  final confirmed = await CustomPopup.showConfirmation(
    context: context,
    title: 'Accept Order?',
    message: 'Are you sure you want to accept this order?',
    confirmText: 'Accept',
    cancelText: 'Cancel',
  );

  if (confirmed != true) return;

  try {
    // Proses accept order
    await orderService.acceptOrder(orderId);
    
    // Tampilkan success popup
    await CustomPopup.showSuccess(
      context: context,
      title: 'Order Accepted!',
      message: 'Let\'s go to the location!',
      onConfirm: () {
        // Navigate setelah user klik OK
        context.go('/navigation');
      },
    );
  } catch (e) {
    // Tampilkan error popup
    CustomPopup.showError(
      context: context,
      title: 'Failed',
      message: 'Error: $e',
    );
  }
}
```

### Submit Rating dengan Feedback

```dart
Future<void> _submitRating() async {
  if (_selectedRating == 0) {
    CustomPopup.showWarning(
      context: context,
      title: 'Rating Required',
      message: 'Please select a rating first.',
    );
    return;
  }

  try {
    await ratingService.submitRating(_selectedRating);
    
    // Popup berbeda berdasarkan rating
    await CustomPopup.showRatingSuccess(
      context: context,
      rating: _selectedRating,
      onConfirm: () {
        context.go('/home');
      },
    );
  } catch (e) {
    CustomPopup.showError(
      context: context,
      title: 'Failed',
      message: 'Error submitting rating: $e',
    );
  }
}
```

## Styling

Semua popup sudah memiliki styling yang konsisten:
- **Rounded corners**: 20px
- **Icon dengan background**: Circle dengan opacity 0.1
- **Button**: Rounded 12px dengan elevation 0
- **Text**: Hierarchy yang jelas (title bold, message regular)

## Tips

1. ✅ Gunakan `showConfirmation` untuk aksi yang destructive (delete, cancel, dll)
2. ✅ Gunakan `showRatingSuccess` untuk feedback rating
3. ✅ Set `barrierDismissible: false` untuk popup yang memerlukan user action
4. ✅ Gunakan `onConfirm` callback untuk navigate setelah popup
5. ✅ Combine dengan try-catch untuk error handling yang baik

