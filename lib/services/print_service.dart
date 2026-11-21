import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/voucher_model.dart';

class PrintService {
  static final PrintService _instance = PrintService._internal();
  factory PrintService() => _instance;
  PrintService._internal();

  /// Prints a single voucher formatted with clean, professional black-and-white borders.
  Future<bool> printSingleVoucher(VoucherModel voucher) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Center(
            child: _buildVoucherCard(voucher, width: 340, height: 220),
          );
        },
      ),
    );

    return await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'voucher_${voucher.code}.pdf',
    );
  }

  /// Prints multiple vouchers arranged in a clean, printable grid with cutting guides.
  Future<bool> printMultipleVouchers(List<VoucherModel> vouchers, {String title = 'WiFi Vouchers'}) async {
    if (vouchers.isEmpty) return false;

    final pdf = pw.Document();
    const int vouchersPerPage = 6;
    final int pageCount = (vouchers.length / vouchersPerPage).ceil();

    for (int p = 0; p < pageCount; p++) {
      final startIndex = p * vouchersPerPage;
      final endIndex = (startIndex + vouchersPerPage < vouchers.length)
          ? startIndex + vouchersPerPage
          : vouchers.length;
      final pageVouchers = vouchers.sublist(startIndex, endIndex);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      title.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.Text(
                      'Page ${p + 1} of $pageCount',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 16),
                pw.Expanded(
                  child: pw.GridView(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: pageVouchers.map((v) => _buildVoucherCard(v)).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'wifi_vouchers_batch_${vouchers.length}.pdf',
    );
  }

  /// Builds a clean, minimalist black and white ticket card conforming to proposal specifications:
  ///
  /// WiFi VOUCHER
  ///
  /// Voucher Code: X7K9P2
  /// Duration: 3 Hours
  /// Status: UNUSED
  ///
  /// Date Generated: [Actual Date]
  static pw.Widget _buildVoucherCard(VoucherModel voucher, {double? width, double? height}) {
    return pw.Container(
      width: width,
      height: height,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.black, width: 1.2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'WiFi VOUCHER',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.2,
                  color: PdfColors.black,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.8),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  voucher.status.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'VOUCHER CODE',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  voucher.code,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 4.0,
                    color: PdfColors.black,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Duration:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  pw.Text(
                    voucher.duration,
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Date Generated:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  pw.Text(
                    voucher.formattedCreatedAt,
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.black),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
