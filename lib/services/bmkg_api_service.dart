import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/earthquake.dart';
import '../utils/constants.dart';

/// Exception khusus untuk penanganan kesalahan koneksi & data BMKG
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NoInternetException extends ApiException {
  NoInternetException()
      : super('Tidak ada koneksi internet. Periksa Wi-Fi atau data seluler Anda.');
}

class TimeoutApiException extends ApiException {
  TimeoutApiException()
      : super('Waktu permintaan habis (timeout 10 detik). Server BMKG sedang padat.');
}

class DataParseException extends ApiException {
  DataParseException([String? details])
      : super(details ?? 'Gagal membaca format data gempa dari server BMKG.');
}

/// Service untuk mengambil data gempa bumi resmi dari BMKG Public API
class BmkgApiService {
  final http.Client _client;

  BmkgApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Mengambil data 1 gempa terbaru dan paling terkini (autogempa.json)
  /// Struktur respons: { "Infogempa": { "gempa": { ...objek tunggal... } } }
  Future<Earthquake> fetchLatestEarthquake() async {
    try {
      final response = await _client
          .get(Uri.parse(AppConstants.autoGempaUrl))
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final infoGempa = data['Infogempa'];
        if (infoGempa == null || infoGempa['gempa'] == null) {
          throw DataParseException('Format data gempa terbaru tidak ditemukan.');
        }

        final gempaJson = infoGempa['gempa'] as Map<String, dynamic>;
        return Earthquake.fromJson(gempaJson);
      } else {
        throw ApiException(
            'Server BMKG merespons dengan kesalahan (${response.statusCode}).',
            response.statusCode);
      }
    } on SocketException {
      throw NoInternetException();
    } on TimeoutException {
      throw TimeoutApiException();
    } on FormatException {
      throw DataParseException('Format respon JSON BMKG tidak valid.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal mengambil data gempa terbaru: $e');
    }
  }

  /// Mengambil 15 data gempa berkekuatan M 5.0+ (gempaterkini.json)
  /// Struktur respons: { "Infogempa": { "gempa": [ ...list objek... ] } }
  Future<List<Earthquake>> fetchRecentEarthquakes() async {
    try {
      final response = await _client
          .get(Uri.parse(AppConstants.gempaTerkiniUrl))
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final infoGempa = data['Infogempa'];
        if (infoGempa == null || infoGempa['gempa'] == null) {
          return [];
        }

        final gempaListJson = infoGempa['gempa'];
        if (gempaListJson is List) {
          return gempaListJson
              .map((item) => Earthquake.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (gempaListJson is Map<String, dynamic>) {
          // Jika BMKG mengembalikan single object
          return [Earthquake.fromJson(gempaListJson)];
        }
        return [];
      } else {
        throw ApiException(
            'Gagal memuat daftar gempa M 5.0+ (${response.statusCode}).',
            response.statusCode);
      }
    } on SocketException {
      throw NoInternetException();
    } on TimeoutException {
      throw TimeoutApiException();
    } on FormatException {
      throw DataParseException('Format JSON gempa M 5.0+ tidak valid.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kendala saat memuat gempa M 5.0+: $e');
    }
  }

  /// Mengambil 15 data gempa yang dirasakan masyarakat (gempadirasakan.json)
  /// Struktur respons: { "Infogempa": { "gempa": [ ...list objek... ] } }
  Future<List<Earthquake>> fetchFeltEarthquakes() async {
    try {
      final response = await _client
          .get(Uri.parse(AppConstants.gempaDirasakanUrl))
          .timeout(AppConstants.requestTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final infoGempa = data['Infogempa'];
        if (infoGempa == null || infoGempa['gempa'] == null) {
          return [];
        }

        final gempaListJson = infoGempa['gempa'];
        if (gempaListJson is List) {
          return gempaListJson
              .map((item) => Earthquake.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (gempaListJson is Map<String, dynamic>) {
          return [Earthquake.fromJson(gempaListJson)];
        }
        return [];
      } else {
        throw ApiException(
            'Gagal memuat daftar gempa dirasakan (${response.statusCode}).',
            response.statusCode);
      }
    } on SocketException {
      throw NoInternetException();
    } on TimeoutException {
      throw TimeoutApiException();
    } on FormatException {
      throw DataParseException('Format JSON gempa dirasakan tidak valid.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kendala saat memuat gempa dirasakan: $e');
    }
  }
}
