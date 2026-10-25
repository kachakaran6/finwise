import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme/tokens.dart';
import '../../core/format.dart';
import '../../core/pdf_export_service.dart';
import '../../core/validation.dart';
import '../../domain/models/calc.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/common.dart';
import '../../theme/app_radius.dart';

/// Screen presenting the PDF report preview with direct share, save, and print actions.
class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({
    super.key,
    required this.def,
    required this.state,
    required this.result,
    required this.fmt,
  });

  final CalculatorDef def;
  final InputState state;
  final CalcResult result;
  final Fmt fmt;

  Future<void> _sharePdf(BuildContext context) async {
    try {
      final bytes = await PdfExportService.generateReport(
        def: def,
        state: state,
        result: result,
        fmt: fmt,
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/finwise_${def.id}_report.pdf');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf', name: 'finwise_${def.id}_report.pdf')],
        text: 'Finwise Financial Report: ${def.name}',
      );
    } catch (e) {
      if (context.mounted) {
        toast(context, 'Unable to share document: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            title: '${def.name} Report',
            actions: [
              AppHeaderAction(
                icon: PhosphorIconsRegular.shareNetwork,
                tooltip: 'Share PDF document',
                onPressed: () => _sharePdf(context),
              ),
            ],
          ),
          Expanded(
            child: PdfPreview(
              build: (format) => PdfExportService.generateReport(
                def: def,
                state: state,
                result: result,
                fmt: fmt,
              ),
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              dynamicLayout: false,
              pdfFileName: 'finwise_${def.id}_report.pdf',
              scrollViewDecoration: BoxDecoration(color: p.bg),
              loadingWidget: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: p.primary,
                ),
              ),
              onError: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Sp.xl, vertical: Sp.lg),
                    child: AppCard(
                      color: p.surfaceAlt,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.filePdf, size: 48, color: p.primary),
                          const SizedBox(height: Sp.md),
                          Text(
                            'Finwise PDF Generated',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: p.ink,
                                ),
                          ),
                          const SizedBox(height: Sp.xs),
                          Text(
                            'Your offline financial report was created successfully.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.inkMuted),
                          ),
                          const SizedBox(height: Sp.xl),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            ),
                            onPressed: () => _sharePdf(context),
                            icon: const Icon(PhosphorIconsRegular.shareNetwork, size: 20),
                            label: const Text('Share / Save PDF Document'),
                          ),
                          const SizedBox(height: Sp.lg),
                          Text(
                            'Note: Because a new native plugin was added to pubspec.yaml, a full app rebuild is required to view the live preview rasterizer on device (press "q" in terminal, then run "flutter run").',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: p.inkMuted,
                                  fontSize: 11.5,
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
