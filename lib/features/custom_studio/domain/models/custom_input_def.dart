/// Represents the variety of input widgets supported by Custom Calculator Studio.
enum CustomInputType {
  number,
  currency,
  percentage,
  duration,
  dropdown,
  toggle,
  slider,
  date,
  infoBlock,
  sectionHeader;

  bool get isComputational =>
      this != CustomInputType.infoBlock &&
      this != CustomInputType.sectionHeader;
}

class CustomChoiceOption {
  const CustomChoiceOption({required this.value, required this.label});
  final String value;
  final String label;

  Map<String, dynamic> toJson() => {'value': value, 'label': label};

  factory CustomChoiceOption.fromJson(Map<String, dynamic> json) =>
      CustomChoiceOption(
        value: json['value'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );
}

/// Model defining a custom calculator input widget.
class CustomInputDef {
  const CustomInputDef({
    required this.id,
    required this.label,
    required this.type,
    this.description,
    this.defaultValue = 0.0,
    this.min,
    this.max,
    this.step = 1.0,
    this.suffix,
    this.prefix,
    this.required = true,
    this.options = const [],
    this.durationUnit = 'years',
    this.infoText,
  });

  final String id;
  final String label;
  final CustomInputType type;
  final String? description;
  final double? defaultValue;
  final double? min;
  final double? max;
  final double? step;
  final String? suffix;
  final String? prefix;
  final bool required;
  final List<CustomChoiceOption> options;
  final String durationUnit; // 'days', 'months', 'years'
  final String? infoText;

  bool get isComputational =>
      type != CustomInputType.infoBlock &&
      type != CustomInputType.sectionHeader;

  CustomInputDef copyWith({
    String? id,
    String? label,
    CustomInputType? type,
    String? description,
    double? defaultValue,
    double? min,
    double? max,
    double? step,
    String? suffix,
    String? prefix,
    bool? required,
    List<CustomChoiceOption>? options,
    String? durationUnit,
    String? infoText,
  }) =>
      CustomInputDef(
        id: id ?? this.id,
        label: label ?? this.label,
        type: type ?? this.type,
        description: description ?? this.description,
        defaultValue: defaultValue ?? this.defaultValue,
        min: min ?? this.min,
        max: max ?? this.max,
        step: step ?? this.step,
        suffix: suffix ?? this.suffix,
        prefix: prefix ?? this.prefix,
        required: required ?? this.required,
        options: options ?? this.options,
        durationUnit: durationUnit ?? this.durationUnit,
        infoText: infoText ?? this.infoText,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type.name,
        if (description != null) 'description': description,
        'defaultValue': defaultValue,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
        'step': step,
        if (suffix != null) 'suffix': suffix,
        if (prefix != null) 'prefix': prefix,
        'required': required,
        if (options.isNotEmpty)
          'options': options.map((o) => o.toJson()).toList(),
        'durationUnit': durationUnit,
        if (infoText != null) 'infoText': infoText,
      };

  factory CustomInputDef.fromJson(Map<String, dynamic> json) => CustomInputDef(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        type: CustomInputType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => CustomInputType.number,
        ),
        description: json['description'] as String?,
        defaultValue: (json['defaultValue'] as num?)?.toDouble() ?? 0.0,
        min: (json['min'] as num?)?.toDouble(),
        max: (json['max'] as num?)?.toDouble(),
        step: (json['step'] as num?)?.toDouble() ?? 1.0,
        suffix: json['suffix'] as String?,
        prefix: json['prefix'] as String?,
        required: json['required'] as bool? ?? true,
        options: (json['options'] as List<dynamic>?)
                ?.map((e) =>
                    CustomChoiceOption.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        durationUnit: json['durationUnit'] as String? ?? 'years',
        infoText: json['infoText'] as String?,
      );
}
