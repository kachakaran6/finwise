import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/models/calc.dart';

/// Local-first scenario storage (SQLite). Works fully offline.
class ScenarioRepository {
  ScenarioRepository._(this._db) : _memory = null;
  ScenarioRepository.inMemory([List<Scenario>? initial])
      : _db = null,
        _memory = initial != null ? List<Scenario>.from(initial) : <Scenario>[];

  final Database? _db;
  final List<Scenario>? _memory;

  static Future<ScenarioRepository> open() async {
    final path = p.join(await getDatabasesPath(), 'finance_calculator.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) => db.execute('''
        CREATE TABLE scenarios(
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          calc_id TEXT NOT NULL,
          inputs TEXT NOT NULL,
          snapshot TEXT NOT NULL,
          schema_version INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )'''),
    );
    return ScenarioRepository._(db);
  }

  Map<String, Object?> _toRow(Scenario s) => {
        'id': s.id,
        'title': s.title,
        'calc_id': s.calcId,
        'inputs': jsonEncode(s.inputs),
        'snapshot': jsonEncode(s.snapshot),
        'schema_version': s.schemaVersion,
        'created_at': s.createdAt,
        'updated_at': s.updatedAt,
      };

  Scenario _fromRow(Map<String, Object?> r) => Scenario(
        id: r['id'] as String,
        title: r['title'] as String,
        calcId: r['calc_id'] as String,
        inputs: Map<String, dynamic>.from(jsonDecode(r['inputs'] as String) as Map),
        snapshot: Map<String, dynamic>.from(jsonDecode(r['snapshot'] as String) as Map),
        schemaVersion: r['schema_version'] as int,
        createdAt: r['created_at'] as int,
        updatedAt: r['updated_at'] as int,
      );

  Future<List<Scenario>> all() async {
    if (_memory != null) {
      final list = List<Scenario>.from(_memory);
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    }
    final rows = await _db!.query('scenarios', orderBy: 'updated_at DESC');
    return rows.map(_fromRow).toList();
  }

  Future<void> upsert(Scenario s) async {
    if (_memory != null) {
      _memory.removeWhere((e) => e.id == s.id);
      _memory.add(s);
      return;
    }
    await _db!.insert('scenarios', _toRow(s), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertAll(List<Scenario> list) async {
    if (_memory != null) {
      for (final s in list) {
        _memory.removeWhere((e) => e.id == s.id);
        _memory.add(s);
      }
      return;
    }
    final batch = _db!.batch();
    for (final s in list) {
      batch.insert('scenarios', _toRow(s), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(String id) async {
    if (_memory != null) {
      _memory.removeWhere((e) => e.id == id);
      return;
    }
    await _db!.delete('scenarios', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    if (_memory != null) {
      _memory.clear();
      return;
    }
    await _db!.delete('scenarios');
  }
}
