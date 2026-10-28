import 'formula_ast.dart';
import 'formula_token.dart';

class ParseException implements Exception {
  const ParseException(this.message, [this.token]);
  final String message;
  final Token? token;

  @override
  String toString() => token != null
      ? 'ParseException: $message at "${token!.lexeme}"'
      : 'ParseException: $message';
}

/// Recursive descent parser for safe mathematical formulas.
class FormulaParser {
  FormulaParser(this.tokens);
  final List<Token> tokens;
  int _current = 0;

  static const supportedFunctions = {
    'abs',
    'sqrt',
    'min',
    'max',
    'round',
    'pow',
  };

  static ExprNode parseFormula(String source) {
    final lexer = FormulaLexer(source);
    final tokens = lexer.tokenize();
    final parser = FormulaParser(tokens);
    return parser.parse();
  }

  ExprNode parse() {
    if (_isAtEnd) {
      throw const ParseException('Formula expression cannot be empty');
    }
    final expr = _expression();
    if (!_isAtEnd) {
      throw ParseException('Unexpected extra token after expression', _peek);
    }
    return expr;
  }

  // Precedence level 1: Addition & Subtraction (+, -)
  ExprNode _expression() {
    var expr = _multiplicative();

    while (_matchAny([TokenType.plus, TokenType.minus])) {
      final op = _previous.type;
      final right = _multiplicative();
      expr = BinaryOpNode(op, expr, right);
    }

    return expr;
  }

  // Precedence level 2: Multiplication & Division (*, /)
  ExprNode _multiplicative() {
    var expr = _power();

    while (_matchAny([TokenType.star, TokenType.slash])) {
      final op = _previous.type;
      final right = _power();
      expr = BinaryOpNode(op, expr, right);
    }

    return expr;
  }

  // Precedence level 3: Exponentiation (^) - right-associative
  ExprNode _power() {
    final expr = _unary();

    if (_match(TokenType.caret)) {
      final op = _previous.type;
      final right = _power(); // recursive call for right associativity
      return BinaryOpNode(op, expr, right);
    }

    return expr;
  }

  // Precedence level 4: Unary operators (-x, +x)
  ExprNode _unary() {
    if (_matchAny([TokenType.minus, TokenType.plus])) {
      final op = _previous.type;
      final operand = _unary();
      return UnaryOpNode(op, operand);
    }

    return _postfixPercent();
  }

  // Postfix percent: e.g. 8% or (revenue - costs)%
  ExprNode _postfixPercent() {
    var expr = _primary();

    while (_match(TokenType.percent)) {
      expr = PercentNode(expr);
    }

    return expr;
  }

  // Primary: numbers, parentheses, variables, and function calls
  ExprNode _primary() {
    if (_match(TokenType.number)) {
      return NumberLiteralNode(
          _previous.value ?? double.parse(_previous.lexeme));
    }

    if (_match(TokenType.identifier)) {
      final name = _previous.lexeme;

      // Check if it's a function call e.g. sqrt(x)
      if (_match(TokenType.lparen)) {
        final lowerName = name.toLowerCase();
        if (!supportedFunctions.contains(lowerName)) {
          throw ParseException('Unknown function "$name"', _previous);
        }

        final args = <ExprNode>[];
        if (!_check(TokenType.rparen)) {
          do {
            args.add(_expression());
          } while (_match(TokenType.comma));
        }

        _consume(TokenType.rparen, 'Expected ")" after function arguments');

        _validateFunctionArgs(lowerName, args);
        return FunctionCallNode(lowerName, args);
      }

      return VariableNode(name);
    }

    if (_match(TokenType.lparen)) {
      final expr = _expression();
      _consume(
          TokenType.rparen, 'Expected ")" to close parenthesized expression');
      return expr;
    }

    if (_isAtEnd) {
      throw const ParseException('Unexpected end of formula');
    }

    throw ParseException('Expected number, variable, or "("', _peek);
  }

  void _validateFunctionArgs(String functionName, List<ExprNode> args) {
    switch (functionName) {
      case 'abs':
      case 'sqrt':
        if (args.length != 1) {
          throw ParseException(
              'Function "$functionName" requires exactly 1 argument, but received ${args.length}');
        }
        break;
      case 'min':
      case 'max':
      case 'pow':
        if (args.length != 2) {
          throw ParseException(
              'Function "$functionName" requires exactly 2 arguments, but received ${args.length}');
        }
        break;
      case 'round':
        if (args.isEmpty || args.length > 2) {
          throw ParseException(
              'Function "round" requires 1 or 2 arguments: round(value, [digits])');
        }
        break;
    }
  }

  bool _match(TokenType type) {
    if (_check(type)) {
      _advance();
      return true;
    }
    return false;
  }

  bool _matchAny(List<TokenType> types) {
    for (final t in types) {
      if (_check(t)) {
        _advance();
        return true;
      }
    }
    return false;
  }

  bool _check(TokenType type) {
    if (_isAtEnd) return false;
    return _peek.type == type;
  }

  Token _advance() {
    if (!_isAtEnd) _current++;
    return _previous;
  }

  bool get _isAtEnd => _peek.type == TokenType.eof;
  Token get _peek => tokens[_current];
  Token get _previous => tokens[_current - 1];

  Token _consume(TokenType type, String message) {
    if (_check(type)) return _advance();
    throw ParseException(message, _peek);
  }
}
