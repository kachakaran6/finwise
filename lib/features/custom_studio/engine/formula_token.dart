/// Token definitions and Lexer for the safe formula engine.
enum TokenType {
  number,
  identifier,
  plus,
  minus,
  star,
  slash,
  caret,
  percent,
  lparen,
  rparen,
  comma,
  eof,
}

class Token {
  const Token(this.type, this.lexeme, [this.value]);
  final TokenType type;
  final String lexeme;
  final double? value;

  @override
  String toString() => 'Token($type, "$lexeme", $value)';
}

class LexerException implements Exception {
  const LexerException(this.message, this.position);
  final String message;
  final int position;

  @override
  String toString() => 'LexerException at index $position: $message';
}

class FormulaLexer {
  FormulaLexer(this.source);
  final String source;
  int _cursor = 0;

  List<Token> tokenize() {
    final tokens = <Token>[];
    while (_cursor < source.length) {
      final ch = source[_cursor];

      if (_isWhitespace(ch)) {
        _cursor++;
        continue;
      }

      switch (ch) {
        case '+':
          tokens.add(Token(TokenType.plus, ch));
          _cursor++;
          break;
        case '-':
          tokens.add(Token(TokenType.minus, ch));
          _cursor++;
          break;
        case '*':
          tokens.add(Token(TokenType.star, ch));
          _cursor++;
          break;
        case '/':
          tokens.add(Token(TokenType.slash, ch));
          _cursor++;
          break;
        case '^':
          tokens.add(Token(TokenType.caret, ch));
          _cursor++;
          break;
        case '%':
          tokens.add(Token(TokenType.percent, ch));
          _cursor++;
          break;
        case '(':
          tokens.add(Token(TokenType.lparen, ch));
          _cursor++;
          break;
        case ')':
          tokens.add(Token(TokenType.rparen, ch));
          _cursor++;
          break;
        case ',':
          tokens.add(Token(TokenType.comma, ch));
          _cursor++;
          break;
        default:
          if (_isDigit(ch) ||
              (ch == '.' &&
                  _cursor + 1 < source.length &&
                  _isDigit(source[_cursor + 1]))) {
            tokens.add(_readNumber());
          } else if (_isAlpha(ch)) {
            tokens.add(_readIdentifier());
          } else {
            throw LexerException('Unexpected character "$ch"', _cursor);
          }
      }
    }
    tokens.add(const Token(TokenType.eof, ''));
    return tokens;
  }

  Token _readNumber() {
    final start = _cursor;
    var hasDecimal = false;

    while (_cursor < source.length) {
      final c = source[_cursor];
      if (_isDigit(c)) {
        _cursor++;
      } else if (c == '.' && !hasDecimal) {
        hasDecimal = true;
        _cursor++;
      } else {
        break;
      }
    }

    final raw = source.substring(start, _cursor);
    final val = double.tryParse(raw);
    if (val == null) {
      throw LexerException('Invalid number "$raw"', start);
    }
    return Token(TokenType.number, raw, val);
  }

  Token _readIdentifier() {
    final start = _cursor;
    while (_cursor < source.length) {
      final c = source[_cursor];
      if (_isAlpha(c) || _isDigit(c) || c == '_') {
        _cursor++;
      } else {
        break;
      }
    }
    final raw = source.substring(start, _cursor);
    return Token(TokenType.identifier, raw);
  }

  static bool _isWhitespace(String ch) =>
      ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n';

  static bool _isDigit(String ch) =>
      ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;

  static bool _isAlpha(String ch) {
    final code = ch.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        ch == '_';
  }
}
