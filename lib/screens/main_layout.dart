import 'package:material_ui/material_ui.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'generate/generate_screen.dart';
import 'management/voucher_management_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0; // 0: Dashboard, 1: Voucher Management, 2: Generate Voucher

  void _navigateToIndex(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to end your administrator session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAdmin = AuthService().currentAdminEmail ?? 'admin@wifivoucher.com';

    final pages = [
      DashboardScreen(
        onNavigateToGenerate: () => _navigateToIndex(2),
        onNavigateToManagement: () => _navigateToIndex(1),
      ),
      VoucherManagementScreen(
        onNavigateToGenerate: () => _navigateToIndex(2),
      ),
      GenerateScreen(
        onNavigateToManagement: () => _navigateToIndex(1),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 840;

        if (isDesktop) {
          // Desktop Layout with Fixed Sidebar
          return Scaffold(
            body: Row(
              children: [
                // Minimal Sidebar
                Container(
                  width: 250,
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(right: BorderSide(color: AppTheme.border, width: 1)),
                  ),
                  child: Column(
                    children: [
                      // Sidebar Header / Brand
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlueLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.primaryBlueBorder),
                              ),
                              child: const Icon(
                                Icons.wifi_rounded,
                                size: 20,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WiFi Voucher',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  'Management System',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Navigation Items
                      _buildSidebarItem(
                        index: 0,
                        title: 'Dashboard',
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard,
                      ),
                      _buildSidebarItem(
                        index: 1,
                        title: 'Voucher Management',
                        icon: Icons.confirmation_number_outlined,
                        activeIcon: Icons.confirmation_number,
                      ),
                      _buildSidebarItem(
                        index: 2,
                        title: 'Generate Voucher',
                        icon: Icons.add_circle_outline,
                        activeIcon: Icons.add_circle,
                      ),

                      const Spacer(),
                      const Divider(height: 1),

                      // Administrator Profile & Logout
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppTheme.primaryBlueLight,
                                    child: Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Administrator',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          currentAdmin,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.danger,
                                  side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.3)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                icon: const Icon(Icons.logout, size: 16, color: AppTheme.danger),
                                label: const Text('Logout', style: TextStyle(fontSize: 13)),
                                onPressed: _handleLogout,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Page Content Area
                Expanded(
                  child: pages[_selectedIndex],
                ),
              ],
            ),
          );
        } else {
          // Mobile / Narrow Layout with Bottom Navigation Bar & Top AppBar
          final titles = ['Dashboard', 'Vouchers', 'Generate'];

          return Scaffold(
            appBar: AppBar(
              title: Text(titles[_selectedIndex]),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, size: 20),
                  tooltip: 'Logout',
                  onPressed: _handleLogout,
                ),
              ],
            ),
            body: pages[_selectedIndex],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _navigateToIndex,
              backgroundColor: AppTheme.surface,
              indicatorColor: AppTheme.primaryBlueLight,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryBlue),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.confirmation_number_outlined),
                  selectedIcon: Icon(Icons.confirmation_number, color: AppTheme.primaryBlue),
                  label: 'Management',
                ),
                NavigationDestination(
                  icon: Icon(Icons.add_circle_outline),
                  selectedIcon: Icon(Icons.add_circle, color: AppTheme.primaryBlue),
                  label: 'Generate',
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required String title,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: () => _navigateToIndex(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlueLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
