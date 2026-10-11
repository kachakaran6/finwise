import '../domain/models/calc.dart';

/// Parsed form state. Never replaces invalid values with zero (FR-02).
class InputState {
  InputState(this.values, this.errors);
  final Map<String, dynamic> values; // parsed values for visible, valid fields
  final Map<String, String> errors; // fieldId -> message
  bool get valid => errors.isEmpty;
}

InputState validateInputs(CalculatorDef def, Map<String, String> raw, Map<String, String> choices) {
  final values = <String, dynamic>{};
  final errors = <String, String>{};
  // Choices first so that visibility rules can be evaluated.
  for (final f in def.fields) {
    if (f.kind == FieldKind.choice) values[f.id] = choices[f.id] ?? f.defaultValue;
  }
  for (final f in def.fields) {
    if (f.kind != FieldKind.number || !f.visible(values)) continue;
    final text = (raw[f.id] ?? '').trim();
    if (text.isEmpty) {
      if (f.required) {
        errors[f.id] = 'Required';
      } else {
        values[f.id] = 0.0;
      }
      continue;
    }
    final v = double.tryParse(text);
    if (v == null || !v.isFinite) {
      errors[f.id] = 'Enter a valid number';
      continue;
    }
    if (f.min != null && v < f.min!) {
      errors[f.id] = 'Must be at least ${_n(f.min!)}';
    } else if (f.max != null && v > f.max!) {
      errors[f.id] = 'Must be at most ${_n(f.max!)}';
    } else if (f.integer && v != v.roundToDouble()) {
      errors[f.id] = 'Enter a whole number';
    } else {
      values[f.id] = v;
    }
  }
  return InputState(values, errors);
}

String _n(double v) => v.abs() >= 1e9 ? v.toStringAsExponential(0) : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());
