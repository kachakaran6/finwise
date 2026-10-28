import 'formula_token.dart';

/// Abstract Syntax Tree (AST) node definitions for safe mathematical formulas.
abstract class ExprNode {
  const ExprNode();
  R accept<R>(ExprVisitor<R> visitor);
  Set<String> collectVariableReferences();
}

abstract class ExprVisitor<R> {
  R visitNumber(NumberLiteralNode node);
  R visitVariable(VariableNode node);
  R visitUnary(UnaryOpNode node);
  R visitBinary(BinaryOpNode node);
  R visitFunction(FunctionCallNode node);
  R visitPercent(PercentNode node);
}

class NumberLiteralNode extends ExprNode {
  const NumberLiteralNode(this.value);
  final double value;

  @override
  R accept<R>(ExprVisitor<R> visitor) => visitor.visitNumber(this);

  @override
  Set<String> collectVariableReferences() => const {};

  @override
  String toString() => '$value';
}

class VariableNode extends ExprNode {
  const VariableNode(this.name);
  final String name;

  @override
  R accept<R>(ExprVisitor<R> visitor) => visitor.visitVariable(this);

  @override
  Set<String> collectVariableReferences() => {name};

  @override
  String toString() => name;
}

class UnaryOpNode extends ExprNode {
  const UnaryOpNode(this.op, this.operand);
  final TokenType op; // minus or plus
  final ExprNode operand;

  @override
  R accept<R>(ExprVisitor<R> visitor) => visitor.visitUnary(this);

  @override
  Set<String> collectVariableReferences() =>
      operand.collectVariableReferences();

  @override
  String toString() => '(${op == TokenType.minus ? "-" : "+"}$operand)';
}

class BinaryOpNode extends ExprNode {
  const BinaryOpNode(this.op, this.left, this.right);
  final TokenType op; // plus, minus, star, slash, caret
  final ExprNode left;
  final ExprNode right;

  @override
  R accept<R>(ExprVisitor<R> visitor) => visitor.visitBinary(this);

  @override
  Set<String> collectVariableReferences() => {
        ...left.collectVariableReferences(),
        ...right.collectVariableReferences(),
      };

  @override
  String toString() {
    final opStr = switch (op) {
      TokenType.plus => '+',
      TokenType.minus => '-',
      TokenType.star => '*',
      TokenType.slash => '/',
      TokenType.caret => '^',
      _ => '?',
    };
    return '($left $opStr $right)';
  }
}

class FunctionCallNode extends ExprNode {
  const FunctionCallNode(this.functionName, this.arguments);
  final String functionName;
  final List<ExprNode> arguments;

  @override
  R accept<R>(ExprVisitor<R> visitor) => visitor.visitFunction(this);

  @override
  Set<String> collectVariableReferences() {
    final vars = <String>{};
    for (final arg in arguments) {
      vars.addAll(arg.collectVariableReferences());
    }
    return vars;
  }

  @override
  String toString() => '$functionName(${arguments.join(", ")})';
}

class PercentNode extends ExprNode {
  const PercentNode(this.expression);
  final ExprNode expression;

  @override
  R accept<R>(ExprVisitor<R> visitor) => visitor.visitPercent(this);

  @override
  Set<String> collectVariableReferences() =>
      expression.collectVariableReferences();

  @override
  String toString() => '($expression)%';
}
