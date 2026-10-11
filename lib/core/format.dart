import 'package:intl/intl.dart';

import '../domain/models/calc.dart';

class CurrencyInfo {
  const CurrencyInfo(this.code, this.symbol, this.name, [this.decimals = 2]);
  final String code, symbol, name;
  final int decimals;
}

const currencies = <CurrencyInfo>[
  CurrencyInfo('INR', '₹', 'Indian Rupee'),
  CurrencyInfo('USD', r'$', 'US Dollar'),
  CurrencyInfo('EUR', '€', 'Euro'),
  CurrencyInfo('GBP', '£', 'Pound Sterling'),
  CurrencyInfo('JPY', '¥', 'Japanese Yen', 0),
  CurrencyInfo('CNY', 'CN¥', 'Chinese Yuan'),
  CurrencyInfo('AUD', r'A$', 'Australian Dollar'),
  CurrencyInfo('CAD', r'C$', 'Canadian Dollar'),
  CurrencyInfo('CHF', 'CHF ', 'Swiss Franc'),
  CurrencyInfo('SGD', r'S$', 'Singapore Dollar'),
  CurrencyInfo('AED', 'AED ', 'UAE Dirham'),
  CurrencyInfo('SAR', 'SAR ', 'Saudi Riyal'),
  CurrencyInfo('PKR', 'Rs ', 'Pakistani Rupee'),
  CurrencyInfo('BDT', '৳', 'Bangladeshi Taka'),
  CurrencyInfo('NGN', '₦', 'Nigerian Naira'),
  CurrencyInfo('ZAR', 'R ', 'South African Rand'),
  CurrencyInfo('BRL', r'R$', 'Brazilian Real'),
  CurrencyInfo('KRW', '₩', 'South Korean Won', 0),
  CurrencyInfo('NONE', '', 'No currency symbol'),
];

class NumberStyle {
  const NumberStyle(this.locale, this.label, this.example);
  final String locale, label, example;
}

const numberStyles = <NumberStyle>[
  NumberStyle('en_IN', 'South Asian grouping', '12,34,567.89'),
  NumberStyle('en_US', 'International', '1,234,567.89'),
  NumberStyle('de_DE', 'European', '1.234.567,89'),
  NumberStyle('fr_FR', 'Space separated', '1 234 567,89'),
];

CurrencyInfo currencyByCode(String code) => currencies.firstWhere((c) => c.code == code, orElse: () => currencies.first);

class Fmt {
  Fmt(this.currency, this.locale)
      : _money = NumberFormat.currency(locale: locale, symbol: currency.symbol, decimalDigits: currency.decimals),
        _plain = NumberFormat('#,##0.00', locale),
        _compact = NumberFormat.compact(locale: locale);

  final CurrencyInfo currency;
  final String locale;
  final NumberFormat _money, _plain, _compact;

  String money(double v) => _money.format(_clean(v));
  static String _pat(int dp) => dp == 0 ? '#,##0' : '#,##0.${'0' * dp}';
  String number(double v, {int dp = 2}) => NumberFormat(_pat(dp), locale).format(_clean(v));
  String percent(double v) => '${_plain.format(_clean(v))}%';
  String compact(double v) => _compact.format(v);
  String plain(double v) => _plain.format(_clean(v));

  double _clean(double v) => v.abs() < 0.000001 ? 0 : v;

  String value(ResultRow r) {
    if (r.kind == ValueKind.text || r.value == null) return r.text ?? '';
    final v = r.value!;
    if (!v.isFinite) return 'Not defined';
    switch (r.kind) {
      case ValueKind.money:
        return money(v);
      case ValueKind.percent:
        return percent(v);
      case ValueKind.years:
        return '${_plain.format(v)} yrs';
      case ValueKind.number:
        return v == v.roundToDouble() && v.abs() < 1e9 ? NumberFormat('#,##0', locale).format(v) : _plain.format(v);
      case ValueKind.text:
        return r.text ?? '';
    }
  }

  /// Compact axis label that respects the number style.
  String axis(double v) => v.abs() >= 1000 ? _compact.format(v) : NumberFormat('#,##0.##', locale).format(v);

  String scheduleCell(double v, int col, bool firstIsIndex) {
    if (col == 0 && firstIsIndex) {
      return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
    }
    return NumberFormat(_pat(currency.decimals), locale).format(_clean(v));
  }
}
