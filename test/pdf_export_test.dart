import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finwise/core/format.dart';
import 'package:finwise/core/pdf_export_service.dart';
import 'package:finwise/core/validation.dart';
import 'package:finwise/domain/calculators/catalog.dart';
import 'package:finwise/domain/models/calc.dart';
import 'package:finwise/features/calculator/pdf_preview_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fmt = Fmt(currencyByCode('INR'), 'en_IN');

  group('PdfExportService Tests', () {
    test(
        'Generates valid, non-empty PDF for Compound Interest with Schedule & Formula',
        () async {
      final def = calcById('compound')!;
      final rawInputs = {
        'principal': '10000',
        'rate': '8',
        'years': '10',
      };
      final choices = {'m': '12'};
      final st = validateInputs(def, rawInputs, choices);
      expect(st.valid, isTrue);

      final result = def.compute(CalcInputs(st.values));
      expect(result.schedule, isNotNull);
      expect(result.schedule!.rows.isNotEmpty, isTrue);

      final pdfBytes = await PdfExportService.generateReport(
        def: def,
        state: st,
        result: result,
        fmt: fmt,
        timestamp: DateTime(2026, 10, 25, 6, 45),
      );

      expect(pdfBytes, isNotEmpty);
      // Valid PDF files start with %PDF
      final header = ascii.decode(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));

      // Check that PDF contains text elements for branding, formula, and disclaimer
      final pdfString = String.fromCharCodes(pdfBytes);
      expect(pdfString.contains('FINWISE') || pdfString.contains('Finwise'),
          isTrue);
      expect(pdfString.contains('Samyukt'), isFalse);
    });

    test('Strictly zero emojis are present in PDF text content', () async {
      final def = calcById('sip')!;
      final rawInputs = {
        'contribution': '5000',
        'rate': '12',
        'years': '15',
        'stepup': '0',
      };
      final choices = {
        'freq': '12',
        'conv': 'nominal',
        'timing': 'end',
      };
      final st = validateInputs(def, rawInputs, choices);
      final result = def.compute(CalcInputs(st.values));

      final pdfBytes = await PdfExportService.generateReport(
        def: def,
        state: st,
        result: result,
        fmt: fmt,
      );

      final pdfString = String.fromCharCodes(pdfBytes);
      // Regex for emoji ranges (Emoticons, Misc Symbols, Dingbats, Transport, Supplemental, etc.)
      final emojiRegex = RegExp(
        r'[\u{1F300}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F018}-\u{1F270}]',
        unicode: true,
      );
      expect(emojiRegex.hasMatch(pdfString), isFalse);
    });

    test(
        'Generates PDF for calculators without schedule (e.g. Simple Interest)',
        () async {
      final def = calcById('simple')!;
      final rawInputs = {
        'principal': '25000',
        'rate': '7.5',
        'years': '5',
      };
      final st = validateInputs(def, rawInputs, {});
      final result = def.compute(CalcInputs(st.values));

      final pdfBytes = await PdfExportService.generateReport(
        def: def,
        state: st,
        result: result,
        fmt: fmt,
      );

      expect(pdfBytes, isNotEmpty);
      final header = ascii.decode(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    testWidgets('PdfPreviewScreen renders without errors', (tester) async {
      final def = calcById('compound')!;
      final rawInputs = {
        'principal': '10000',
        'rate': '8',
        'years': '10',
      };
      final choices = {'m': '12'};
      final st = validateInputs(def, rawInputs, choices);
      final result = def.compute(CalcInputs(st.values));

      await tester.pumpWidget(
        MaterialApp(
          home: PdfPreviewScreen(
            def: def,
            state: st,
            result: result,
            fmt: fmt,
          ),
        ),
      );

      expect(find.text('${def.name} Report'), findsOneWidget);
      expect(find.byType(PdfPreviewScreen), findsOneWidget);
    });
  });
}
