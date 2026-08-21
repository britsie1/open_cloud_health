import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:open_cloud_health/models/pdf_export_options.dart';
import 'package:open_cloud_health/models/profile.dart';
import 'package:open_cloud_health/services/medical_pdf_service.dart';

class PdfPreviewScreen extends ConsumerWidget {
  final Profile profile;
  final MedicalPdfExportOptions options;

  const PdfPreviewScreen({
    super.key,
    required this.profile,
    this.options = const MedicalPdfExportOptions(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfService = ref.read(medicalPdfServiceProvider);
    final sanitizedName = '${profile.name}_${profile.surname}'.replaceAll(RegExp(r'[^\w]'), '_');
    final fileName = 'Medical_Summary_$sanitizedName.pdf';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${profile.name} - Medical PDF',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: PdfPreview(
        build: (format) => pdfService.generateMedicalPdfBytes(profile.id, options: options),
        pdfFileName: fileName,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        maxPageWidth: 700,
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Compiling Medical Summary PDF...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
