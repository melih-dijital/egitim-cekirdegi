import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Admin Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Teacher Controller
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _loginAdmin() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurunuz.')),
      );
      return;
    }
    ref
        .read(authProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
  }

  void _loginTeacher() {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen 6 haneli kodu giriniz.')),
      );
      return;
    }
    // Password is null for code login (handled in repo)
    ref.read(authProvider.notifier).login(_codeController.text.trim(), null);
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes
    ref.listen<AsyncValue>(authProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            context.go('/'); // Navigate to Dashboard
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $error')));
        },
        loading: () {},
      );
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Area
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Okul Asistanı',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hoş Geldiniz',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              // Login Card
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: CustomCard(
                  padding: EdgeInsets
                      .zero, // Card handles its own padding? No check CustomCard
                  child: Column(
                    children: [
                      // Tabs
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textLight,
                        indicatorColor: AppColors.primary,
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: const [
                          Tab(text: 'Yönetici Girişi'),
                          Tab(text: 'Öğretmen Girişi'),
                        ],
                      ),

                      // Tab Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          height: 320, // Check height
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Admin Login View
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'E-posta Adresi',
                                      prefixIcon: Icon(Icons.email_outlined),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Şifre',
                                      prefixIcon: Icon(Icons.lock_outline),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : CustomButton(
                                          text: 'Giriş Yap',
                                          onPressed: _loginAdmin,
                                        ),
                                  const Spacer(),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Center(child: _buildSocialLoginRow()),
                                ],
                              ),

                              // Teacher Login View
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Size verilen 6 haneli kodu giriniz.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  TextField(
                                    controller: _codeController,
                                    textAlign: TextAlign.center,
                                    maxLength: 6,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      letterSpacing: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '000000',
                                      counterText: '',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : CustomButton(
                                          text: 'Kodu Doğrula',
                                          icon: Icons.vpn_key_outlined,
                                          onPressed: _loginTeacher,
                                        ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Hesabınız yok mu? '),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Kayıt Ol'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '© 2026 Okul Çekirdeği Sistemleri',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(Icons.g_mobiledata, () {}),
        const SizedBox(width: 16),
        _buildSocialButton(Icons.apple, () {}),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textLight.withValues(alpha: 0.3)),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 24),
      ),
    );
  }
}
