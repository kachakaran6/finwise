import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../domain/models/custom_calc_definition.dart';

class CustomCalcValidationException implements Exception {
  const CustomCalcValidationException(this.errors);
  final List<String> errors;

  @override
  String toString() => 'CustomCalcValidationException: ${errors.join(", ")}';
}

/// Offline-first repository for user-defined calculators.
class CustomCalcRepository {
  CustomCalcRepository._(this._db) : _memory = null;
  CustomCalcRepository.fromDb(Database db)
      : _db = db,
        _memory = null;
  CustomCalcRepository.inMemory([List<CustomCalcDefinition>? initial])
      : _db = null,
        _memory = initial != null
            ? List<CustomCalcDefinition>.from(initial)
            : <CustomCalcDefinition>[];

  final Database? _db;
  final List<CustomCalcDefinition>? _memory;

  static const tableName = 'custom_calculators';

  static Future<CustomCalcRepository> open(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        schema_version INTEGER NOT NULL,
        is_draft INTEGER NOT NULL,
        definition TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    return CustomCalcRepository._(db);
  }

  Map<String, Object?> _toRow(CustomCalcDefinition c) => {
        'id': c.id,
        'name': c.name,
        'description': c.description,
        'schema_version': c.schemaVersion,
        'is_draft': c.isDraft ? 1 : 0,
        'definition': jsonEncode(c.toJson()),
        'created_at': c.createdAt,
        'updated_at': c.updatedAt,
      };

  CustomCalcDefinition _fromRow(Map<String, Object?> r) {
    final defJson =
        jsonDecode(r['definition'] as String) as Map<String, dynamic>;
    return CustomCalcDefinition.fromJson(defJson);
  }

  Future<List<CustomCalcDefinition>> all({bool includeDrafts = true}) async {
    if (_memory != null) {
      final list = List<CustomCalcDefinition>.from(
        includeDrafts ? _memory : _memory.where((c) => !c.isDraft),
      );
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    }

    final where = includeDrafts ? null : 'is_draft = 0';
    final rows = await _db!.query(
      tableName,
      where: where,
      orderBy: 'updated_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<CustomCalcDefinition?> getById(String id) async {
    if (_memory != null) {
      for (final c in _memory) {
        if (c.id == id) return c;
      }
      return null;
    }

    final rows = await _db!.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<CustomCalcDefinition?> getLatestDraft() async {
    if (_memory != null) {
      final drafts = _memory.where((c) => c.isDraft).toList();
      if (drafts.isEmpty) return null;
      drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return drafts.first;
    }

    final rows = await _db!.query(
      tableName,
      where: 'is_draft = 1',
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<void> save(CustomCalcDefinition def) async {
    // If not a draft, ensure the definition is mathematically and structurally valid
    if (!def.isDraft) {
      final errors = def.validate();
      if (errors.isNotEmpty) {
        throw CustomCalcValidationException(errors);
      }
    }

    if (_memory != null) {
      _memory.removeWhere((e) => e.id == def.id);
      _memory.add(def);
      return;
    }

    await _db!.insert(
      tableName,
      _toRow(def),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    if (_memory != null) {
      _memory.removeWhere((e) => e.id == id);
      return;
    }
    await _db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<CustomCalcDefinition> duplicate(String id) async {
    final original = await getById(id);
    if (original == null) {
      throw Exception('Calculator with ID "$id" not found.');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final newId = '${original.id}_copy_${now % 10000}';
    final duplicated = original.copyWith(
      id: newId,
      name: '${original.name} (Copy)',
      createdAt: now,
      updatedAt: now,
      isDraft: false,
    );

    await save(duplicated);
    return duplicated;
  }

  /// Exports a calculator definition to a validated versioned JSON string.
  String exportToJson(CustomCalcDefinition def) {
    final exportMap = {
      'finwise_calculator_export_version': 1,
      'exported_at': DateTime.now().millisecondsSinceEpoch,
      'calculator': def.toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(exportMap);
  }

  /// Imports and validates a calculator definition from a JSON string.
  CustomCalcDefinition importFromJson(String jsonStr) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw const CustomCalcValidationException(['Invalid JSON format.']);
    }

    if (!data.containsKey('calculator')) {
      throw const CustomCalcValidationException(
          ['File does not contain a valid Finwise calculator definition.']);
    }

    final calcMap = data['calculator'] as Map<String, dynamic>;
    final def = CustomCalcDefinition.fromJson(calcMap);

    // Give imported calculator a fresh unique ID so it doesn't accidentally overwrite existing
    final now = DateTime.now().millisecondsSinceEpoch;
    final imported = def.copyWith(
      id: 'custom_${now}_${now % 1000}',
      name: '${def.name} (Imported)',
      createdAt: now,
      updatedAt: now,
      isDraft: false,
    );

    final errors = imported.validate();
    if (errors.isNotEmpty) {
      throw CustomCalcValidationException(errors);
    }

    return imported;
  }
}
