/// Formatting kind for calculated outputs.
enum CustomOutputKind {
  currency,
  percentage,
  number,
}

/// Model defining a calculated output result in Custom Calculator Studio.
class CustomOutputDef {
  const CustomOutputDef({
    required this.id,
    required this.label,
    required this.formula,
    this.formulaExplanation,
    this.isPrimary = false,
    this.kind = CustomOutputKind.currency,
    this.decimalPlaces = 2,
    this.prefix,
    this.suffix,
  });

  final String id;
  final String label;
  final String formula;
  final String? formulaExplanation;
  final bool isPrimary;
  final CustomOutputKind kind;
  final int decimalPlaces;
  final String? prefix;
  final String? suffix;

  CustomOutputDef copyWith({
    String? id,
    String? label,
    String? formula,
    String? formulaExplanation,
    bool? isPrimary,
    CustomOutputKind? kind,
    int? decimalPlaces,
    String? prefix,
    String? suffix,
  }) =>
      CustomOutputDef(
        id: id ?? this.id,
        label: label ?? this.label,
        formula: formula ?? this.formula,
        formulaExplanation: formulaExplanation ?? this.formulaExplanation,
        isPrimary: isPrimary ?? this.isPrimary,
        kind: kind ?? this.kind,
        decimalPlaces: decimalPlaces ?? this.decimalPlaces,
        prefix: prefix ?? this.prefix,
        suffix: suffix ?? this.suffix,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'formula': formula,
        if (formulaExplanation != null)
          'formulaExplanation': formulaExplanation,
        'isPrimary': isPrimary,
        'kind': kind.name,
        'decimalPlaces': decimalPlaces,
        if (prefix != null) 'prefix': prefix,
        if (suffix != null) 'suffix': suffix,
      };

  factory CustomOutputDef.fromJson(Map<String, dynamic> json) =>
      CustomOutputDef(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        formula: json['formula'] as String? ?? '',
        formulaExplanation: json['formulaExplanation'] as String?,
        isPrimary: json['isPrimary'] as bool? ?? false,
        kind: CustomOutputKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => CustomOutputKind.currency,
        ),
        decimalPlaces: json['decimalPlaces'] as int? ?? 2,
        prefix: json['prefix'] as String?,
        suffix: json['suffix'] as String?,
      );
}
