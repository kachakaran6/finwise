import '../domain/models/custom_calc_definition.dart';
import '../domain/models/custom_output_def.dart';
import '../engine/dependency_graph.dart';
import '../engine/formula_evaluator.dart';
import '../engine/formula_parser.dart';

class CustomOutputValue {
  const CustomOutputValue({
    required this.def,
    this.value,
    this.errorMessage,
  });

  final CustomOutputDef def;
  final double? value;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
}

class CustomCalcExecutionResult {
  const CustomCalcExecutionResult({
    required this.values,
    required this.errors,
    required this.outputs,
    this.primaryOutput,
    this.primaryValue,
  });

  final Map<String, double> values; // outputId -> calculated value
  final Map<String, String> errors; // outputId -> error message
  final List<CustomOutputValue> outputs;
  final CustomOutputDef? primaryOutput;
  final double? primaryValue;

  bool get hasErrors => errors.isNotEmpty;
}

/// Evaluates a CustomCalcDefinition against a map of raw user inputs.
class CustomCalculatorRuntime {
  const CustomCalculatorRuntime._();

  static CustomCalcExecutionResult compute({
    required CustomCalcDefinition definition,
    required Map<String, double> rawInputs,
  }) {
    final context = Map<String, double>.from(rawInputs);
    final calculatedValues = <String, double>{};
    final calculationErrors = <String, String>{};

    if (definition.outputs.isEmpty) {
      return const CustomCalcExecutionResult(
        values: {},
        errors: {},
        outputs: [],
      );
    }

    // Build dependency graph of formulas
    final formulaMap = {for (final o in definition.outputs) o.id: o.formula};

    List<String> evaluationOrder;
    try {
      final graph = DependencyGraph.fromFormulas(formulaMap);
      evaluationOrder = graph.getEvaluationOrder();
    } on CircularDependencyException catch (e) {
      for (final o in definition.outputs) {
        calculationErrors[o.id] =
            'Circular dependency: ${e.cyclePath.join(" → ")}';
      }
      return CustomCalcExecutionResult(
        values: const {},
        errors: calculationErrors,
        outputs: definition.outputs
            .map((o) => CustomOutputValue(
                  def: o,
                  errorMessage: calculationErrors[o.id],
                ))
            .toList(),
      );
    } catch (e) {
      for (final o in definition.outputs) {
        calculationErrors[o.id] = 'Formula syntax error: $e';
      }
      return CustomCalcExecutionResult(
        values: const {},
        errors: calculationErrors,
        outputs: definition.outputs
            .map((o) => CustomOutputValue(
                  def: o,
                  errorMessage: calculationErrors[o.id],
                ))
            .toList(),
      );
    }

    // Evaluate in topological order
    for (final outputId in evaluationOrder) {
      final outputDef =
          definition.outputs.firstWhere((o) => o.id == outputId);
      try {
        final ast = FormulaParser.parseFormula(outputDef.formula);
        final val = FormulaEvaluator.evaluate(ast, context);

        if (val.isNaN || val.isInfinite) {
          calculationErrors[outputId] = 'Result is not a finite number';
        } else {
          calculatedValues[outputId] = val;
          context[outputId] = val; // Available to subsequent formulas
        }
      } on MathEvaluationException catch (e) {
        calculationErrors[outputId] = e.message;
      } catch (e) {
        calculationErrors[outputId] = 'Calculation error: $e';
      }
    }

    final outputValues = <CustomOutputValue>[];
    for (final def in definition.outputs) {
      outputValues.add(CustomOutputValue(
        def: def,
        value: calculatedValues[def.id],
        errorMessage: calculationErrors[def.id],
      ));
    }

    final primaryDef = definition.primaryOutput;
    final primaryVal = primaryDef != null ? calculatedValues[primaryDef.id] : null;

    return CustomCalcExecutionResult(
      values: calculatedValues,
      errors: calculationErrors,
      outputs: outputValues,
      primaryOutput: primaryDef,
      primaryValue: primaryVal,
    );
  }
}
