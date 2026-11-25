import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/earthquake.dart';
import '../models/checklist_item.dart';

/// Database Helper (Singleton) untuk mengelola SQLite lokal aplikasi SiagaBumi
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Getter database dengan inisialisasi lazy
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('siagabumi.db');
    return _database!;
  }

  /// Inisialisasi file SQLite database di path sistem aplikasi
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Membuat tabel `watchlist` dan `checklist` pada saat pertama kali dibuat
  Future<void> _createDB(Database db, int version) async {
    // 1. Tabel Watchlist (Pantauan Saya)
    await db.execute('''
      CREATE TABLE watchlist (
        id TEXT PRIMARY KEY,
        tanggal TEXT NOT NULL,
        jam TEXT NOT NULL,
        datetime TEXT NOT NULL,
        coordinates TEXT NOT NULL,
        lintang TEXT NOT NULL,
        bujur TEXT NOT NULL,
        magnitude TEXT NOT NULL,
        kedalaman TEXT NOT NULL,
        wilayah TEXT NOT NULL,
        potensi TEXT,
        dirasakan TEXT,
        shakemap TEXT,
        catatan TEXT,
        saved_at TEXT NOT NULL
      )
    ''');

    // 2. Tabel Checklist (Tas Siaga Bencana)
    await db.execute('''
      CREATE TABLE checklist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item TEXT NOT NULL,
        category TEXT NOT NULL,
        is_checked INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Inisialisasi data awal (seeding) untuk checklist tas siaga bencana
    await _seedChecklist(db);
  }

  /// Data awal tas siaga bencana sesuai anjuran BNPB
  Future<void> _seedChecklist(Database db) async {
    final initialItems = [
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

    for (final item in initialItems) {
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
    final db = await instance.database;
    return await db.insert(
      'watchlist',
      earthquake.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mengambil semua gempa yang disimpan di pantauan (diurutkan paling baru disimpan)
  Future<List<Earthquake>> getAllWatchlist() async {
    final db = await instance.database;
    final result = await db.query(
      'watchlist',
      orderBy: 'saved_at DESC',
    );
    return result.map((map) => Earthquake.fromMap(map)).toList();
  }

  /// Memperbarui catatan pribadi pada gempa tertentu
  Future<int> updateWatchlistNote(String id, String newNote) async {
    final db = await instance.database;
    return await db.update(
      'watchlist',
      {'catatan': newNote},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Menghapus gempa dari pantauan berdasarkan ID
  Future<int> deleteWatchlist(String id) async {
    final db = await instance.database;
    return await db.delete(
      'watchlist',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Memeriksa apakah suatu gempa sudah tersimpan di pantauan
  Future<bool> isSaved(String id) async {
    final db = await instance.database;
    final result = await db.query(
      'watchlist',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ==========================================
  // OPERASI CRUD TABEL CHECKLIST (TAS SIAGA)
  // ==========================================

  /// Mengambil seluruh daftar checklist tas siaga bencana
  Future<List<ChecklistItem>> getAllChecklist() async {
    final db = await instance.database;
    final result = await db.query(
      'checklist',
      orderBy: 'id ASC',
    );
    return result.map((map) => ChecklistItem.fromMap(map)).toList();
  }

  /// Memperbarui status centang checklist
  Future<int> updateChecklistStatus(int id, bool isChecked) async {
    final db = await instance.database;
    return await db.update(
      'checklist',
      {'is_checked': isChecked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Reset semua centang tas siaga ke belum dicentang
  Future<int> resetChecklist() async {
    final db = await instance.database;
    return await db.update(
      'checklist',
      {'is_checked': 0},
    );
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
