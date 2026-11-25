import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

/// Helper formatting untuk tanggal, koordinat, dan magnitudo gempa
class Formatters {
  /// Parsing string magnitudo (misal "5.3", "5,3") ke double
  static double parseMagnitude(String? magStr) {
    if (magStr == null || magStr.trim().isEmpty) return 0.0;
    try {
      final sanitized = magStr.replaceAll(',', '.').trim();
      return double.tryParse(sanitized) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// Parsing string kedalaman (misal "10 km", "150 km") ke double dalam km
  static double parseDepth(String? depthStr) {
    if (depthStr == null || depthStr.trim().isEmpty) return 0.0;
    try {
      final sanitized = depthStr
          .replaceAll(RegExp(r'[^0-9.,]'), '')
          .replaceAll(',', '.')
          .trim();
      return double.tryParse(sanitized) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// Warna badge berdasarkan magnitudo:
  /// - Hijau: < 4.0
  /// - Kuning: 4.0 - 4.9
  /// - Oranye: 5.0 - 5.9
  /// - Merah: >= 6.0
  static Color getMagnitudeColor(double mag) {
    if (mag < 4.0) return AppConstants.magLow;
    if (mag < 5.0) return AppConstants.magMedium;
    if (mag < 6.0) return AppConstants.magHigh;
    return AppConstants.magSevere;
  }

  /// Label kategori magnitudo
  static String getMagnitudeCategory(double mag) {
    if (mag < 4.0) return 'Ringan';
    if (mag < 5.0) return 'Sedang';
    if (mag < 6.0) return 'Kuat';
    return 'Sangat Kuat / Signifikan';
  }

  /// Parsing koordinat dari String "lat,lon" (misal: "-6.78,107.12")
  static ({double lat, double lon})? parseCoordinates(String? coords) {
    if (coords == null || !coords.contains(',')) return null;
    try {
      final parts = coords.split(',');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0].trim());
        final lon = double.tryParse(parts[1].trim());
        if (lat != null && lon != null) {
          return (lat: lat, lon: lon);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Format tanggal ramah bahasa Indonesia
  static String formatIndonesianDate(String? rawDate, String? rawTime) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    if (rawTime != null && rawTime.isNotEmpty) {
      return '$rawDate, $rawTime WIB';
    }
    return rawDate;
  }

  /// Format DateTime ISO / string tersimpan
  static String formatSavedAt(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '-';
    try {
      final dt = DateTime.tryParse(isoString);
      if (dt != null) {
        return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt.toLocal());
      }
    } catch (_) {}
    return isoString;
  }
}
