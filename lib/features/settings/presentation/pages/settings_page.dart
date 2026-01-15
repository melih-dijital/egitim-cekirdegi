import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _dutyNotifications = true;
  bool _examNotifications = true;
  bool _emailNotifications = false;

  void _showLinkAccountDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Bağla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Kod ile giriş yaptınız. Hesabınızı kalıcı yapmak için e-posta ve şifre belirleyin.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Yeni E-posta'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Yeni Şifre'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog first
              ref
                  .read(authProvider.notifier)
                  .linkEmail(
                    newEmail: emailController.text.trim(),
                    newPassword: passwordController.text,
                  );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch Auth State for user details
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final isShadowAccount =
        user?.email?.contains('temp.okulasistan.com') ?? false;

    // Listen for errors
    ref.listen(authProvider, (prev, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: ${next.error}')));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'HESAP'),
          _buildSettingItem(
            context,
            icon: Icons.person_outline,
            title: 'Profil Bilgileri',
            // Display actual email or placeholder
            subtitle: user?.email ?? 'Giriş yapılmadı',
            onTap: () {},
          ),
          if (isShadowAccount) // Only show if needed
            _buildSettingItem(
              context,
              icon: Icons.link,
              title: 'Hesabı E-postaya Bağla',
              subtitle: 'Kalıcı erişim için bağlayın',
              trailing: const Icon(Icons.warning, color: Colors.orange),
              onTap: _showLinkAccountDialog,
            ),
          const Divider(),
          _buildSectionHeader(context, 'BİLDİRİMLER'),
          _buildSwitchItem(
            context,
            icon: Icons.notifications_active_outlined,
            title: 'Nöbet Bildirimleri',
            value: _dutyNotifications,
            onChanged: (val) => setState(() => _dutyNotifications = val),
          ),
          _buildSwitchItem(
            context,
            icon: Icons.assignment_outlined,
            title: 'Sınav Bildirimleri',
            value: _examNotifications,
            onChanged: (val) => setState(() => _examNotifications = val),
          ),
          _buildSwitchItem(
            context,
            icon: Icons.mail_outline,
            title: 'E-posta Bülteni',
            value: _emailNotifications,
            onChanged: (val) => setState(() => _emailNotifications = val),
          ),
          const Divider(),
          _buildSectionHeader(context, 'OKUL BİLGİLERİ'),
          _buildSettingItem(
            context,
            icon: Icons.school_outlined,
            title: 'Okul Adı',
            subtitle: 'Atatürk Anadolu Lisesi',
            onTap: () {},
          ),
          _buildSettingItem(
            context,
            icon: Icons.info_outline,
            title: 'Uygulama Sürümü',
            subtitle: 'v1.0.0 (Beta)',
            trailing: const SizedBox(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).signOut();
                context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          trailing ??
          const Icon(Icons.chevron_right, color: AppColors.textLight),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      activeTrackColor: AppColors.primary,
      activeThumbColor: Colors.white,
      value: value,
      onChanged: onChanged,
    );
  }
}
