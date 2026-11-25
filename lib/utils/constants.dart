import 'package:flutter/material.dart';

/// Konstanta aplikasi SiagaBumi
class AppConstants {
  // Nama & Identitas Aplikasi
  static const String appName = 'SiagaBumi';
  static const String appTagline = 'Pemantau Gempa Bumi Indonesia';

  // Endpoint Public REST API BMKG (tanpa API key)
  static const String autoGempaUrl =
      'https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json';
  static const String gempaTerkiniUrl =
      'https://data.bmkg.go.id/DataMKG/TEWS/gempaterkini.json';
  static const String gempaDirasakanUrl =
      'https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json';
  static const String shakemapBaseUrl =
      'https://data.bmkg.go.id/DataMKG/TEWS/';

  // Kontak Darurat Bencana
  static const String emergencyPhone = '117';
  static const String emergencyAgency = 'BNPB (Badan Nasional Penanggulangan Bencana)';
  static const String bmkgWebUrl = 'https://www.bmkg.go.id';

  // Durasi Request Timeout
  static const Duration requestTimeout = Duration(seconds: 10);

  // Palet Warna Kategori Magnitudo
  static const Color magLow = Color(0xFF2E7D32); // Hijau (< 4.0)
  static const Color magMedium = Color(0xFFF9A825); // Kuning (4.0 - 4.9)
  static const Color magHigh = Color(0xFFE65100); // Oranye (5.0 - 5.9)
  static const Color magSevere = Color(0xFFC62828); // Merah (>= 6.0)

  // Warna Aksen Siaga
  static const Color primarySeed = Color(0xFFC62828);
}
