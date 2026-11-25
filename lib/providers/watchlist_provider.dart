import 'package:flutter/foundation.dart';
import '../models/earthquake.dart';
import '../services/database_helper.dart';

/// Provider pengelola state Pantauan Saya (Local Storage SQLite)
class WatchlistProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;

  WatchlistProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  List<Earthquake> _watchlist = [];
  final Set<String> _savedIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<Earthquake> get watchlist => _watchlist;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Memeriksa apakah gempa sudah ada di daftar pantauan
  bool isSaved(String id) => _savedIds.contains(id);

  /// Memuat seluruh data pantauan dari SQLite
  Future<void> loadWatchlist() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _watchlist = await _dbHelper.getAllWatchlist();
      _savedIds
        ..clear()
        ..addAll(_watchlist.map((e) => e.id));
    } catch (e) {
      _errorMessage = 'Gagal memuat pantauan lokal: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menambahkan gempa ke pantauan lokal
  Future<bool> addToWatchlist(Earthquake earthquake, {String? catatan}) async {
    try {
      final toSave = earthquake.copyWith(
        catatan: catatan ?? earthquake.catatan ?? '',
        savedAt: DateTime.now().toIso8601String(),
      );

      await _dbHelper.insertWatchlist(toSave);
      _savedIds.add(toSave.id);
      // Sisipkan di posisi paling awal
      _watchlist.removeWhere((e) => e.id == toSave.id);
      _watchlist.insert(0, toSave);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan ke pantauan: $e';
      notifyListeners();
      return false;
    }
  }

  /// Memperbarui catatan pribadi pada item pantauan
  Future<bool> updateNote(String id, String newNote) async {
    try {
      await _dbHelper.updateWatchlistNote(id, newNote);
      final index = _watchlist.indexWhere((e) => e.id == id);
      if (index != -1) {
        _watchlist[index] = _watchlist[index].copyWith(catatan: newNote);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui catatan: $e';
      notifyListeners();
      return false;
    }
  }

  /// Menghapus gempa dari pantauan lokal (mengembalikan data yang dihapus untuk undo)
  Future<Earthquake?> removeFromWatchlist(String id) async {
    try {
      final index = _watchlist.indexWhere((e) => e.id == id);
      Earthquake? removedItem;
      if (index != -1) {
        removedItem = _watchlist[index];
      }

      await _dbHelper.deleteWatchlist(id);
      _savedIds.remove(id);
      _watchlist.removeWhere((e) => e.id == id);
      notifyListeners();

      return removedItem;
    } catch (e) {
      _errorMessage = 'Gagal menghapus dari pantauan: $e';
      notifyListeners();
      return null;
    }
  }
}
