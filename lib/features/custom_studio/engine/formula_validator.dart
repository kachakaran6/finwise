import 'formula_ast.dart';
import 'formula_evaluator.dart';
import 'formula_parser.dart';
import 'formula_token.dart';

class FormulaValidationResult {
  const FormulaValidationResult({
    required this.isValid,
    this.errorMessage,
    this.referencedVariables = const {},
    this.ast,
  });

  final bool isValid;
  final String? errorMessage;
  final Set<String> referencedVariables;
  final ExprNode? ast;
}

class FormulaValidator {
  const FormulaValidator._();

  /// Validates a formula string against a set of known available variables.
  static FormulaValidationResult validate(
    String formula, {
    required Set<String> availableVariables,
  }) {
    final trimmed = formula.trim();
    if (trimmed.isEmpty) {
      return const FormulaValidationResult(
        isValid: false,
        errorMessage: 'Formula cannot be empty.',
      );
    }

    if (trimmed.length > 500) {
      return const FormulaValidationResult(
        isValid: false,
        errorMessage: 'Formula exceeds maximum length of 500 characters.',
      );
    }

    try {
      final ast = FormulaParser.parseFormula(trimmed);
      final refs = ast.collectVariableReferences();

      final unknownVars = refs.difference(availableVariables);
      if (unknownVars.isNotEmpty) {
        final unknownList = unknownVars.map((v) => '"$v"').join(', ');
        return FormulaValidationResult(
          isValid: false,
          errorMessage:
              'Unknown variable(s): $unknownList. Add these inputs or select from existing variables.',
          referencedVariables: refs,
          ast: ast,
        );
      }

      return FormulaValidationResult(
        isValid: true,
        referencedVariables: refs,
        ast: ast,
      );
    } on LexerException catch (e) {
      return FormulaValidationResult(
        isValid: false,
        errorMessage: 'Syntax error: ${e.message}',
      );
    } on ParseException catch (e) {
      return FormulaValidationResult(
        isValid: false,
        errorMessage: 'Grammar error: ${e.message}',
      );
    } catch (e) {
      return FormulaValidationResult(
        isValid: false,
        errorMessage: 'Invalid formula: $e',
      );
    }
  }

  /// Evaluates an AST with sample values (e.g. 1.0 for each variable) to verify runtime math safety.
  static String? testEvaluateWithSampleValues(
    ExprNode ast,
    Set<String> variables,
  ) {
    try {
      final sampleValues = {for (final v in variables) v: 10.0};
      final res = FormulaEvaluator.evaluate(ast, sampleValues);
      if (!res.isFinite) {
        return 'Calculation resulted in non-finite value ($res)';
      }
      return null;
    } on MathEvaluationException catch (e) {
      return e.message;
    } catch (e) {
      return 'Evaluation error: $e';
    }
  }
}
