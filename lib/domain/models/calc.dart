// Pure Dart. No Flutter imports.

enum FieldKind { number, choice }

enum ValueKind { money, percent, number, years, text }

enum CalcCategory {
  growth('Growth & Investing'),
  loans('Loans & Debt'),
  planning('Goals & Planning'),
  returns('Returns & Inflation'),
  utilities('Utilities');

  const CalcCategory(this.label);
  final String label;
}

class ChoiceOption {
  const ChoiceOption(this.value, this.label);
  final String value;
  final String label;
}

class FieldDef {
  const FieldDef({
    required this.id,
    required this.label,
    this.kind = FieldKind.number,
    this.hint,
    this.help,
    this.money = false,
    this.suffix,
    this.defaultValue,
    this.min,
    this.max,
    this.integer = false,
    this.required = true,
    this.options = const [],
    this.showWhenField,
    this.showWhenValue,
  });

  final String id;
  final String label;
  final FieldKind kind;
  final String? hint;
  final String? help;
  final bool money; // show currency symbol as prefix
  final String? suffix;
  final Object? defaultValue; // num or String
  final double? min;
  final double? max;
  final bool integer;
  final bool required;
  final List<ChoiceOption> options;
  final String? showWhenField;
  final String? showWhenValue;

  bool visible(Map<String, dynamic> values) =>
      showWhenField == null || values[showWhenField] == showWhenValue;

  String optionLabel(String value) {
    for (final o in options) {
      if (o.value == value) return o.label;
    }
    return value;
  }
}

class CalcInputs {
  CalcInputs(this.values);
  final Map<String, dynamic> values;
  double n(String id) => (values[id] as num).toDouble();
  double nOr(String id, double fallback) {
    final v = values[id];
    return v is num ? v.toDouble() : fallback;
  }

  String s(String id) => values[id] as String;
}

class CalcException implements Exception {
  CalcException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ResultRow {
  const ResultRow(this.label, this.value, {this.kind = ValueKind.money, this.text});
  const ResultRow.text(this.label, String this.text)
      : value = null,
        kind = ValueKind.text;

  final String label;
  final double? value;
  final ValueKind kind;
  final String? text;

  Map<String, dynamic> toJson() => {'l': label, 'v': value, 'k': kind.name, 't': text};

  static ResultRow fromJson(Map<String, dynamic> j) => ResultRow(
        j['l'] as String,
        (j['v'] as num?)?.toDouble(),
        kind: ValueKind.values.firstWhere((k) => k.name == j['k'], orElse: () => ValueKind.number),
        text: j['t'] as String?,
      );
}

class Series {
  const Series(this.name, this.xs, this.ys, {this.emphasis = true});
  final String name;
  final List<double> xs;
  final List<double> ys;
  final bool emphasis;
}

class ChartSpec {
  const ChartSpec(this.xLabel, this.series);
  final String xLabel;
  final List<Series> series;
}

class Schedule {
  const Schedule(this.columns, this.rows, {this.firstColumnIsIndex = true});
  final List<String> columns;
  final List<List<double>> rows;
  final bool firstColumnIsIndex;
}

class CalcResult {
  const CalcResult({
    required this.primary,
    this.rows = const [],
    this.assumptions = const [],
    this.chart,
    this.schedule,
  });
  final ResultRow primary;
  final List<ResultRow> rows;
  final List<String> assumptions;
  final ChartSpec? chart;
  final Schedule? schedule;

  Map<String, dynamic> toSnapshot() => {
        'primary': primary.toJson(),
        'rows': rows.map((r) => r.toJson()).toList(),
      };
}

class CalculatorDef {
  const CalculatorDef({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.summary,
    required this.explains,
    required this.formula,
    required this.fields,
    required this.compute,
    this.aliases = const [],
  });

  final String id;
  final String code; // C01..C14 from the PRD
  final String name;
  final CalcCategory category;
  final String summary;
  final String explains; // "what this calculates"
  final List<String> formula;
  final List<FieldDef> fields;
  final List<String> aliases;
  final CalcResult Function(CalcInputs) compute;
}

/// A saved scenario. Result snapshot stored alongside inputs (FR-05).
class Scenario {
  Scenario({
    required this.id,
    required this.title,
    required this.calcId,
    required this.inputs,
    required this.snapshot,
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = 1,
  });

  final String id;
  final String title;
  final String calcId;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> snapshot;
  final int createdAt;
  final int updatedAt;
  final int schemaVersion;

  Scenario copyWith({String? id, String? title, Map<String, dynamic>? inputs, Map<String, dynamic>? snapshot, int? createdAt, int? updatedAt}) =>
      Scenario(
        id: id ?? this.id,
        title: title ?? this.title,
        calcId: calcId,
        inputs: inputs ?? this.inputs,
        snapshot: snapshot ?? this.snapshot,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        schemaVersion: schemaVersion,
      );

  ResultRow get primary => ResultRow.fromJson(Map<String, dynamic>.from(snapshot['primary'] as Map));
  List<ResultRow> get rows => ((snapshot['rows'] as List?) ?? const [])
      .map((e) => ResultRow.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}
