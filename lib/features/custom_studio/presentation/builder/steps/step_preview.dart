import 'package:flutter/material.dart';

import '../../../domain/models/custom_calc_definition.dart';
import '../../../runtime/custom_calculator_screen.dart';

class StepPreview extends StatelessWidget {
  const StepPreview({
    super.key,
    required this.definition,
  });

  final CustomCalcDefinition definition;

  @override
  Widget build(BuildContext context) {
    return CustomCalculatorScreen(
      definition: definition,
    );
  }
}
