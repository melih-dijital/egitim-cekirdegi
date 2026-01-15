import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../domain/entities/entities.dart';
import '../providers/butterfly_providers.dart';

class StudentEntryPage extends ConsumerWidget {
  const StudentEntryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Öğrenci Veri Girişi'),
          actions: [
            TextButton.icon(
              onPressed: () {
                context.push('/exam-hall');
              },
              icon: const Icon(Icons.meeting_room),
              label: const Text('Salon Yönetimi'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Excel Yükle', icon: Icon(Icons.upload_file)),
              Tab(text: 'Manuel Ekle', icon: Icon(Icons.person_add)),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
          ),
        ),
        body: const TabBarView(
          children: [_ExcelUploadTab(), _ManualEntryTab()],
        ),
      ),
    );
  }
}

class _ExcelUploadTab extends ConsumerWidget {
  const _ExcelUploadTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.textLight,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Excel Dosyasını Sürükleyin veya Seçin',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(studentsProvider.notifier)
                          .pickAndImportFile();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dosya işlendi ve listeye eklendi.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Dosya Seç'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Desteklenen Formatlar: .xlsx, .csv\nÖrnek şablonu indirmek için tıklayınız.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualEntryTab extends ConsumerStatefulWidget {
  const _ManualEntryTab();

  @override
  ConsumerState<_ManualEntryTab> createState() => _ManualEntryTabState();
}

class _ManualEntryTabState extends ConsumerState<_ManualEntryTab> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClass;
  String? _selectedBranch;
  final _numberController = TextEditingController();
  final _nameController = TextEditingController();

  final List<String> _classes = ['9', '10', '11', '12'];
  final List<String> _branches = ['A', 'B', 'C', 'D', 'E'];

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _saveStudent() {
    if (_formKey.currentState!.validate()) {
      final student = Student(
        id: const Uuid().v4(),
        number: _numberController.text,
        name: _nameController.text,
        className: _selectedClass!,
        branch: _selectedBranch!,
      );

      // Add to list via notifier
      ref.read(studentsProvider.notifier).addStudent(student);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Öğrenci listeye eklendi.')));

      // Reset form
      _formKey.currentState!.reset();
      _numberController.clear();
      _nameController.clear();
      setState(() {
        _selectedClass = null;
        _selectedBranch = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: const InputDecoration(labelText: 'Sınıf'),
                    items: _classes
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text('$c. Sınıf'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedClass = val),
                    validator: (val) => val == null ? 'Zorunlu' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedBranch,
                    decoration: const InputDecoration(labelText: 'Şube'),
                    items: _branches
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text('$b Şubesi'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedBranch = val),
                    validator: (val) => val == null ? 'Zorunlu' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Okul Numarası',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Numara giriniz';
                if (int.tryParse(val) == null) return 'Geçersiz numara';
                return null;
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (val) => (val == null || val.length < 3)
                  ? 'Geçerli bir isim giriniz'
                  : null,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Listeye Ekle',
              icon: Icons.add,
              onPressed: _saveStudent,
            ),
            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/exam-result');
                },
                icon: const Icon(Icons.play_circle_fill),
                label: const Text('KELEBEK SİSTEMİNİ ÇALIŞTIR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Show student count
            Consumer(
              builder: (context, ref, _) {
                final studentCount = ref.watch(studentsProvider).length;
                return Center(child: Text('Toplam Öğrenci: $studentCount'));
              },
            ),
          ],
        ),
      ),
    );
  }
}
