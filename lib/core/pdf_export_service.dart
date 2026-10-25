import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/models/calc.dart';
import 'format.dart';
import 'validation.dart';

/// Professional, offline PDF report generator for Finwise.
/// Strictly zero emojis to ensure 100% reliable rendering without font or glyph errors.
class PdfExportService {
  static const PdfColor _emerald = PdfColor.fromInt(0xFF059669);
  static const PdfColor _emeraldDark = PdfColor.fromInt(0xFF065F46);
  static const PdfColor _emeraldLight = PdfColor.fromInt(0xFFF0FDF4);
  static const PdfColor _emeraldBorder = PdfColor.fromInt(0xFFA7F3D0);
  static const PdfColor _slateDark = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor _slateMuted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _slateLight = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _dividerColor = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor _barSecondary = PdfColor.fromInt(0xFF10B981);

  /// Generates a complete, publication-grade PDF report for the given calculator calculation.
  static Future<Uint8List> generateReport({
    required CalculatorDef def,
    required InputState state,
    required CalcResult result,
    required Fmt fmt,
    DateTime? timestamp,
  }) async {
    pw.Font baseFont;
    pw.Font boldFont;
    pw.Font monoFont;

    try {
      final regData = await rootBundle.load('assets/fonts/IBMPlexSans-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/IBMPlexSans-Bold.ttf');
      final monoData = await rootBundle.load('assets/fonts/IBMPlexMono-Regular.ttf');
      baseFont = pw.Font.ttf(regData.buffer.asByteData());
      boldFont = pw.Font.ttf(boldData.buffer.asByteData());
      monoFont = pw.Font.ttf(monoData.buffer.asByteData());
    } catch (_) {
      // Fallback for tests or environments without asset bundle
      baseFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
      monoFont = pw.Font.courier();
    }

    final doc = pw.Document(
      title: '${def.name} - Finwise',
      author: 'Finwise',
      subject: 'Financial Calculation Report',
      keywords: 'Finwise, Finance, ${def.name}, Offline',
      theme: pw.ThemeData.withFont(
        base: baseFont,
        bold: boldFont,
      ),
    );

    final generatedAt = DateFormat('dd MMM yyyy, HH:mm').format(timestamp ?? DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        header: (context) => _buildHeader(def, generatedAt, boldFont),
        footer: (context) => _buildFooter(context, monoFont),
        build: (context) => [
          _buildMetaBanner(def, fmt, boldFont),
          pw.SizedBox(height: 14),
          _buildExecutiveSummary(def, result, fmt, boldFont),
          pw.SizedBox(height: 16),
          _buildInputsSection(def, state, fmt, boldFont),
          pw.SizedBox(height: 16),
          _buildBreakdownSection(result, fmt, boldFont),
          pw.SizedBox(height: 16),
          _buildFormulaSection(def, result, monoFont, boldFont),
          if (result.schedule != null && result.schedule!.rows.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildScheduleSection(result.schedule!, fmt, boldFont, monoFont),
          ],
        ],
      ),
    );

    return doc.save();
  }

  /// Top Brand Header
  static pw.Widget _buildHeader(CalculatorDef def, String generatedAt, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(height: 3, color: _emerald),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FINWISE',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 16,
                    color: _emerald,
                    letterSpacing: 1.5,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Private, Offline Financial Intelligence & Planning',
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: _slateMuted,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: _emeraldLight,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: _emeraldBorder, width: 0.75),
                  ),
                  child: pw.Text(
                    'OFFLINE & CONFIDENTIAL',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 7.5,
                      color: _emeraldDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Generated: $generatedAt',
                  style: const pw.TextStyle(fontSize: 8, color: _slateMuted),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _dividerColor, thickness: 0.75),
        pw.SizedBox(height: 8),
      ],
    );
  }

  /// Metadata Banner: Calculator Name, Category, Currency
  static pw.Widget _buildMetaBanner(CalculatorDef def, Fmt fmt, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _slateLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: _dividerColor, width: 0.75),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                def.name,
                style: pw.TextStyle(font: boldFont, fontSize: 14, color: _slateDark),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Category: ${def.category.label}  |  Code: ${def.code}',
                style: const pw.TextStyle(fontSize: 8.5, color: _slateMuted),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Currency: ${fmt.currency.name} (${fmt.currency.symbol.trim()})',
                style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: _slateDark),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Formatting: ${fmt.locale}',
                style: const pw.TextStyle(fontSize: 8, color: _slateMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Executive Summary Card with Primary Result
  static pw.Widget _buildExecutiveSummary(
    CalculatorDef def,
    CalcResult result,
    Fmt fmt,
    pw.Font boldFont,
  ) {
    final primaryLabel = result.primary.label.toUpperCase();
    final primaryValue = fmt.value(result.primary);

    // Check if we can display a visual proportion bar (e.g. Principal vs Interest)
    ResultRow? principalRow;
    ResultRow? interestRow;
    for (final r in result.rows) {
      final l = r.label.toLowerCase();
      if (l.contains('principal') || l.contains('invested') || l.contains('loan amount')) {
        principalRow ??= r;
      } else if (l.contains('interest') || l.contains('wealth gained') || l.contains('capital gain')) {
        interestRow ??= r;
      }
    }

    final hasProportion = principalRow?.value != null &&
        interestRow?.value != null &&
        principalRow!.value! > 0 &&
        interestRow!.value! > 0;

    double pRatio = 0.5;
    double iRatio = 0.5;
    if (hasProportion) {
      final total = principalRow.value! + interestRow.value!;
      if (total > 0) {
        pRatio = (principalRow.value! / total).clamp(0.05, 0.95);
        iRatio = 1.0 - pRatio;
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _emeraldLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _emeraldBorder, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                primaryLabel,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 9,
                  color: _emeraldDark,
                  letterSpacing: 1.1,
                ),
              ),
              pw.Text(
                'EXECUTIVE SUMMARY',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: _slateMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            primaryValue,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 22,
              color: _slateDark,
            ),
          ),
          if (hasProportion) ...[
            pw.SizedBox(height: 10),
            pw.ClipRRect(
              horizontalRadius: 3,
              verticalRadius: 3,
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: (pRatio * 100).round(),
                    child: pw.Container(height: 7, color: _emerald),
                  ),
                  pw.Expanded(
                    flex: (iRatio * 100).round(),
                    child: pw.Container(height: 7, color: _barSecondary),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${principalRow.label}: ${fmt.value(principalRow)} (${(pRatio * 100).toStringAsFixed(1)}%)',
                  style: const pw.TextStyle(fontSize: 8, color: _slateDark),
                ),
                pw.Text(
                  '${interestRow.label}: ${fmt.value(interestRow)} (${(iRatio * 100).toStringAsFixed(1)}%)',
                  style: const pw.TextStyle(fontSize: 8, color: _slateDark),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Inputs Table
  static pw.Widget _buildInputsSection(
    CalculatorDef def,
    InputState state,
    Fmt fmt,
    pw.Font boldFont,
  ) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _slateLight),
        children: [
          _cellHeader('Input Parameter', boldFont),
          _cellHeader('Provided Value', boldFont),
          _cellHeader('Unit / Parameter Description', boldFont),
        ],
      ),
    ];

    bool alt = false;
    for (final f in def.fields) {
      if (!f.visible(state.values)) continue;
      final val = state.values[f.id];
      String displayVal = '-';
      if (val != null) {
        if (f.kind == FieldKind.choice) {
          displayVal = f.optionLabel(val.toString());
        } else if (val is num) {
          if (f.money) {
            displayVal = fmt.money(val.toDouble());
          } else if (f.suffix != null) {
            displayVal = '${fmt.plain(val.toDouble())} ${f.suffix}';
          } else {
            displayVal = fmt.plain(val.toDouble());
          }
        } else {
          displayVal = val.toString();
        }
      }

      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: alt ? _slateLight : PdfColors.white),
          children: [
            _cellText(f.label, isBold: true, boldFont: boldFont),
            _cellText(displayVal),
            _cellText(f.help ?? f.suffix ?? '-', isMuted: true),
          ],
        ),
      );
      alt = !alt;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeading('1. Input Parameters', boldFont),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: _dividerColor, width: 0.75),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.2),
            1: pw.FlexColumnWidth(1.8),
            2: pw.FlexColumnWidth(2.5),
          },
          children: rows,
        ),
      ],
    );
  }

  /// Key Results / Breakdown Table
  static pw.Widget _buildBreakdownSection(CalcResult result, Fmt fmt, pw.Font boldFont) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _slateLight),
        children: [
          _cellHeader('Result Metric', boldFont),
          _cellHeader('Calculated Value', boldFont),
        ],
      ),
    ];

    bool alt = false;
    for (final r in result.rows) {
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: alt ? _slateLight : PdfColors.white),
          children: [
            _cellText(r.label, isBold: true, boldFont: boldFont),
            _cellText(fmt.value(r)),
          ],
        ),
      );
      alt = !alt;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeading('2. Detailed Financial Breakdown', boldFont),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: _dividerColor, width: 0.75),
          columnWidths: const {
            0: pw.FlexColumnWidth(3.0),
            1: pw.FlexColumnWidth(2.0),
          },
          children: rows,
        ),
      ],
    );
  }

  /// Formula, Methodology and Assumptions Section
  static pw.Widget _buildFormulaSection(
    CalculatorDef def,
    CalcResult result,
    pw.Font monoFont,
    pw.Font boldFont,
  ) {
    final formulaText = def.formula.join('\n');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeading('3. Formula & Methodology', boldFont),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: _slateLight,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            border: pw.Border.all(color: _dividerColor, width: 0.75),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MATHEMATICAL MODEL:',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 7.5,
                  color: _slateMuted,
                  letterSpacing: 0.8,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                formulaText,
                style: pw.TextStyle(
                  font: monoFont,
                  fontSize: 8.5,
                  color: _slateDark,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: _dividerColor, thickness: 0.5),
              pw.SizedBox(height: 6),
              pw.Text(
                'CALCULATION EXPLANATION:',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 7.5,
                  color: _slateMuted,
                  letterSpacing: 0.8,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                def.explains,
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: _slateDark,
                  lineSpacing: 1.3,
                ),
              ),
              if (result.assumptions.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'UNDERLYING ASSUMPTIONS:',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 7.5,
                    color: _slateMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.SizedBox(height: 3),
                for (final a in result.assumptions)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '- ',
                          style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: _emerald),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            a,
                            style: const pw.TextStyle(fontSize: 8.5, color: _slateDark),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Schedule / Amortization Table (up to 36 rows max for clean report layout)
  static pw.Widget _buildScheduleSection(
    Schedule sched,
    Fmt fmt,
    pw.Font boldFont,
    pw.Font monoFont,
  ) {
    final maxRows = sched.rows.length > 36 ? 36 : sched.rows.length;
    final displayRows = sched.rows.sublist(0, maxRows);

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _slateLight),
        children: [
          for (final col in sched.columns) _cellHeader(col, boldFont),
        ],
      ),
    ];

    bool alt = false;
    for (final r in displayRows) {
      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: alt ? _slateLight : PdfColors.white),
          children: [
            for (var c = 0; c < r.length; c++)
              _cellText(
                fmt.scheduleCell(r[c], c, sched.firstColumnIsIndex),
                font: monoFont,
                align: c == 0 && sched.firstColumnIsIndex ? pw.TextAlign.left : pw.TextAlign.right,
              ),
          ],
        ),
      );
      alt = !alt;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeading('4. Projection & Amortization Schedule', boldFont),
        if (sched.rows.length > 36) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            '(Displaying first 36 periods of ${sched.rows.length} total)',
            style: const pw.TextStyle(fontSize: 7.5, color: _slateMuted),
          ),
        ],
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: _dividerColor, width: 0.75),
          children: tableRows,
        ),
      ],
    );
  }

  /// Page Footer with Pagination and Offline Disclaimer
  static pw.Widget _buildFooter(pw.Context context, pw.Font monoFont) {
    return pw.Column(
      children: [
        pw.Divider(color: _dividerColor, thickness: 0.75),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Finwise  |  100% Offline & Private Financial Engineering',
              style: const pw.TextStyle(fontSize: 7.5, color: _slateMuted),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(font: monoFont, fontSize: 7.5, color: _slateMuted),
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'Disclaimer: For planning and educational purposes only. Not investment, tax, or legal advice. No data ever leaves your device.',
          style: const pw.TextStyle(fontSize: 6.5, color: _slateMuted),
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  static pw.Widget _sectionHeading(String title, pw.Font boldFont) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        font: boldFont,
        fontSize: 10.5,
        color: _slateDark,
      ),
    );
  }

  static pw.Widget _cellHeader(String text, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 8,
          color: _slateDark,
        ),
      ),
    );
  }

  static pw.Widget _cellText(
    String text, {
    bool isBold = false,
    bool isMuted = false,
    pw.Font? font,
    pw.Font? boldFont,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: font ?? (isBold && boldFont != null ? boldFont : null),
          fontSize: 8,
          color: isMuted ? _slateMuted : _slateDark,
        ),
      ),
    );
  }
}
