import 'package:flutter/foundation.dart';
import '../models/earthquake.dart';
import '../services/bmkg_api_service.dart';

/// Provider pengelola state data gempa bumi BMKG (API Service)
class EarthquakeProvider with ChangeNotifier {
  final BmkgApiService _apiService;

  EarthquakeProvider({BmkgApiService? apiService})
      : _apiService = apiService ?? BmkgApiService();

  // State Data
  Earthquake? _latestEarthquake;
  List<Earthquake> _recentEarthquakes = [];
  List<Earthquake> _feltEarthquakes = [];

  // State Loading & Error
  bool _isLoadingLatest = false;
  bool _isLoadingRecent = false;
  bool _isLoadingFelt = false;

  String? _errorLatest;
  String? _errorRecent;
  String? _errorFelt;

  // Filter pencarian untuk halaman daftar
  String _searchQuery = '';

  // Getters
  Earthquake? get latestEarthquake => _latestEarthquake;
  List<Earthquake> get recentEarthquakes => _recentEarthquakes;
  List<Earthquake> get feltEarthquakes => _feltEarthquakes;

  bool get isLoadingLatest => _isLoadingLatest;
  bool get isLoadingRecent => _isLoadingRecent;
  bool get isLoadingFelt => _isLoadingFelt;
  bool get isLoadingAny =>
      _isLoadingLatest || _isLoadingRecent || _isLoadingFelt;

  String? get errorLatest => _errorLatest;
  String? get errorRecent => _errorRecent;
  String? get errorFelt => _errorFelt;
  String get searchQuery => _searchQuery;

  /// Daftar gempa M5.0+ tersaring berdasarkan nama wilayah
  List<Earthquake> get filteredRecentEarthquakes {
    if (_searchQuery.trim().isEmpty) return _recentEarthquakes;
    final q = _searchQuery.toLowerCase().trim();
    return _recentEarthquakes
        .where((eq) => eq.wilayah.toLowerCase().contains(q))
        .toList();
  }

  /// Daftar gempa dirasakan tersaring berdasarkan nama wilayah
  List<Earthquake> get filteredFeltEarthquakes {
    if (_searchQuery.trim().isEmpty) return _feltEarthquakes;
    final q = _searchQuery.toLowerCase().trim();
    return _feltEarthquakes
        .where((eq) => eq.wilayah.toLowerCase().contains(q))
        .toList();
  }

  /// Mengubah kata kunci pencarian
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Mengambil semua data secara paralel (beranda & awal buka aplikasi)
  Future<void> fetchAll() async {
    await Future.wait([
      fetchLatest(),
      fetchRecent(),
      fetchFelt(),
    ]);
  }

  /// Memuat gempa terbaru (autogempa)
  Future<void> fetchLatest() async {
    _isLoadingLatest = true;
    _errorLatest = null;
    notifyListeners();

    try {
      _latestEarthquake = await _apiService.fetchLatestEarthquake();
    } catch (e) {
      _errorLatest = e.toString();
    } finally {
      _isLoadingLatest = false;
      notifyListeners();
    }
  }

  /// Memuat daftar gempa M 5.0+ (gempaterkini)
  Future<void> fetchRecent() async {
    _isLoadingRecent = true;
    _errorRecent = null;
    notifyListeners();

    try {
      _recentEarthquakes = await _apiService.fetchRecentEarthquakes();
    } catch (e) {
      _errorRecent = e.toString();
    } finally {
      _isLoadingRecent = false;
      notifyListeners();
    }
  }

  /// Memuat daftar gempa dirasakan (gempadirasakan)
  Future<void> fetchFelt() async {
    _isLoadingFelt = true;
    _errorFelt = null;
    notifyListeners();

    try {
      _feltEarthquakes = await _apiService.fetchFeltEarthquakes();
    } catch (e) {
      _errorFelt = e.toString();
    } finally {
      _isLoadingFelt = false;
      notifyListeners();
    }
  }
}
