import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../../models/voucher_model.dart';
import '../../services/print_service.dart';
import '../../services/voucher_service.dart';
import '../../theme/app_theme.dart';
import '../details/voucher_details_dialog.dart';

class VoucherManagementScreen extends StatefulWidget {
  final VoidCallback onNavigateToGenerate;

  const VoucherManagementScreen({
    super.key,
    required this.onNavigateToGenerate,
  });

  @override
  State<VoucherManagementScreen> createState() => _VoucherManagementScreenState();
}

class _VoucherManagementScreenState extends State<VoucherManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _statusFilter = 'ALL'; // ALL, UNUSED, USED
  String _durationFilter = 'ALL'; // ALL, 1 Hour, 3 Hours, 1 Day
  bool _sortNewestFirst = true;

  final Set<String> _selectedVoucherIds = {};
  bool _isRefreshing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await VoucherService().refresh();
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vouchers refreshed from database'),
          backgroundColor: AppTheme.textPrimary,
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<VoucherModel> _filterAndSortVouchers(List<VoucherModel> vouchers) {
    return vouchers.where((v) {
      // Search code filter
      if (_searchQuery.isNotEmpty && !v.code.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      // Status filter
      if (_statusFilter != 'ALL' && v.status.toUpperCase() != _statusFilter.toUpperCase()) {
        return false;
      }
      // Duration filter
      if (_durationFilter != 'ALL' && v.duration != _durationFilter) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        return _sortNewestFirst
            ? b.createdAt.compareTo(a.createdAt)
            : a.createdAt.compareTo(b.createdAt);
      });
  }

  Future<void> _toggleVoucherStatus(VoucherModel voucher) async {
    final newStatus = voucher.isUnused ? 'USED' : 'UNUSED';
    await VoucherService().updateVoucherStatus(voucher.id, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voucher "${voucher.code}" marked as $newStatus'),
          backgroundColor: AppTheme.textPrimary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteVoucherWithConfirm(VoucherModel voucher) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Voucher?'),
        content: Text('Are you sure you want to delete voucher "${voucher.code}"?'),
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
      await VoucherService().deleteVoucher(voucher.id);
      _selectedVoucherIds.remove(voucher.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted voucher "${voucher.code}"'),
            backgroundColor: AppTheme.textPrimary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyVoucherCode(String code, {String? duration}) {
    final text = duration != null ? 'Voucher Code: $code\nDuration: $duration' : code;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "$code" to clipboard!'),
        backgroundColor: AppTheme.textPrimary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copySelectedVouchers(List<VoucherModel> allVouchers) {
    final selected = allVouchers.where((v) => _selectedVoucherIds.contains(v.id)).toList();
    if (selected.isEmpty) return;

    final buffer = StringBuffer();
    for (final v in selected) {
      buffer.writeln(v.toCopyString(includeDuration: true));
      buffer.writeln('----------------------------------------');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${selected.length} selected vouchers to clipboard!'),
        backgroundColor: AppTheme.textPrimary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _printSelectedVouchers(List<VoucherModel> allVouchers) async {
    final selected = allVouchers.where((v) => _selectedVoucherIds.contains(v.id)).toList();
    if (selected.isEmpty) return;

    try {
      if (selected.length == 1) {
        await PrintService().printSingleVoucher(selected.first);
      } else {
        await PrintService().printMultipleVouchers(selected, title: 'Selected WiFi Vouchers');
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

  Future<void> _printAllFilteredVouchers(List<VoucherModel> filteredVouchers) async {
    if (filteredVouchers.isEmpty) return;

    try {
      if (filteredVouchers.length == 1) {
        await PrintService().printSingleVoucher(filteredVouchers.first);
      } else {
        await PrintService().printMultipleVouchers(filteredVouchers, title: 'Filtered WiFi Vouchers');
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
    final voucherService = VoucherService();

    return StreamBuilder<List<VoucherModel>>(
      stream: voucherService.vouchersStream,
      initialData: voucherService.vouchers,
      builder: (context, snapshot) {
        final allVouchers = snapshot.data ?? [];
        final filteredVouchers = _filterAndSortVouchers(allVouchers);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Voucher Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Search, filter, update status, copy, and print voucher records.',
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: _isRefreshing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh'),
                        onPressed: _isRefreshing ? null : _refresh,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Generate New'),
                        onPressed: widget.onNavigateToGenerate,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Filter & Search Controls Card
              Card(
                color: AppTheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Search and Sort Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val.trim()),
                              decoration: InputDecoration(
                                hintText: 'Search by voucher code...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Sort dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              border: Border.all(color: AppTheme.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<bool>(
                                value: _sortNewestFirst,
                                icon: const Icon(Icons.sort, size: 18, color: AppTheme.textSecondary),
                                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                items: const [
                                  DropdownMenuItem(value: true, child: Text('Newest First')),
                                  DropdownMenuItem(value: false, child: Text('Oldest First')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _sortNewestFirst = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Filters row
                      Row(
                        children: [
                          // Status Filter
                          const Text(
                            'Status:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Wrap(
                            spacing: 6,
                            children: ['ALL', 'UNUSED', 'USED'].map((status) {
                              final isSelected = _statusFilter == status;
                              return ChoiceChip(
                                label: Text(status),
                                selected: isSelected,
                                selectedColor: AppTheme.primaryBlueLight,
                                backgroundColor: AppTheme.background,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                                ),
                                side: BorderSide(
                                  color: isSelected ? AppTheme.primaryBlue : AppTheme.border,
                                ),
                                onSelected: (sel) {
                                  if (sel) setState(() => _statusFilter = status);
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(width: 20),

                          // Duration Filter
                          const Text(
                            'Duration:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Wrap(
                            spacing: 6,
                            children: ['ALL', '1 Hour', '3 Hours', '1 Day'].map((dur) {
                              final isSelected = _durationFilter == dur;
                              return ChoiceChip(
                                label: Text(dur),
                                selected: isSelected,
                                selectedColor: AppTheme.primaryBlueLight,
                                backgroundColor: AppTheme.background,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                                ),
                                side: BorderSide(
                                  color: isSelected ? AppTheme.primaryBlue : AppTheme.border,
                                ),
                                onSelected: (sel) {
                                  if (sel) setState(() => _durationFilter = dur);
                                },
                              );
                            }).toList(),
                          ),

                          const Spacer(),

                          // Quick print all filtered
                          if (filteredVouchers.isNotEmpty)
                            TextButton.icon(
                              icon: const Icon(Icons.print_outlined, size: 16),
                              label: Text('Print All Filtered (${filteredVouchers.length})'),
                              onPressed: () => _printAllFilteredVouchers(filteredVouchers),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Multi-select bulk action toolbar (if any vouchers are selected)
              if (_selectedVoucherIds.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryBlueBorder),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${_selectedVoucherIds.length} Voucher${_selectedVoucherIds.length > 1 ? 's' : ''} Selected',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy Selected'),
                        onPressed: () => _copySelectedVouchers(allVouchers),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.print_outlined, size: 16),
                        label: const Text('Print Selected'),
                        onPressed: () => _printSelectedVouchers(allVouchers),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _selectedVoucherIds.clear()),
                        child: const Text('Clear Selection'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Table / Card List Content
              Card(
                color: AppTheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Table header with Select All
                      Row(
                        children: [
                          Checkbox(
                            value: filteredVouchers.isNotEmpty &&
                                _selectedVoucherIds.length == filteredVouchers.length,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedVoucherIds.addAll(filteredVouchers.map((v) => v.id));
                                } else {
                                  _selectedVoucherIds.clear();
                                }
                              });
                            },
                          ),
                          Text(
                            'Showing ${filteredVouchers.length} of ${allVouchers.length} Vouchers',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),

                      if (filteredVouchers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_outlined,
                                  size: 48,
                                  color: AppTheme.textMuted.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No vouchers match "$_searchQuery"'
                                      : 'No vouchers found for this filter',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Try adjusting your search query or status filter.',
                                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _statusFilter = 'ALL';
                                      _durationFilter = 'ALL';
                                    });
                                  },
                                  child: const Text('Reset Filters'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 750) {
                              return _buildTableView(filteredVouchers);
                            } else {
                              return _buildCardListView(filteredVouchers);
                            }
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

  /// Desktop / Tablet Clean Table View
  Widget _buildTableView(List<VoucherModel> vouchers) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(48), // Checkbox
        1: FlexColumnWidth(2.0), // Voucher Code
        2: FlexColumnWidth(1.2), // Duration
        3: FlexColumnWidth(1.2), // Status
        4: FlexColumnWidth(1.8), // Date Created
        5: FlexColumnWidth(2.2), // Actions
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Table Header
        TableRow(
          decoration: const BoxDecoration(
            color: AppTheme.background,
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          children: [
            const SizedBox(height: 40),
            _buildTableHeaderCell('Voucher Code'),
            _buildTableHeaderCell('Duration'),
            _buildTableHeaderCell('Status'),
            _buildTableHeaderCell('Date Created'),
            _buildTableHeaderCell('Actions'),
          ],
        ),

        // Table Rows
        ...vouchers.map((voucher) {
          final isSelected = _selectedVoucherIds.contains(voucher.id);
          final isUnused = voucher.isUnused;

          return TableRow(
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlueLight.withValues(alpha: 0.3) : Colors.transparent,
              border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            children: [
              // Checkbox
              TableCell(
                child: Checkbox(
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedVoucherIds.add(voucher.id);
                      } else {
                        _selectedVoucherIds.remove(voucher.id);
                      }
                    });
                  },
                ),
              ),
              // Code
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      SelectableText(
                        voucher.code,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.copy, size: 15, color: AppTheme.textSecondary),
                        tooltip: 'Copy Code',
                        onPressed: () => _copyVoucherCode(voucher.code),
                      ),
                    ],
                  ),
                ),
              ),
              // Duration
              TableCell(
                child: Text(
                  voucher.duration,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              // Status
              TableCell(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isUnused ? AppTheme.statusUnusedBg : AppTheme.statusUsedBg,
                        border: Border.all(
                          color: isUnused ? AppTheme.statusUnusedBorder : AppTheme.statusUsedBorder,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        voucher.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isUnused ? AppTheme.statusUnusedText : AppTheme.statusUsedText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        isUnused ? Icons.toggle_off_outlined : Icons.toggle_on,
                        size: 20,
                        color: isUnused ? AppTheme.textSecondary : AppTheme.primaryBlue,
                      ),
                      tooltip: isUnused ? 'Switch to USED' : 'Switch to UNUSED',
                      onPressed: () => _toggleVoucherStatus(voucher),
                    ),
                  ],
                ),
              ),
              // Date Created
              TableCell(
                child: Text(
                  voucher.formattedCreatedAt,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
              // Actions
              TableCell(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.print_outlined, size: 18),
                      tooltip: 'Print Voucher',
                      onPressed: () => PrintService().printSingleVoucher(voucher),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 18),
                      tooltip: 'View Details',
                      onPressed: () => VoucherDetailsDialog.show(context, voucher),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                      tooltip: 'Delete Record',
                      onPressed: () => _deleteVoucherWithConfirm(voucher),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Mobile Responsive Card List View
  Widget _buildCardListView(List<VoucherModel> vouchers) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vouchers.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final voucher = vouchers[index];
        final isSelected = _selectedVoucherIds.contains(voucher.id);
        final isUnused = voucher.isUnused;

        return Container(
          color: isSelected ? AppTheme.primaryBlueLight.withValues(alpha: 0.3) : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedVoucherIds.add(voucher.id);
                        } else {
                          _selectedVoucherIds.remove(voucher.id);
                        }
                      });
                    },
                  ),
                  SelectableText(
                    voucher.code,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isUnused ? AppTheme.statusUnusedBg : AppTheme.statusUsedBg,
                      border: Border.all(
                        color: isUnused ? AppTheme.statusUnusedBorder : AppTheme.statusUsedBorder,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      voucher.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isUnused ? AppTheme.statusUnusedText : AppTheme.statusUsedText,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy Code',
                    onPressed: () => _copyVoucherCode(voucher.code, duration: voucher.duration),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    tooltip: 'Details',
                    onPressed: () => VoucherDetailsDialog.show(context, voucher),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48.0, right: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${voucher.duration} • ${voucher.formattedCreatedAt}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _toggleVoucherStatus(voucher),
                          child: Text(
                            isUnused ? 'Mark USED' : 'Mark UNUSED',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                          tooltip: 'Delete',
                          onPressed: () => _deleteVoucherWithConfirm(voucher),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
