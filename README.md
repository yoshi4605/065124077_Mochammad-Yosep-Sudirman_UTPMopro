# SiagaBumi (Pemantau Gempa Indonesia)

Aplikasi mobile berbasis Flutter untuk memantau data gempa bumi terkini di seluruh Indonesia secara langsung dari BMKG (Badan Meteorologi, Klimatologi, dan Geofisika), menyimpan riwayat gempa ke database lokal dengan catatan pribadi, serta menyediakan panduan kesiapsiagaan bencana.


---

## 📱 Fitur Utama Aplikasi

1. **Beranda (Home):**
   - Kartu besar **Gempa Terbaru** (AutoGempa BMKG) memuat info magnitudo, lokasi, kedalaman, koordinat, dan peringatan potensi tsunami.
   - Daftar ringkas 5 gempa terkini M 5.0+.
   - Fitur *Pull-to-Refresh* untuk memperbarui data realtime.

2. **Daftar Gempa (List):**
   - **TabBar 2 Kategori:** "M 5.0+" (15 data gempa) dan "Dirasakan" (15 data gempa).
   - Pencarian/filter interaktif instan berdasarkan nama wilayah atau kota.
   - Badge magnitudo dengan kode warna resmi (<4 Hijau, 4-5 Kuning, 5-6 Oranye, ≥6 Merah).

3. **Detail Gempa (Detail):**
   - Informasi terperinci (koordinat lintang & bujur, kedalaman sumber, waktu WIB, potensi tsunami, skala MMI).
   - Penampil peta guncangan (*Shakemap BMKG*) dengan placeholder dan error builder.
   - Tombol simpan/hapus ke **Pantauan Saya** (Local Storage SQLite).
   - Tombol **Buka di Peta** (*Google Maps* via `url_launcher`).
   - Tombol **Bagikan Info Gempa** (pesan teks lengkap via `share_plus`).
   - Animasi perpindahan halaman yang halus dengan *Hero Transition*.

4. **Pantauan Saya (Watchlist & Local Storage):**
   - Menyimpan gempa penting secara persisten di database SQLite lokal (`sqflite`).
   - Fitur penambahan dan pengeditan catatan pribadi per gempa (contoh: "Terasa di lantai 2 rumah").
   - Fitur *Swipe-to-Delete* (geser untuk menghapus) dengan konfirmasi dialog dan tombol *Undo* pada SnackBar.
   - *Empty State* yang rapi saat belum ada data yang disimpan.

5. **Panduan Siaga Bencana (Guide):**
   - Langkah mitigasi gempa interaktif (*ExpansionTile*): "Sebelum Gempa", "Saat Gempa", dan "Setelah Gempa".
   - **Tas Siaga Bencana (Checklist SQLite):** Daftar perlengkapan darurat standar BNPB yang dapat dicentang dan statusnya tersimpan di database lokal, lengkap dengan indikator progres kesiapan dan tombol reset.
   - Edukasi magnitudo & kedalaman gempa beserta legenda warna.
   - Tombol panggilan darurat langsung ke **BNPB Hotline: 117** via `url_launcher`.

---

## 🌐 Sumber Data (BMKG Public REST API)

Aplikasi menggunakan Public REST API resmi BMKG tanpa memerlukan API Key:
- **Gempa Terbaru (Autogempa):** `https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json`
- **15 Gempa M 5.0+:** `https://data.bmkg.go.id/DataMKG/TEWS/gempaterkini.json`
- **15 Gempa Dirasakan:** `https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json`
- **Peta Guncangan (Shakemap):** `https://data.bmkg.go.id/DataMKG/TEWS/{Shakemap}`

---

## 🗄️ Skema Database SQLite (Local Storage)

Database diinisialisasi melalui singleton class `DatabaseHelper`:

### 1. Tabel `watchlist` (Pantauan Saya)
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | TEXT PRIMARY KEY | ID unik gabungan `DateTime + Coordinates` |
| `tanggal` | TEXT | Tanggal gempa (contoh: 25 Nov 2026) |
| `jam` | TEXT | Jam gempa (contoh: 19:30:15 WIB) |
| `datetime` | TEXT | Waktu format ISO dari BMKG |
| `coordinates`| TEXT | Titik koordinat latitude, longitude |
| `lintang` | TEXT | Derajat lintang (LS/LU) |
| `bujur` | TEXT | Derajat bujur (BT/BB) |
| `magnitude` | TEXT | Nilai magnitudo gempa |
| `kedalaman` | TEXT | Kedalaman hiposentrum |
| `wilayah` | TEXT | Lokasi pusat gempa bumi |
| `potensi` | TEXT | Keterangan potensi tsunami |
| `dirasakan` | TEXT | Skala intensitas gempa (MMI) |
| `shakemap` | TEXT | Nama file gambar shakemap |
| `catatan` | TEXT | Catatan pribadi pengguna |
| `saved_at` | TEXT | Waktu data disimpan ke SQLite |

### 2. Tabel `checklist` (Tas Siaga Bencana)
| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | ID item |
| `item` | TEXT | Nama perlengkapan siaga |
| `category` | TEXT | Kategori kebutuhan (Dokumen, Medis, dll) |
| `is_checked` | INTEGER | Status centang (0 = belum, 1 = sudah) |

---

## 📦 Daftar Package / Dependencies

- `http: ^1.2.2` - Pengambilan data Public REST API BMKG secara asinkron.
- `provider: ^6.1.2` - Manajemen state reaktif (Earthquake, Watchlist, Checklist).
- `sqflite: ^2.3.3+1` & `path: ^1.9.0` - Penyimpanan database SQLite lokal pada perangkat mobile.
- `intl: ^0.19.0` - Format tanggal, waktu, dan angka dalam bahasa Indonesia (`id_ID`).
- `url_launcher: ^6.3.1` - Membuka lokasi gempa di Google Maps dan panggilan darurat BNPB 117.
- `share_plus: ^10.1.2` - Membagikan rincian informasi gempa ke aplikasi lain (WhatsApp, Telegram, dll).
- `cached_network_image: ^3.4.1` - Caching dan penanganan gambar shakemap BMKG dengan placeholder.

---

## 📂 Struktur Folder Proyek

```
lib/
├── main.dart                      # Entry point aplikasi & inisialisasi MultiProvider
├── models/
│   ├── earthquake.dart            # Model data gempa (JSON & SQLite mapper)
│   └── checklist_item.dart        # Model item tas siaga bencana
├── services/
│   ├── bmkg_api_service.dart      # Service HTTP client & error handling BMKG API
│   └── database_helper.dart       # SQLite Helper singleton (CRUD watchlist & checklist)
├── providers/
│   ├── earthquake_provider.dart   # State provider data gempa & filter pencarian
│   ├── watchlist_provider.dart    # State provider pantauan lokal & catatan
│   └── checklist_provider.dart    # State provider tas siaga bencana
├── screens/
│   ├── main_shell.dart            # Shell navigasi BottomNavigationBar 4 tab
│   ├── home_screen.dart           # Halaman 1: Beranda gempa terbaru & ringkasan M5.0+
│   ├── list_screen.dart           # Halaman 2: Daftar gempa (M5.0+ & Dirasakan + Cari)
│   ├── detail_screen.dart         # Halaman 3: Detail lengkap, peta, bagikan & simpan
│   ├── watchlist_screen.dart      # Halaman 4: Pantauan lokal tersimpan & edit catatan
│   └── guide_screen.dart          # Halaman 5: Panduan mitigasi & checklist tas siaga
├── widgets/
│   ├── earthquake_card.dart       # Widget kartu gempa reusable
│   ├── magnitude_badge.dart       # Badge warna magnitudo (<4, 4-5, 5-6, >=6)
│   ├── error_view.dart            # Widget penanganan error ramah + Coba Lagi
│   ├── loading_view.dart          # Widget indikator proses memuat data
│   └── empty_view.dart            # Widget empty state informatif
└── utils/
    ├── constants.dart             # Endpoint URL BMKG, nomor darurat, warna
    ├── formatters.dart            # Helper parsing & formatter tanggal/koordinat
    └── theme.dart                 # Tema Material 3 (Light & Dark Mode)
```

---

## 🚀 Cara Menjalankan Aplikasi

### Prasyarat
- Flutter SDK (versi 3.19 ke atas, disarankan 3.35.x atau terbaru)
- Android Studio / VS Code dengan ekstensi Flutter & Dart
- Perangkat Android (Emulator atau HP fisik dengan USB Debugging aktif)

### Langkah-langkah
1. **Clone repository ini:**
   ```bash
   git clone <URL_REPOSITORY_ANDA>
   cd yosep_077_utp
   ```

2. **Unduh dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verifikasi kode (Linter check):**
   ```bash
   flutter analyze
   ```
   *(Pastikan status `No issues found!`)*

4. **Jalankan aplikasi di perangkat target:**
   ```bash
   flutter run
   ```

---

## 🛡️ Hak Akses & Izin Android (`AndroidManifest.xml`)
Aplikasi telah ditambahkan perizinan internet dan queries skema:
- `android.permission.INTERNET` (Akses data API BMKG dan gambar Shakemap)
- Intent queries `tel` (Panggilan telepon hotline 117 BNPB)
- Intent queries `https` & `geo` (Membuka titik pusat gempa di Google Maps)
