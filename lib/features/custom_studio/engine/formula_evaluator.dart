import 'dart:math' as math;

import 'formula_ast.dart';
import 'formula_token.dart';

class MathEvaluationException implements Exception {
  const MathEvaluationException(this.message);
  final String message;

  @override
  String toString() => 'MathEvaluationException: $message';
}

/// Evaluates an AST expression given a variable lookup map.
class FormulaEvaluator implements ExprVisitor<double> {
  FormulaEvaluator(this.variables);

  /// Map of variable identifier -> numeric value
  final Map<String, double> variables;

  static double evaluate(ExprNode ast, Map<String, double> variables) {
    final evaluator = FormulaEvaluator(variables);
    return ast.accept(evaluator);
  }

  @override
  double visitNumber(NumberLiteralNode node) => node.value;

  @override
  double visitVariable(VariableNode node) {
    final val = variables[node.name];
    if (val == null) {
      throw MathEvaluationException(
          'Undeclared or missing variable "${node.name}"');
    }
    return val;
  }

  @override
  double visitUnary(UnaryOpNode node) {
    final val = node.operand.accept(this);
    if (node.op == TokenType.minus) {
      return -val;
    }
    return val;
  }

  @override
  double visitBinary(BinaryOpNode node) {
    final left = node.left.accept(this);
    final right = node.right.accept(this);

    final res = switch (node.op) {
      TokenType.plus => left + right,
      TokenType.minus => left - right,
      TokenType.star => left * right,
      TokenType.slash => () {
          if (right == 0.0) {
            throw const MathEvaluationException('Division by zero');
          }
          return left / right;
        }(),
      TokenType.caret => () {
          if (left < 0 && right != right.roundToDouble()) {
            throw MathEvaluationException(
                'Negative base $left cannot be raised to fractional power $right');
          }
          final p = math.pow(left, right).toDouble();
          return p;
        }(),
      _ => throw MathEvaluationException(
          'Unsupported binary operator: ${node.op}'),
    };

    if (!res.isFinite) {
      throw MathEvaluationException(
          'Calculation produced non-finite result: $res');
    }

    return res;
  }

  @override
  double visitFunction(FunctionCallNode node) {
    final evaluatedArgs =
        node.arguments.map((arg) => arg.accept(this)).toList();

    final res = switch (node.functionName) {
      'abs' => evaluatedArgs[0].abs(),
      'sqrt' => () {
          final arg = evaluatedArgs[0];
          if (arg < 0) {
            throw MathEvaluationException(
                'Cannot calculate square root of negative number: $arg');
          }
          return math.sqrt(arg);
        }(),
      'min' => math.min(evaluatedArgs[0], evaluatedArgs[1]),
      'max' => math.max(evaluatedArgs[0], evaluatedArgs[1]),
      'pow' => () {
          final base = evaluatedArgs[0];
          final exp = evaluatedArgs[1];
          if (base < 0 && exp != exp.roundToDouble()) {
            throw MathEvaluationException(
                'Negative base $base cannot be raised to fractional power $exp');
          }
          return math.pow(base, exp).toDouble();
        }(),
      'round' => () {
          final val = evaluatedArgs[0];
          final digits =
              evaluatedArgs.length > 1 ? evaluatedArgs[1].toInt() : 0;
          if (digits <= 0) return val.roundToDouble();
          final factor = math.pow(10, digits);
          return (val * factor).roundToDouble() / factor;
        }(),
      _ => throw MathEvaluationException(
          'Unknown function "${node.functionName}"'),
    };

    if (!res.isFinite) {
      throw MathEvaluationException(
          'Function ${node.functionName} produced non-finite result: $res');
    }

    return res;
  }

  @override
  double visitPercent(PercentNode node) {
    final val = node.expression.accept(this);
    return val / 100.0;
  }
}
