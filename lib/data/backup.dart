import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../domain/calculators/catalog.dart';
import '../domain/models/calc.dart';

class BackupException implements Exception {
  BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

class RestorePreview {
  RestorePreview(this.scenarios, this.skipped);
  final List<Scenario> scenarios;
  final int skipped;
}

/// Versioned backup. Optional AES-256-GCM encryption with a key derived from a
/// passphrase using PBKDF2-HMAC-SHA256. Nothing is ever uploaded.
class BackupService {
  static const plainFormat = 'ofc-backup';
  static const encFormat = 'ofc-backup-enc';
  static const version = 1;
  static const iterations = 150000;
  static const maxBytes = 10 * 1024 * 1024;

  static final _aes = AesGcm.with256bits();
  static final _kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);

  static Uint8List _random(int n) {
    final r = Random.secure();
    return Uint8List.fromList(List.generate(n, (_) => r.nextInt(256)));
  }

  static String _payload(List<Scenario> list) => jsonEncode({
        'format': plainFormat,
        'version': version,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'scenarios': list
            .map((s) => {
                  'id': s.id,
                  'title': s.title,
                  'calcId': s.calcId,
                  'inputs': s.inputs,
                  'snapshot': s.snapshot,
                  'schemaVersion': s.schemaVersion,
                  'createdAt': s.createdAt,
                  'updatedAt': s.updatedAt,
                })
            .toList(),
      });

  static Future<Uint8List> export(List<Scenario> list, {String? passphrase}) async {
    final plain = _payload(list);
    if (passphrase == null) return Uint8List.fromList(utf8.encode(plain));
    final salt = _random(16);
    final key = await _kdf.deriveKeyFromPassword(password: passphrase, nonce: salt);
    final box = await _aes.encrypt(utf8.encode(plain), secretKey: key);
    return Uint8List.fromList(utf8.encode(jsonEncode({
      'format': encFormat,
      'version': version,
      'kdf': 'pbkdf2-hmac-sha256',
      'iterations': iterations,
      'cipher': 'aes-256-gcm',
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'data': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    })));
  }

  static bool isEncrypted(Uint8List bytes) {
    try {
      final j = jsonDecode(utf8.decode(bytes));
      return j is Map && j['format'] == encFormat;
    } catch (_) {
      return false;
    }
  }

  static Future<RestorePreview> parse(Uint8List bytes, {String? passphrase}) async {
    if (bytes.length > maxBytes) throw BackupException('File is too large to be a valid backup.');
    late Map<String, dynamic> root;
    try {
      root = Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
    } catch (_) {
      throw BackupException('This file is not a valid backup.');
    }
    if (root['format'] == encFormat) {
      if (root['version'] != version) throw BackupException('Unsupported backup version.');
      if (passphrase == null || passphrase.isEmpty) throw BackupException('A passphrase is required.');
      try {
        final salt = base64Decode(root['salt'] as String);
        final key = await _kdf.deriveKeyFromPassword(password: passphrase, nonce: salt);
        final box = SecretBox(base64Decode(root['data'] as String), nonce: base64Decode(root['nonce'] as String), mac: Mac(base64Decode(root['mac'] as String)));
        final clear = await _aes.decrypt(box, secretKey: key);
        root = Map<String, dynamic>.from(jsonDecode(utf8.decode(clear)) as Map);
      } catch (_) {
        throw BackupException('Wrong passphrase, or the file is damaged.');
      }
    }
    if (root['format'] != plainFormat) throw BackupException('This file is not a valid backup.');
    final v = root['version'];
    if (v is! int || v > version) throw BackupException('Unsupported backup version.');
    final list = root['scenarios'];
    if (list is! List) throw BackupException('Backup contains no scenario list.');
    if (list.length > 5000) throw BackupException('Backup contains too many records.');

    final ok = <Scenario>[];
    var skipped = 0;
    for (final e in list) {
      final s = _validate(e);
      if (s == null) {
        skipped++;
      } else {
        ok.add(s);
      }
    }
    return RestorePreview(ok, skipped);
  }

  static Scenario? _validate(Object? e) {
    if (e is! Map) return null;
    final id = e['id'], title = e['title'], calcId = e['calcId'];
    final inputs = e['inputs'], snap = e['snapshot'];
    final created = e['createdAt'], updated = e['updatedAt'], sv = e['schemaVersion'];
    if (id is! String || id.isEmpty || id.length > 64) return null;
    if (title is! String || title.length > 200) return null;
    if (calcId is! String || (calcById(calcId) == null && !calcId.startsWith('custom_'))) return null;
    if (inputs is! Map || inputs.length > 40 || snap is! Map) return null;
    for (final val in inputs.values) {
      if (val is! num && val is! String) return null;
      if (val is String && val.length > 64) return null;
    }
    if (created is! int || updated is! int || sv is! int) return null;
    return Scenario(
      id: id,
      title: title,
      calcId: calcId,
      inputs: Map<String, dynamic>.from(inputs),
      snapshot: Map<String, dynamic>.from(snap),
      createdAt: created,
      updatedAt: updated,
      schemaVersion: sv,
    );
  }
}
