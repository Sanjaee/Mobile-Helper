# Debug Polyline - Mengikuti Jalan Seperti Gojek

## Masalah yang Diperbaiki
Polyline sebelumnya menampilkan garis lurus, sekarang sudah diperbaiki untuk mengikuti jalan yang sebenarnya seperti Google Maps dan Gojek.

## Perubahan yang Dilakukan

### 1. **Service yang Diupdate**
- ✅ `GoogleDirectionsService` - Menggunakan implementasi yang tepat
- ✅ `NavigationPage` - Menggunakan `GoogleDirectionsService`
- ✅ `ProviderOnTheWayPage` - Menggunakan `GoogleDirectionsService`

### 2. **Implementasi yang Benar**
```dart
// Menggunakan flutter_polyline_points untuk decode polyline
final points = await directionsService.getPolylinePoints(
  startLat, startLng, endLat, endLng,
);

// Convert PointLatLng to LatLng
final polylineCoordinates = points.map((p) => LatLng(p.latitude, p.longitude)).toList();
```

### 3. **Dependencies yang Diperlukan**
```yaml
dependencies:
  google_maps_flutter: ^2.7.0
  flutter_polyline_points: ^2.0.0
  dio: ^5.4.0
```

## Testing

### 1. **Test Page**
```dart
// Navigate to test page
context.go('/test-polyline');

// Shows Jakarta to Bandung route
// Polyline should follow actual roads
```

### 2. **Manual Testing**
```dart
final directionsService = GoogleDirectionsService();
final points = await directionsService.getPolylinePoints(
  -6.200000, 106.816666, // Jakarta
  -6.917464, 107.619125, // Bandung
);

print('Polyline points count: ${points.length}');
// Should show many points following roads
```

### 3. **Debug Console**
Periksa console untuk error:
```bash
# Jika berhasil, tidak ada error
# Jika gagal, akan muncul:
# "Error getPolylinePoints: [error message]"
```

## Troubleshooting

### ❌ **Masalah: Masih Garis Lurus**

**Penyebab:**
1. API key tidak valid
2. Directions API tidak diaktifkan
3. Internet connection bermasalah
4. Koordinat tidak valid

**Solusi:**
1. **Cek API Key:**
   ```dart
   // lib/core/constants/api_config.dart
   static const String googleMapsApiKey = 'YOUR_ACTUAL_API_KEY';
   ```

2. **Cek API Response:**
   ```bash
   curl "https://maps.googleapis.com/maps/api/directions/json?origin=-6.200000,106.816666&destination=-6.917464,107.619125&key=YOUR_API_KEY"
   ```

3. **Cek Console Logs:**
   ```dart
   print('API Response: $data');
   print('Polyline points: ${points.length}');
   ```

### ✅ **Yang Harus Terlihat**

1. **Polyline mengikuti jalan:**
   - Tidak memotong bangunan
   - Mengikuti jalan raya dan tol
   - Rute yang realistis

2. **Visual yang benar:**
   - Warna hijau Gojek (`#00BFA5`)
   - Lebar 6px dengan rounded caps
   - Pattern dash yang smooth

3. **Performance yang baik:**
   - Loading cepat
   - Rendering smooth
   - Update real-time

## Verifikasi

### 1. **Test dengan Koordinat Real**
```dart
// Jakarta ke Bandung
final points = await directionsService.getPolylinePoints(
  -6.200000, 106.816666, // Jakarta
  -6.917464, 107.619125, // Bandung
);

// Should return many points following roads
print('Points count: ${points.length}'); // Should be > 100
```

### 2. **Test dengan Koordinat Lokal**
```dart
// Test dengan koordinat order yang sebenarnya
final points = await directionsService.getPolylinePoints(
  orderLat, orderLng,     // Lokasi order
  clientLat, clientLng,   // Lokasi client
);

// Should follow actual roads between these points
```

### 3. **Compare dengan Google Maps**
- Buka Google Maps
- Cari rute dari titik A ke titik B
- Bandingkan dengan polyline di app
- Harus sama atau sangat mirip

## Expected Results

### ✅ **Berhasil**
- Polyline mengikuti jalan raya
- Tidak ada garis lurus memotong bangunan
- Rute realistis dan bisa diikuti
- Visual seperti Gojek/Google Maps

### ❌ **Gagal**
- Masih garis lurus
- Polyline memotong bangunan/air
- Error di console
- Tidak ada polyline sama sekali

## Next Steps

1. **Test dengan Data Real:**
   - Gunakan koordinat order yang sebenarnya
   - Test di berbagai lokasi
   - Verifikasi akurasi

2. **Performance Testing:**
   - Test di device yang berbeda
   - Cek memory usage
   - Optimize jika perlu

3. **User Experience:**
   - Gather feedback
   - Compare dengan Google Maps
   - Make improvements

## Support

Jika masih ada masalah:
1. Check console logs untuk error
2. Verify API key dan permissions
3. Test dengan koordinat yang berbeda
4. Compare dengan implementasi Google Maps
