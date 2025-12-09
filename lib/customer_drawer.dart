import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final String userRole;

  const CustomDrawer({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.warehouse, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Warehouse App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Role: $userRole',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Menu khusus untuk Boss/Owner
          if (userRole == 'Owner/Boss') ...[
            _buildDrawerItem(
              context,
              icon: Icons.analytics,
              title: 'Financial Reports',
              onTap: () {
                Navigator.pop(context);
                // Navigate to financial reports
                // TODO: Implement financial reports navigation
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.trending_up,
              title: 'Business Analytics',
              onTap: () {
                Navigator.pop(context);
                // Navigate to analytics
                // TODO: Implement analytics navigation
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.people,
              title: 'Employee Performance',
              onTap: () {
                Navigator.pop(context);
                // Navigate to employee performance
                // TODO: Implement employee performance navigation
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.account_balance,
              title: 'Profit & Loss',
              onTap: () {
                Navigator.pop(context);
                // Navigate to profit & loss
                // TODO: Implement profit & loss navigation
              },
            ),
            const Divider(),
          ],

          // Menu umum untuk semua role
          _buildDrawerItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              Navigator.pop(context);
              // TODO: Handle dashboard navigation based on role
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.inventory_2,
            title: 'Products',
            onTap: () {
              Navigator.pop(context);
              // Navigate to products
              // TODO: Implement products navigation
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.category,
            title: 'Categories',
            onTap: () {
              Navigator.pop(context);
              // Navigate to categories
              // TODO: Implement categories navigation
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.local_shipping,
            title: 'Suppliers',
            onTap: () {
              Navigator.pop(context);
              // Navigate to suppliers
              // TODO: Implement suppliers navigation
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.swap_horiz,
            title: 'Transactions',
            onTap: () {
              Navigator.pop(context);
              // Navigate to transactions
              // TODO: Implement transactions navigation
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.assessment,
            title: 'Reports',
            onTap: () {
              Navigator.pop(context);
              // Navigate to reports
              // TODO: Implement reports navigation
            },
          ),

          // Menu khusus untuk Admin dan Manager
          if (userRole == 'Admin Haikal' || userRole == 'Manager') ...[
            const Divider(),
            _buildDrawerItem(
              context,
              icon: Icons.settings,
              title: 'System Settings',
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
                // TODO: Implement settings navigation
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.security,
              title: 'User Management',
              onTap: () {
                Navigator.pop(context);
                // Navigate to user management
                // TODO: Implement user management navigation
              },
            ),
          ],

          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      onTap: onTap,
    );
  }
}
