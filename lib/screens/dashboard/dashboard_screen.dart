import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../../models/voucher_model.dart';
import '../../services/voucher_service.dart';
import '../../theme/app_theme.dart';
import '../details/voucher_details_dialog.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToGenerate;
  final VoidCallback onNavigateToManagement;

  const DashboardScreen({
    super.key,
    required this.onNavigateToGenerate,
    required this.onNavigateToManagement,
  });

  void _copyVoucherCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voucher code "$code" copied to clipboard!'),
        backgroundColor: AppTheme.textPrimary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voucherService = VoucherService();

    return StreamBuilder<List<VoucherModel>>(
      stream: voucherService.vouchersStream,
      initialData: voucherService.vouchers,
      builder: (context, snapshot) {
        final allVouchers = snapshot.data ?? [];
        final totalCount = allVouchers.length;
        final unusedCount = allVouchers.where((v) => v.isUnused).length;
        final usedCount = allVouchers.where((v) => v.isUsed).length;
        final recentVouchers = allVouchers.take(6).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'WiFi Voucher Overview & Statistics',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Generate Voucher'),
                    onPressed: onNavigateToGenerate,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Statistics Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Vouchers',
                          value: totalCount.toString(),
                          subtitle: 'All created vouchers',
                          icon: Icons.confirmation_number_outlined,
                          accentColor: AppTheme.primaryBlue,
                          isCompact: !isWide,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Unused Vouchers',
                          value: unusedCount.toString(),
                          subtitle: 'Ready for customers',
                          icon: Icons.check_circle_outline,
                          accentColor: AppTheme.primaryBlue,
                          isCompact: !isWide,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Used Vouchers',
                          value: usedCount.toString(),
                          subtitle: 'Activated / Expired',
                          icon: Icons.history_toggle_off_outlined,
                          accentColor: AppTheme.textSecondary,
                          isCompact: !isWide,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Quick Actions Bar
              Card(
                color: AppTheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_outlined, size: 20, color: AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      const Text(
                        'Quick Actions:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Generate Voucher'),
                        onPressed: onNavigateToGenerate,
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.list_alt, size: 16),
                        label: const Text('Manage All Vouchers'),
                        onPressed: onNavigateToManagement,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Recent Vouchers Card
              Card(
                color: AppTheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.access_time_outlined, size: 20, color: AppTheme.textSecondary),
                              SizedBox(width: 8),
                              Text(
                                'Recent Generated Vouchers',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: onNavigateToManagement,
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      if (recentVouchers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: AppTheme.textMuted.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No vouchers generated yet',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Create your first WiFi voucher to get started.',
                                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Generate First Voucher'),
                                  onPressed: onNavigateToGenerate,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentVouchers.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final voucher = recentVouchers[index];
                            final isUnused = voucher.isUnused;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: const Icon(
                                  Icons.wifi_rounded,
                                  size: 20,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    voucher.code,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isUnused ? AppTheme.statusUnusedBg : AppTheme.statusUsedBg,
                                      border: Border.all(
                                        color: isUnused
                                            ? AppTheme.statusUnusedBorder
                                            : AppTheme.statusUsedBorder,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      voucher.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isUnused
                                            ? AppTheme.statusUnusedText
                                            : AppTheme.statusUsedText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${voucher.duration} • Created ${voucher.formattedCreatedAt}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 18),
                                    tooltip: 'Copy Code',
                                    onPressed: () => _copyVoucherCode(context, voucher.code),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new, size: 18),
                                    tooltip: 'View Details',
                                    onPressed: () => VoucherDetailsDialog.show(context, voucher),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isCompact,
  }) {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Icon(icon, size: 18, color: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
