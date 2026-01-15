import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/global_providers.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/teacher_card.dart';
import '../providers/teacher_providers.dart';
import '../../domain/entities/teacher.dart';

class TeacherManagementPage extends ConsumerStatefulWidget {
  const TeacherManagementPage({super.key});

  @override
  ConsumerState<TeacherManagementPage> createState() =>
      _TeacherManagementPageState();
}

class _TeacherManagementPageState extends ConsumerState<TeacherManagementPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _uploadExcel() async {
    final fileService = ref.read(fileServiceProvider);
    final result = await fileService.pickFile();

    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dosya seçilmedi.')));
      }
      return;
    }

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dosya okunamadı.')));
      }
      return;
    }

    // Parse Excel
    final rows = fileService.parseExcel(bytes);

    // Skip header row, map to Teacher
    final uuid = const Uuid();
    int addedCount = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 2) continue;

      final teacher = Teacher(
        id: uuid.v4(),
        name: row[0].toString(),
        branch: row.length > 1 ? row[1].toString() : '',
      );

      ref.read(teachersProvider.notifier).addTeacher(teacher);
      addedCount++;
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$addedCount öğretmen eklendi.')));
    }
  }

  void _showAddTeacherDialog() {
    final nameController = TextEditingController();
    final branchController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Öğretmen Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: branchController,
              decoration: const InputDecoration(
                labelText: 'Branş',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;

              final teacher = Teacher(
                id: const Uuid().v4(),
                name: nameController.text,
                branch: branchController.text,
              );

              ref.read(teachersProvider.notifier).addTeacher(teacher);
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Öğretmen eklendi.')),
              );
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teachers = ref.watch(teachersProvider);

    // Filter by search
    final filteredTeachers = _searchQuery.isEmpty
        ? teachers
        : teachers
              .where(
                (t) =>
                    t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    t.branch.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Öğretmen Yönetimi')),
      body: Column(
        children: [
          // Top Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Öğretmen ara...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _uploadExcel,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Excel Yükle'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Ekle',
                        icon: Icons.add,
                        onPressed: _showAddTeacherDialog,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Teacher List
          Expanded(
            child: filteredTeachers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 64,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz öğretmen eklenmedi.\nExcel yükleyerek veya manuel ekleyebilirsiniz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTeachers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final teacher = filteredTeachers[index];
                      return TeacherCard(
                        name: teacher.name,
                        branch: teacher.branch,
                        dutyCount: 0, // TODO: Calculate from duties
                        onTap: () {
                          // TODO: Show detail/edit dialog
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
