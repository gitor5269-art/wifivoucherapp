import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../../models/voucher_model.dart';
import '../../services/auth_service.dart';
import '../../services/print_service.dart';
import '../../services/voucher_service.dart';
import '../../theme/app_theme.dart';

class GenerateScreen extends StatefulWidget {
  final VoidCallback onNavigateToManagement;

  const GenerateScreen({
    super.key,
    required this.onNavigateToManagement,
  });

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final ScrollController _scrollController = ScrollController();

  String _selectedDuration = '1 Hour';
  int _selectedBatchCount = 1;
  bool _isGenerating = false;
  List<VoucherModel>? _lastGeneratedVouchers;

  final List<String> _durations = ['1 Hour', '3 Hours', '1 Day'];
  final List<int> _batchCounts = [1, 5, 10, 20];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generateVouchers() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _lastGeneratedVouchers = null;
    });

    try {
      final adminEmail = AuthService().currentAdminEmail ?? 'admin@wifivoucher.com';
      List<VoucherModel> result = [];

      if (_selectedBatchCount == 1) {
        final v = await VoucherService().generateSingleVoucher(
          duration: _selectedDuration,
          adminEmail: adminEmail,
        );
        result = [v];
      } else {
        result = await VoucherService().generateBatchVouchers(
          count: _selectedBatchCount,
          duration: _selectedDuration,
          adminEmail: adminEmail,
        );
      }

      if (mounted) {
        setState(() {
          _lastGeneratedVouchers = result;
          _isGenerating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedBatchCount == 1
                  ? 'Successfully generated voucher ${result.first.code}!'
                  : 'Successfully generated ${result.length} vouchers!',
            ),
            backgroundColor: AppTheme.textPrimary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Smoothly scroll down to see the generated vouchers
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('[GenerateScreen] Error generating vouchers: $e');
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating voucher: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyAllGeneratedCodes() {
    if (_lastGeneratedVouchers == null || _lastGeneratedVouchers!.isEmpty) return;

    final buffer = StringBuffer();
    for (final v in _lastGeneratedVouchers!) {
      buffer.writeln(v.toCopyString(includeDuration: true));
      buffer.writeln('----------------------------------------');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${_lastGeneratedVouchers!.length} voucher(s) with duration to clipboard!'),
        backgroundColor: AppTheme.textPrimary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _printGeneratedVouchers() async {
    if (_lastGeneratedVouchers == null || _lastGeneratedVouchers!.isEmpty) return;

    try {
      if (_lastGeneratedVouchers!.length == 1) {
        await PrintService().printSingleVoucher(_lastGeneratedVouchers!.first);
      } else {
        await PrintService().printMultipleVouchers(_lastGeneratedVouchers!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Generate WiFi Vouchers',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Create single or batch vouchers with unique access codes and selected durations.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),

              // Generator Configuration Card
              Card(
                color: AppTheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Duration Options
                      const Text(
                        '1. Select Voucher Duration',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choose the validity period for the new voucher(s).',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: _durations.map((duration) {
                          final isSelected = _selectedDuration == duration;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: InkWell(
                                onTap: () => setState(() => _selectedDuration = duration),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.primaryBlueLight : AppTheme.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? AppTheme.primaryBlue : AppTheme.border,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 20,
                                        color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        duration,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const Divider(height: 32),

                      // Section 2: Quantity / Batch Count
                      const Text(
                        '2. Quantity to Generate',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Generate an individual voucher or create a small batch in one click.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 14),

                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: _batchCounts.map((count) {
                          final isSelected = _selectedBatchCount == count;
                          return ChoiceChip(
                            label: Text(
                              count == 1 ? '1 Voucher (Single)' : '$count Vouchers (Batch)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryBlueLight,
                            backgroundColor: AppTheme.background,
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryBlue : AppTheme.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedBatchCount = count);
                              }
                            },
                          );
                        }).toList(),
                      ),

                      const Divider(height: 32),

                      // Code format reassurance info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.borderLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: AppTheme.textSecondary),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Voucher codes are randomly generated, checked for uniqueness in Firestore, and formatted without confusing characters (0, O, 1, I, L) for easy reading.',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: _isGenerating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.bolt, size: 20),
                          label: Text(
                            _isGenerating
                                ? 'Generating Vouchers...'
                                : _selectedBatchCount == 1
                                    ? 'Generate 1 Voucher ($_selectedDuration)'
                                    : 'Generate $_selectedBatchCount Vouchers ($_selectedDuration)',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isGenerating ? null : _generateVouchers,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Instant Generation Results Area
              if (_lastGeneratedVouchers != null && _lastGeneratedVouchers!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Card(
                  color: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, size: 22, color: AppTheme.primaryBlue),
                                const SizedBox(width: 8),
                                Text(
                                  'Generated Successfully (${_lastGeneratedVouchers!.length} Voucher${_lastGeneratedVouchers!.length > 1 ? 's' : ''})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.content_copy, size: 16),
                                  label: const Text('Copy All'),
                                  onPressed: _copyAllGeneratedCodes,
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.print_outlined, size: 16),
                                  label: const Text('Print Now'),
                                  onPressed: _printGeneratedVouchers,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Display generated vouchers grid
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _lastGeneratedVouchers!.map((voucher) {
                            return Container(
                              width: 220,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        voucher.duration,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.copy, size: 16),
                                        tooltip: 'Copy Code',
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: voucher.code));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Voucher "${voucher.code}" copied!'),
                                              backgroundColor: AppTheme.textPrimary,
                                              duration: const Duration(seconds: 1),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  SelectableText(
                                    voucher.code,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Status: ${voucher.status}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Generate More Vouchers'),
                              onPressed: () {
                                setState(() => _lastGeneratedVouchers = null);
                                if (_scrollController.hasClients) {
                                  _scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                }
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: const Text('Go to Voucher Management'),
                              onPressed: widget.onNavigateToManagement,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
