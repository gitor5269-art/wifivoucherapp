import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../../models/voucher_model.dart';
import '../../services/print_service.dart';
import '../../services/voucher_service.dart';
import '../../theme/app_theme.dart';

class VoucherDetailsDialog extends StatefulWidget {
  final VoucherModel voucher;
  final VoidCallback? onUpdated;

  const VoucherDetailsDialog({
    super.key,
    required this.voucher,
    this.onUpdated,
  });

  static Future<void> show(BuildContext context, VoucherModel voucher, {VoidCallback? onUpdated}) {
    return showDialog(
      context: context,
      builder: (context) => VoucherDetailsDialog(
        voucher: voucher,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  State<VoucherDetailsDialog> createState() => _VoucherDetailsDialogState();
}

class _VoucherDetailsDialogState extends State<VoucherDetailsDialog> {
  late VoucherModel _currentVoucher;
  bool _isUpdatingStatus = false;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _currentVoucher = widget.voucher;
  }

  Future<void> _toggleStatus() async {
    setState(() => _isUpdatingStatus = true);
    final newStatus = _currentVoucher.isUnused ? 'USED' : 'UNUSED';

    try {
      await VoucherService().updateVoucherStatus(_currentVoucher.id, newStatus);
      setState(() {
        _currentVoucher = _currentVoucher.copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
      });
      widget.onUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voucher status changed to $newStatus'),
            backgroundColor: AppTheme.textPrimary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  void _copyToClipboard({bool includeDuration = true}) {
    final text = _currentVoucher.toCopyString(includeDuration: includeDuration);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          includeDuration
              ? 'Copied voucher code & duration to clipboard!'
              : 'Copied code "${_currentVoucher.code}" to clipboard!',
        ),
        backgroundColor: AppTheme.textPrimary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _printVoucher() async {
    setState(() => _isPrinting = true);
    try {
      await PrintService().printSingleVoucher(_currentVoucher);
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
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _deleteVoucher() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Voucher?'),
        content: Text(
          'Are you sure you want to delete voucher "${_currentVoucher.code}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await VoucherService().deleteVoucher(_currentVoucher.id);
      widget.onUpdated?.call();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voucher "${_currentVoucher.code}" deleted.'),
            backgroundColor: AppTheme.textPrimary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnused = _currentVoucher.isUnused;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppTheme.surface,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Voucher Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Code Display Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'VOUCHER CODE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      _currentVoucher.code,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 5.0,
                        color: AppTheme.textPrimary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy Code Only'),
                          onPressed: () => _copyToClipboard(includeDuration: false),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.content_copy, size: 16),
                          label: const Text('Copy with Duration'),
                          onPressed: () => _copyToClipboard(includeDuration: true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Metadata table
              _buildDetailRow(
                'Status',
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUnused ? AppTheme.statusUnusedBg : AppTheme.statusUsedBg,
                        border: Border.all(
                          color: isUnused ? AppTheme.statusUnusedBorder : AppTheme.statusUsedBorder,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _currentVoucher.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isUnused ? AppTheme.statusUnusedText : AppTheme.statusUsedText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _isUpdatingStatus
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: _toggleStatus,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              isUnused ? 'Mark as USED' : 'Mark as UNUSED',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                  ],
                ),
              ),
              _buildDetailRow('Duration', Text(_currentVoucher.duration, style: const TextStyle(fontWeight: FontWeight.w600))),
              _buildDetailRow('Date Created', Text(_currentVoucher.formattedCreatedAt)),
              _buildDetailRow('Created By', Text(_currentVoucher.createdBy)),
              _buildDetailRow('Last Updated', Text(_currentVoucher.formattedUpdatedAt)),

              const Divider(height: 24),

              // Action Buttons
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                    tooltip: 'Delete Voucher',
                    onPressed: _deleteVoucher,
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        : const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Print Voucher'),
                    onPressed: _isPrinting ? null : _printVoucher,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          valueWidget,
        ],
      ),
    );
  }
}
