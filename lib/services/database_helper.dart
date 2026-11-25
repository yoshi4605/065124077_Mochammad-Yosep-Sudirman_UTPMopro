import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/earthquake.dart';
import '../models/checklist_item.dart';

/// Database Helper (Singleton) untuk mengelola penyimpanan lokal aplikasi SiagaBumi.
/// Mendukung SQLite di Android, iOS, Windows Desktop (FFI), serta in-memory fallback untuk Web.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _ffiInitialized = false;

  // In-memory fallback agar aplikasi selalu berfungsi di platform manapun (termasuk Web)
  final List<Earthquake> _memoryWatchlist = [];
  final List<ChecklistItem> _memoryChecklist = [];
  bool _useMemoryFallback = false;

  DatabaseHelper._init() {
    _initMemoryChecklist();
  }

  /// Data awal tas siaga bencana (seeding)
  static final List<Map<String, String>> _initialChecklistData = [
    {'category': 'Dokumen & Finansial', 'item': 'Surat-surat berharga (KK, KTP, Ijazah, Polis Asuransi dlm plastik)'},
    {'category': 'Dokumen & Finansial', 'item': 'Uang tunai secukupnya untuk kebutuhan darurat'},
    {'category': 'Medis & Kesehatan', 'item': 'Kotak P3K standar (Kasa, Plester, Antiseptik, Parasetamol)'},
    {'category': 'Medis & Kesehatan', 'item': 'Obat-obatan pribadi atau resep dokter'},
    {'category': 'Medis & Kesehatan', 'item': 'Masker medis & pembersih tangan (Hand Sanitizer)'},
    {'category': 'Logistik & Konsumsi', 'item': 'Air mineral kemasan (minimal 3 hari untuk tiap anggota keluarga)'},
    {'category': 'Logistik & Konsumsi', 'item': 'Makanan siap saji & tahan lama (Biskuit, Abon, Makanan kaleng)'},
    {'category': 'Peralatan & Keamanan', 'item': 'Senter tahan air beserta baterai cadangan'},
    {'category': 'Peralatan & Keamanan', 'item': 'Peluit darurat (untuk meminta pertolongan saat tertimbun)'},
    {'category': 'Peralatan & Keamanan', 'item': 'Powerbank kapasitas penuh & kabel charger ponsel'},
    {'category': 'Peralatan & Keamanan', 'item': 'Pakaian ganti tebal, pakaian dalam, dan selimut hangat'},
    {'category': 'Peralatan & Keamanan', 'item': 'Jas hujan praktis / ponco'},
    {'category': 'Peralatan & Keamanan', 'item': 'Perlengkapan higienis (Sabun, sikat gigi, pasta gigi, tisu basah)'},
  ];

  void _initMemoryChecklist() {
    if (_memoryChecklist.isEmpty) {
      for (int i = 0; i < _initialChecklistData.length; i++) {
        _memoryChecklist.add(
          ChecklistItem(
            id: i + 1,
            item: _initialChecklistData[i]['item']!,
            category: _initialChecklistData[i]['category']!,
            isChecked: false,
          ),
        );
      }
    }
  }

  /// Inisialisasi FFI untuk Desktop (Windows / Linux / macOS).
  /// Harus dipanggil sebelum runApp() di main().
  static void initializeFfi() {
    if (_ffiInitialized) return;
    try {
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        _ffiInitialized = true;
        debugPrint('SQLite FFI initialized successfully for desktop.');
      }
    } catch (e) {
      debugPrint('initializeFfi notice: $e');
    }
  }

  /// Mengambil instance factory yang sesuai dengan platform.
  /// Selalu mengembalikan databaseFactoryFfi di desktop untuk menghindari
  /// error "databaseFactory not initialized".
  static DatabaseFactory get _dbFactory {
    if (!kIsWeb) {
      try {
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          // Pastikan FFI selalu terinisialisasi sebelum digunakan
          if (!_ffiInitialized) {
            sqfliteFfiInit();
            databaseFactory = databaseFactoryFfi;
            _ffiInitialized = true;
          }
          return databaseFactoryFfi;
        }
      } catch (_) {}
    }
    // Android / iOS menggunakan default sqflite factory
    return databaseFactory;
  }

  /// Getter database dengan inisialisasi lazy dan proteksi exception
  Future<Database?> get database async {
    if (_useMemoryFallback) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDB('siagabumi.db');
      return _database;
    } catch (e) {
      debugPrint('SQLite initialization failed, switching to memory fallback: $e');
      _useMemoryFallback = true;
      return null;
    }
  }

  /// Inisialisasi file SQLite database
  Future<Database> _initDB(String filePath) async {
    final factory = _dbFactory;
    final dbPath = await factory.getDatabasesPath();
    final path = join(dbPath, filePath);

    return await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
        onOpen: (db) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS watchlist (
              id TEXT PRIMARY KEY,
              tanggal TEXT,
              jam TEXT,
              datetime TEXT,
              coordinates TEXT,
              lintang TEXT,
              bujur TEXT,
              magnitude TEXT,
              kedalaman TEXT,
              wilayah TEXT,
              potensi TEXT,
              dirasakan TEXT,
              shakemap TEXT,
              catatan TEXT,
              saved_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS checklist (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              item TEXT NOT NULL,
              category TEXT NOT NULL,
              is_checked INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
      ),
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS watchlist (
        id TEXT PRIMARY KEY,
        tanggal TEXT,
        jam TEXT,
        datetime TEXT,
        coordinates TEXT,
        lintang TEXT,
        bujur TEXT,
        magnitude TEXT,
        kedalaman TEXT,
        wilayah TEXT,
        potensi TEXT,
        dirasakan TEXT,
        shakemap TEXT,
        catatan TEXT,
        saved_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS checklist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item TEXT NOT NULL,
        category TEXT NOT NULL,
        is_checked INTEGER NOT NULL DEFAULT 0
      )
    ''');

    for (final item in _initialChecklistData) {
      await db.insert('checklist', {
        'item': item['item'],
        'category': item['category'],
        'is_checked': 0,
      });
    }
  }

  // ==========================================
  // OPERASI CRUD TABEL WATCHLIST (PANTAUAN SAYA)
  // ==========================================

  /// Menambahkan gempa ke daftar pantauan
  Future<int> insertWatchlist(Earthquake earthquake) async {
    try {
      final db = await database;
      if (db != null) {
        return await db.insert(
          'watchlist',
          earthquake.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('SQLite insertWatchlist failed: $e');
      _useMemoryFallback = true;
    }

    // Fallback memori
    _memoryWatchlist.removeWhere((e) => e.id == earthquake.id);
    _memoryWatchlist.insert(0, earthquake);
    return 1;
  }

  /// Mengambil semua gempa yang disimpan di pantauan
  Future<List<Earthquake>> getAllWatchlist() async {
    try {
      final db = await database;
      if (db != null) {
        final result = await db.query(
          'watchlist',
          orderBy: 'saved_at DESC',
        );
        return result.map((map) => Earthquake.fromMap(map)).toList();
      }
    } catch (e) {
      debugPrint('SQLite getAllWatchlist failed: $e');
      _useMemoryFallback = true;
    }

    // Fallback memori
    return List.from(_memoryWatchlist);
  }

  /// Memperbarui catatan pribadi pada gempa tertentu
  Future<int> updateWatchlistNote(String id, String newNote) async {
    try {
      final db = await database;
      if (db != null) {
        return await db.update(
          'watchlist',
          {'catatan': newNote},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      debugPrint('SQLite updateWatchlistNote failed: $e');
      _useMemoryFallback = true;
    }

    // Fallback memori
    final index = _memoryWatchlist.indexWhere((e) => e.id == id);
    if (index != -1) {
      _memoryWatchlist[index] = _memoryWatchlist[index].copyWith(catatan: newNote);
      return 1;
    }
    return 0;
  }

  /// Menghapus gempa dari pantauan berdasarkan ID
  Future<int> deleteWatchlist(String id) async {
    try {
      final db = await database;
      if (db != null) {
        return await db.delete(
          'watchlist',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      debugPrint('SQLite deleteWatchlist failed: $e');
      _useMemoryFallback = true;
    }

    // Fallback memori
    _memoryWatchlist.removeWhere((e) => e.id == id);
    return 1;
  }

  /// Memeriksa apakah suatu gempa sudah tersimpan di pantauan
  Future<bool> isSaved(String id) async {
    try {
      final db = await database;
      if (db != null) {
        final result = await db.query(
          'watchlist',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        return result.isNotEmpty;
      }
    } catch (e) {
      debugPrint('SQLite isSaved failed: $e');
      _useMemoryFallback = true;
    }

    // Fallback memori
    return _memoryWatchlist.any((e) => e.id == id);
  }

  // ==========================================
  // OPERASI CRUD TABEL CHECKLIST (TAS SIAGA)
  // ==========================================

  /// Mengambil seluruh daftar checklist tas siaga bencana
  Future<List<ChecklistItem>> getAllChecklist() async {
    try {
      final db = await database;
      if (db != null) {
        final result = await db.query(
          'checklist',
          orderBy: 'id ASC',
        );
        return result.map((map) => ChecklistItem.fromMap(map)).toList();
      }
    } catch (e) {
      debugPrint('SQLite getAllChecklist failed: $e');
      _useMemoryFallback = true;
    }

    // Fallback memori
    return List.from(_memoryChecklist);
  }

  /// Memperbarui status centang checklist
  Future<int> updateChecklistStatus(int id, bool isChecked) async {
    try {
      final db = await database;
      if (db != null) {
        return await db.update(
          'checklist',
          {'is_checked': isChecked ? 1 : 0},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      debugPrint('SQLite updateChecklistStatus failed: $e');
      _useMemoryFallback = true;
    }

    // Fallback memori
    final index = _memoryChecklist.indexWhere((i) => i.id == id);
    if (index != -1) {
      _memoryChecklist[index] = _memoryChecklist[index].copyWith(isChecked: isChecked);
      return 1;
    }
    return 0;
  }

  /// Reset semua centang tas siaga
  Future<int> resetChecklist() async {
    try {
      final db = await database;
      if (db != null) {
        return await db.update(
          'checklist',
          {'is_checked': 0},
        );
      }
    } catch (e) {
      debugPrint('SQLite resetChecklist failed: $e');
      _useMemoryFallback = true;
    }

    // Fallback memori
    for (int i = 0; i < _memoryChecklist.length; i++) {
      _memoryChecklist[i] = _memoryChecklist[i].copyWith(isChecked: false);
    }
    return _memoryChecklist.length;
  }

  /// Menutup koneksi database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
