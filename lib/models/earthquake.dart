import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Model representasi data Gempa Bumi (BMKG Public API & SQLite Watchlist)
class Earthquake {
  final String id;
  final String tanggal;
  final String jam;
  final String dateTime;
  final String coordinates;
  final String lintang;
  final String bujur;
  final String magnitude;
  final String kedalaman;
  final String wilayah;
  final String? potensi;
  final String? dirasakan;
  final String? shakemap;
  final String? catatan;
  final String? savedAt;

  const Earthquake({
    required this.id,
    required this.tanggal,
    required this.jam,
    required this.dateTime,
    required this.coordinates,
    required this.lintang,
    required this.bujur,
    required this.magnitude,
    required this.kedalaman,
    required this.wilayah,
    this.potensi,
    this.dirasakan,
    this.shakemap,
    this.catatan,
    this.savedAt,
  });

  /// Factory untuk membuat Earthquake dari JSON BMKG dengan penanganan aman (null-safe)
  factory Earthquake.fromJson(Map<String, dynamic> json) {
    final tanggal = json['Tanggal']?.toString().trim() ?? '';
    final jam = json['Jam']?.toString().trim() ?? '';
    final dt = json['DateTime']?.toString().trim() ?? '';
    final coords = json['Coordinates']?.toString().trim() ?? '';
    final lintang = json['Lintang']?.toString().trim() ?? '';
    final bujur = json['Bujur']?.toString().trim() ?? '';
    final magnitude = json['Magnitude']?.toString().trim() ?? '0.0';
    final kedalaman = json['Kedalaman']?.toString().trim() ?? '-';
    final wilayah = json['Wilayah']?.toString().trim() ?? 'Wilayah Tidak Diketahui';
    final potensi = json['Potensi']?.toString().trim();
    final dirasakan = json['Dirasakan']?.toString().trim();
    final shakemap = json['Shakemap']?.toString().trim();

    // ID unik gabungan DateTime + Coordinates (atau fallback tanggal+jam+wilayah)
    final uniqueId = (dt.isNotEmpty && coords.isNotEmpty)
        ? '${dt}_$coords'
        : '${tanggal}_${jam}_${coords.isNotEmpty ? coords : wilayah}';

    return Earthquake(
      id: uniqueId,
      tanggal: tanggal,
      jam: jam,
      dateTime: dt,
      coordinates: coords,
      lintang: lintang,
      bujur: bujur,
      magnitude: magnitude,
      kedalaman: kedalaman,
      wilayah: wilayah,
      potensi: potensi,
      dirasakan: dirasakan,
      shakemap: shakemap,
    );
  }

  /// Konversi dari Row Map SQLite
  factory Earthquake.fromMap(Map<String, dynamic> map) {
    return Earthquake(
      id: map['id']?.toString() ?? '',
      tanggal: map['tanggal']?.toString() ?? '',
      jam: map['jam']?.toString() ?? '',
      dateTime: map['datetime']?.toString() ?? '',
      coordinates: map['coordinates']?.toString() ?? '',
      lintang: map['lintang']?.toString() ?? '',
      bujur: map['bujur']?.toString() ?? '',
      magnitude: map['magnitude']?.toString() ?? '0.0',
      kedalaman: map['kedalaman']?.toString() ?? '-',
      wilayah: map['wilayah']?.toString() ?? '',
      potensi: map['potensi']?.toString(),
      dirasakan: map['dirasakan']?.toString(),
      shakemap: map['shakemap']?.toString(),
      catatan: map['catatan']?.toString(),
      savedAt: map['saved_at']?.toString(),
    );
  }

  /// Konversi ke Map untuk disimpan di database SQLite tabel `watchlist`
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tanggal': tanggal,
      'jam': jam,
      'datetime': dateTime,
      'coordinates': coordinates,
      'lintang': lintang,
      'bujur': bujur,
      'magnitude': magnitude,
      'kedalaman': kedalaman,
      'wilayah': wilayah,
      'potensi': potensi,
      'dirasakan': dirasakan,
      'shakemap': shakemap,
      'catatan': catatan,
      'saved_at': savedAt ?? DateTime.now().toIso8601String(),
    };
  }

  /// Copy with untuk memperbarui data (seperti catatan atau savedAt)
  Earthquake copyWith({
    String? catatan,
    String? savedAt,
  }) {
    return Earthquake(
      id: id,
      tanggal: tanggal,
      jam: jam,
      dateTime: dateTime,
      coordinates: coordinates,
      lintang: lintang,
      bujur: bujur,
      magnitude: magnitude,
      kedalaman: kedalaman,
      wilayah: wilayah,
      potensi: potensi,
      dirasakan: dirasakan,
      shakemap: shakemap,
      catatan: catatan ?? this.catatan,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  // Getters Nilai Angka & URL
  double get magnitudeValue => Formatters.parseMagnitude(magnitude);
  double get depthValue => Formatters.parseDepth(kedalaman);

  /// URL lengkap gambar peta guncangan (shakemap)
  String? get fullShakemapUrl {
    if (shakemap == null || shakemap!.trim().isEmpty) return null;
    return '${AppConstants.shakemapBaseUrl}$shakemap';
  }

  /// Koordinat lintang dan bujur
  ({double lat, double lon})? get latLng {
    return Formatters.parseCoordinates(coordinates);
  }

  /// URL Google Maps
  String? get googleMapsUrl {
    final parsed = latLng;
    if (parsed == null) return null;
    return 'https://www.google.com/maps/search/?api=1&query=${parsed.lat},${parsed.lon}';
  }

  /// Indikator potensi tsunami
  bool get hasTsunamiPotential {
    if (potensi == null) return false;
    final lower = potensi!.toLowerCase();
    return lower.contains('berpotensi tsunami') && !lower.contains('tidak berpotensi tsunami');
  }

  /// Format teks ringkas untuk dibagikan via share_plus
  String get shareText {
    final buffer = StringBuffer();
    buffer.writeln('🚨 INFO GEMPA BUMI - SiagaBumi (BMKG)');
    buffer.writeln('Magnitudo: M $magnitude');
    buffer.writeln('Kedalaman: $kedalaman');
    buffer.writeln('Wilayah: $wilayah');
    buffer.writeln('Waktu: $tanggal, $jam WIB');
    if (potensi != null && potensi!.isNotEmpty) {
      buffer.writeln('Potensi: $potensi');
    }
    if (dirasakan != null && dirasakan!.isNotEmpty) {
      buffer.writeln('Dirasakan: $dirasakan');
    }
    if (coordinates.isNotEmpty) {
      buffer.writeln('Koordinat: $coordinates ($lintang, $bujur)');
    }
    if (googleMapsUrl != null) {
      buffer.writeln('Lokasi Peta: $googleMapsUrl');
    }
    buffer.writeln('\nPantau informasi resmi BMKG melalui aplikasi SiagaBumi.');
    return buffer.toString();
  }
}
