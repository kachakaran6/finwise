import '../../engine/dependency_graph.dart';
import '../../engine/formula_validator.dart';
import 'custom_input_def.dart';
import 'custom_output_def.dart';

/// Full definition of a user-created financial calculator.
class CustomCalcDefinition {
  const CustomCalcDefinition({
    required this.id,
    required this.name,
    this.description = '',
    this.category = 'planning',
    this.iconKey = 'calculator',
    this.schemaVersion = 1,
    this.isDraft = false,
    this.inputs = const [],
    this.outputs = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String iconKey;
  final int schemaVersion;
  final bool isDraft;
  final List<CustomInputDef> inputs;
  final List<CustomOutputDef> outputs;
  final int createdAt;
  final int updatedAt;

  CustomOutputDef? get primaryOutput =>
      outputs.firstWhere((o) => o.isPrimary, orElse: () => outputs.first);

  Set<String> get computationalInputIds =>
      inputs.where((i) => i.isComputational).map((i) => i.id).toSet();

  Set<String> get allOutputIds => outputs.map((o) => o.id).toSet();

  CustomCalcDefinition copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? iconKey,
    int? schemaVersion,
    bool? isDraft,
    List<CustomInputDef>? inputs,
    List<CustomOutputDef>? outputs,
    int? createdAt,
    int? updatedAt,
  }) =>
      CustomCalcDefinition(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        iconKey: iconKey ?? this.iconKey,
        schemaVersion: schemaVersion ?? this.schemaVersion,
        isDraft: isDraft ?? this.isDraft,
        inputs: inputs ?? this.inputs,
        outputs: outputs ?? this.outputs,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Validates the calculator definition for mathematical, dependency, and naming consistency.
  List<String> validate() {
    final errors = <String>[];

    if (name.trim().isEmpty) {
      errors.add('Calculator name cannot be empty.');
    }

    final compInputs = inputs.where((i) => i.isComputational).toList();
    if (compInputs.isEmpty) {
      errors.add(
          'At least one numeric, currency, or variable input is required.');
    }

    if (outputs.isEmpty) {
      errors.add('At least one calculated output is required.');
    }

    // Check for duplicate input IDs
    final seenInputIds = <String>{};
    for (final input in compInputs) {
      if (input.id.trim().isEmpty) {
        errors.add('Input "${input.label}" must have a valid variable ID.');
      } else if (!seenInputIds.add(input.id)) {
        errors.add('Duplicate input variable ID: "${input.id}".');
      }
    }

    // Check for duplicate output IDs
    final seenOutputIds = <String>{};
    for (final output in outputs) {
      if (output.id.trim().isEmpty) {
        errors.add('Output "${output.label}" must have a valid result ID.');
      } else if (!seenOutputIds.add(output.id)) {
        errors.add('Duplicate calculated output ID: "${output.id}".');
      } else if (seenInputIds.contains(output.id)) {
        errors
            .add('Output ID "${output.id}" clashes with an input variable ID.');
      }
    }

    // Validate formulas
    final availableVariables = {...seenInputIds, ...seenOutputIds};
    final formulas = <String, String>{};

    for (final output in outputs) {
      final res = FormulaValidator.validate(
        output.formula,
        availableVariables: availableVariables,
      );
      if (!res.isValid) {
        errors.add('Output "${output.label}": ${res.errorMessage}');
      } else {
        formulas[output.id] = output.formula;
      }
    }

    // Validate dependency ordering and detect circular references
    if (errors.isEmpty && formulas.isNotEmpty) {
      try {
        final graph = DependencyGraph.fromFormulas(formulas);
        graph.getEvaluationOrder();
      } on CircularDependencyException catch (e) {
        errors.add(
            'Circular formula dependency detected: ${e.cyclePath.join(" → ")}');
      } catch (e) {
        errors.add('Formula dependency error: $e');
      }
    }

    return errors;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'iconKey': iconKey,
        'schemaVersion': schemaVersion,
        'isDraft': isDraft,
        'inputs': inputs.map((i) => i.toJson()).toList(),
        'outputs': outputs.map((o) => o.toJson()).toList(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory CustomCalcDefinition.fromJson(Map<String, dynamic> json) =>
      CustomCalcDefinition(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Untitled Calculator',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'planning',
        iconKey: json['iconKey'] as String? ?? 'calculator',
        schemaVersion: json['schemaVersion'] as int? ?? 1,
        isDraft: json['isDraft'] as bool? ?? false,
        inputs: (json['inputs'] as List<dynamic>?)
                ?.map((e) => CustomInputDef.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        outputs: (json['outputs'] as List<dynamic>?)
                ?.map(
                    (e) => CustomOutputDef.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        createdAt:
            json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt:
            json['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      );
}
