import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Okul Asistanı',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.secondaryLight,
            child: Icon(Icons.person, color: AppColors.error),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),
          _buildFeatureCard(
            context,
            title: 'Nöbet Oluşturucu',
            description: 'Öğretmen nöbet çizelgelerini hızlıca hazırla.',
            icon: Icons.calendar_month_outlined,
            color: AppColors.primary,
            onTap: () {
              context.go('/duty-create');
            },
          ),
          const SizedBox(height: 20),
          _buildFeatureCard(
            context,
            title: 'Kelebek Sınav Sistemi',
            description: 'Sınav salonlarını ve gözetmenleri otomatik ata.',
            icon: Icons.assignment_turned_in_outlined,
            color: AppColors.accent,
            onTap: () {
              context.go('/student-entry');
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Son İşlemler',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildRecentActivityItem(
            context,
            '9-A Sınıfı Nöbet Listesi güncellendi.',
            '2 sa önce',
          ),
          _buildRecentActivityItem(
            context,
            'Matematik sınavı yerleşimi tamamlandı.',
            '5 sa önce',
          ),

          const SizedBox(height: 24),

          Text(
            'Bildirim Özeti',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Yarın yapılacak olan veli toplantısı hatırlatması.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Okul',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
        selectedIndex: 0,
        onDestinationSelected: (idx) {
          if (idx == 1) {
            context.go('/teachers');
          } else if (idx == 2) {
            context.go('/settings');
          }
        },
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
        ],
      ),
    );
  }

  Widget _buildRecentActivityItem(
    BuildContext context,
    String text,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, size: 20, color: AppColors.textLight),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            time,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
