import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const _databaseName = 'ocr_expense_tracker.db';
  static const _tableName = 'expenses';

  Future<Database>? _database;

  Future<Database> get _databaseInstance async {
    final opening = _database ??= _openDatabase();
    try {
      return await opening;
    } catch (_) {
      if (identical(_database, opening)) _database = null;
      rethrow;
    }
  }

  Future<Database> _openDatabase() async {
    final databasesDirectory = await getDatabasesPath();
    final databasePath = path.join(databasesDirectory, _databaseName);
    return openDatabase(
      databasePath,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            merchant TEXT NOT NULL,
            amount INTEGER NOT NULL,
            transaction_date TEXT NOT NULL,
            category TEXT NOT NULL,
            receipt_image_path TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertExpense(Expense expense) async {
    final database = await _databaseInstance;
    final values = expense.toMap()..remove('id');
    return database.insert(_tableName, values);
  }

  Future<List<Expense>> getExpenses() async {
    final database = await _databaseInstance;
    final rows = await database.query(
      _tableName,
      orderBy: 'transaction_date DESC, id DESC',
    );
    return rows.map(Expense.fromMap).toList(growable: false);
  }
}
