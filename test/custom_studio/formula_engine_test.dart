import 'package:flutter_test/flutter_test.dart';
import 'package:finwise/features/custom_studio/engine/dependency_graph.dart';
import 'package:finwise/features/custom_studio/engine/formula_evaluator.dart';
import 'package:finwise/features/custom_studio/engine/formula_parser.dart';
import 'package:finwise/features/custom_studio/engine/formula_validator.dart';

void main() {
  group('Formula Engine Parser & Evaluator Tests', () {
    double eval(String formula, [Map<String, double> vars = const {}]) {
      final ast = FormulaParser.parseFormula(formula);
      return FormulaEvaluator.evaluate(ast, vars);
    }

    test('Basic arithmetic evaluation', () {
      expect(eval('10 + 20'), 30.0);
      expect(eval('50 - 15'), 35.0);
      expect(eval('6 * 7'), 42.0);
      expect(eval('100 / 4'), 25.0);
    });

    test('Operator precedence and parentheses', () {
      expect(eval('2 + 3 * 4'), 14.0);
      expect(eval('(2 + 3) * 4'), 20.0);
      expect(eval('100 - 20 / 4'), 95.0);
      expect(eval('(100 - 20) / 4'), 20.0);
    });

    test('Exponentiation and right-associativity', () {
      expect(eval('2 ^ 3'), 8.0);
      expect(eval('2 ^ 3 ^ 2'), 512.0); // 2 ^ (3 ^ 2) = 2 ^ 9 = 512
      expect(eval('(2 ^ 3) ^ 2'), 64.0);
    });

    test('Unary negative numbers and double negation', () {
      expect(eval('-10 + 25'), 15.0);
      expect(eval('-(10 + 15)'), -25.0);
      expect(eval('-(-50)'), 50.0);
    });

    test('Percentage postfix operator', () {
      expect(eval('8%'), 0.08);
      expect(eval('1000 * 8%'), 80.0);
      expect(eval('500 + 500 * 10%'), 550.0);
    });

    test('Variable resolution and multi-variable financial math', () {
      final vars = {
        'principal': 10000.0,
        'rate': 8.0,
        'years': 5.0,
      };
      // Compound interest formula: P * (1 + r / 100) ^ t
      final res = eval('principal * (1 + rate / 100) ^ years', vars);
      // 10000 * 1.08^5 = 14693.280768
      expect(res, closeTo(14693.28, 0.01));
    });

    test('Mathematical functions (abs, sqrt, min, max, round, pow)', () {
      expect(eval('abs(-42)'), 42.0);
      expect(eval('sqrt(144)'), 12.0);
      expect(eval('min(15, 25)'), 15.0);
      expect(eval('max(15, 25)'), 25.0);
      expect(eval('round(12.3456, 2)'), 12.35);
      expect(eval('round(12.3456)'), 12.0);
      expect(eval('pow(2, 5)'), 32.0);
    });

    test('Division by zero throws MathEvaluationException', () {
      expect(
        () => eval('100 / 0'),
        throwsA(isA<MathEvaluationException>().having(
          (e) => e.message,
          'message',
          contains('Division by zero'),
        )),
      );
    });

    test('Square root of negative number throws MathEvaluationException', () {
      expect(
        () => eval('sqrt(-9)'),
        throwsA(isA<MathEvaluationException>().having(
          (e) => e.message,
          'message',
          contains('negative number'),
        )),
      );
    });

    test('Missing variable throws MathEvaluationException', () {
      expect(
        () => eval('revenue - expenses', {'revenue': 5000}),
        throwsA(isA<MathEvaluationException>().having(
          (e) => e.message,
          'message',
          contains('expenses'),
        )),
      );
    });
  });

  group('FormulaValidator Tests', () {
    test('Validates clean formula with known variables', () {
      final res = FormulaValidator.validate(
        'monthly_revenue - operating_costs',
        availableVariables: {'monthly_revenue', 'operating_costs'},
      );
      expect(res.isValid, isTrue);
      expect(res.errorMessage, isNull);
      expect(res.referencedVariables, {'monthly_revenue', 'operating_costs'});
    });

    test('Detects unknown variables and explains clearly', () {
      final res = FormulaValidator.validate(
        'monthly_revenue - tax_amount',
        availableVariables: {'monthly_revenue'},
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('"tax_amount"'));
    });

    test('Catches unclosed parentheses', () {
      final res = FormulaValidator.validate(
        '(10 + 20 * 5',
        availableVariables: const {},
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('Expected ")"'));
    });

    test('Catches invalid syntax like trailing operators', () {
      final res = FormulaValidator.validate(
        '10 + * 5',
        availableVariables: const {},
      );
      expect(res.isValid, isFalse);
    });
  });

  group('DependencyGraph & Cycle Detection Tests', () {
    test('Correctly orders linear and multi-step dependencies', () {
      final formulas = {
        'net_profit': 'gross_profit - estimated_tax',
        'gross_profit': 'revenue - expenses',
        'estimated_tax': 'gross_profit * 20%',
      };
      final graph = DependencyGraph.fromFormulas(formulas);
      final order = graph.getEvaluationOrder();

      // gross_profit must come before estimated_tax and net_profit
      expect(order.indexOf('gross_profit'),
          lessThan(order.indexOf('estimated_tax')));
      expect(
          order.indexOf('gross_profit'), lessThan(order.indexOf('net_profit')));
      expect(order.indexOf('estimated_tax'),
          lessThan(order.indexOf('net_profit')));
    });

    test('Detects direct circular dependency (A -> B -> A)', () {
      final formulas = {
        'profit': 'margin * 2',
        'margin': 'profit / 10',
      };
      final graph = DependencyGraph.fromFormulas(formulas);
      expect(
        () => graph.getEvaluationOrder(),
        throwsA(isA<CircularDependencyException>().having(
          (e) => e.cyclePath,
          'cyclePath',
          containsAll(['profit', 'margin']),
        )),
      );
    });

    test('Detects indirect circular dependency (A -> B -> C -> A)', () {
      final formulas = {
        'a': 'b + 1',
        'b': 'c + 2',
        'c': 'a + 3',
      };
      final graph = DependencyGraph.fromFormulas(formulas);
      expect(
        () => graph.getEvaluationOrder(),
        throwsA(isA<CircularDependencyException>()),
      );
    });
  });
}
