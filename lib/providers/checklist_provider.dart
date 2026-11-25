import 'package:flutter/foundation.dart';
import '../models/checklist_item.dart';
import '../services/database_helper.dart';

/// Provider pengelola state Tas Siaga Bencana (Checklist SQLite)
class ChecklistProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper;

  ChecklistProvider({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  List<ChecklistItem> _items = [];
  bool _isLoading = false;

  List<ChecklistItem> get items => _items;
  bool get isLoading => _isLoading;

  int get totalCount => _items.length;
  int get checkedCount => _items.where((i) => i.isChecked).length;
  double get progress => totalCount == 0 ? 0.0 : checkedCount / totalCount;

  /// Memuat item checklist dari database SQLite
  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _dbHelper.getAllChecklist();
    } catch (e) {
      debugPrint('Error loading checklist: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mengubah status centang item
  Future<void> toggleItem(ChecklistItem item) async {
    if (item.id == null) return;
    final newStatus = !item.isChecked;

    try {
      await _dbHelper.updateChecklistStatus(item.id!, newStatus);
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = _items[index].copyWith(isChecked: newStatus);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating checklist status: $e');
    }
  }

  /// Reset semua centang
  Future<void> resetAll() async {
    try {
      await _dbHelper.resetChecklist();
      _items = _items.map((i) => i.copyWith(isChecked: false)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting checklist: $e');
    }
  }
}
