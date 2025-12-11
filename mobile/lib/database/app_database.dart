import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Bagian ini wajib ada agar code generator tahu di mana harus menaruh kode hasil generate
part 'app_database.g.dart';

// ==========================================================
// 1. DEFINISI TABEL (SCHEMA)
// ==========================================================
class JournalEntries extends Table {
  // ID unik untuk setiap entry, otomatis bertambah (1, 2, 3...)
  IntColumn get id => integer().autoIncrement()();
  
  // Isi jurnal user
  TextColumn get content => text()();
  
  // Skor mood (0 - 100)
  IntColumn get moodScore => integer()();
  
  // Waktu pembuatan, default ke waktu sekarang saat disimpan
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  // --- Kolom untuk Hasil Analisa AI ---
  // Kita buat nullable() artinya boleh kosong (karena saat awal disimpan, AI belum berjalan)
  TextColumn get aiSummary => text().nullable()();
  TextColumn get aiTags => text().nullable()(); 
}

// ==========================================================
// 2. CLASS DATABASE UTAMA
// ==========================================================
@DriftDatabase(tables: [JournalEntries])
class AppDatabase extends _$AppDatabase {
  // Constructor memanggil fungsi koneksi di bawah
  AppDatabase() : super(_openConnection());

  // Versi skema DB. Jika nanti kamu ubah struktur tabel, naikkan angkanya (misal jadi 2)
  @override
  int get schemaVersion => 1;

  // --- QUERY: INSERT (Simpan Jurnal Baru) ---
  // Mengembalikan ID dari baris yang baru dibuat
  Future<int> insertEntry(String text, int mood) {
    return into(journalEntries).insert(
      JournalEntriesCompanion.insert(
        content: text,
        moodScore: mood,
        // aiSummary & aiTags tidak diisi dulu (akan null)
      ),
    );
  }

  // --- QUERY: READ (Ambil Semua Data) ---
  // Mengurutkan dari yang paling baru (createdAt desc)
  Future<List<JournalEntry>> getAllEntries() {
    return (select(journalEntries)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  // --- QUERY: UPDATE (Simpan Hasil AI) ---
  // Mencari baris berdasarkan ID, lalu isi kolom aiSummary & aiTags
  Future<void> updateAiAnalysis(int id, String summary, String tags) {
    return (update(journalEntries)..where((t) => t.id.equals(id))).write(
      JournalEntriesCompanion(
        aiSummary: Value(summary),
        aiTags: Value(tags),
      ),
    );
  }
}

// ==========================================================
// 3. KONFIGURASI KONEKSI FILE (ANDROID/IOS)
// ==========================================================
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Mencari lokasi folder aman di HP untuk menyimpan file
    final dbFolder = await getApplicationDocumentsDirectory();
    
    // Membuat file database bernama 'db_mood_map.sqlite'
    final file = File(p.join(dbFolder.path, 'db_mood_map.sqlite'));
    
    return NativeDatabase.createInBackground(file);
  });
}