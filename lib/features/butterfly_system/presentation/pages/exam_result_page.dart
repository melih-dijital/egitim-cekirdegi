import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../domain/entities/entities.dart';
import '../providers/butterfly_providers.dart';

class ExamResultPage extends ConsumerStatefulWidget {
  const ExamResultPage({super.key});

  @override
  ConsumerState<ExamResultPage> createState() => _ExamResultPageState();
}

class _ExamResultPageState extends ConsumerState<ExamResultPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Trigger distribution when page loads (or via a button on previous page)
    // For now we assume we trigger it here if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(distributionProvider).valueOrNull?.isEmpty ?? true) {
        final students = ref.read(studentsProvider);
        final halls = ref.read(hallsProvider);
        if (students.isNotEmpty && halls.isNotEmpty) {
          ref.read(distributionProvider.notifier).distribute(students, halls);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final distributionAsync = ref.watch(distributionProvider);
    final students = ref.watch(studentsProvider);
    final halls = ref.watch(hallsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınav Dağıtım Sonucu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF hazırlanıyor...')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Öğrenci Ara (İsim veya Numara)...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
          ),

          // Content
          Expanded(
            child: distributionAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Hata: $err')),
              data: (placements) {
                if (placements.isEmpty) {
                  return const Center(
                    child: Text('Henüz dağıtım yapılmadı veya veri yok.'),
                  );
                }

                // Group placements by Hall
                // This logic normally belongs in a ViewModel/Provider selector
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: halls.length,
                  itemBuilder: (context, index) {
                    final hall = halls[index];
                    final hallPlacements = placements
                        .where((p) => p.hallId == hall.id)
                        .toList();

                    if (hallPlacements.isEmpty) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 8),
                            child: Text(
                              hall.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                            ),
                          ),
                          CustomCard(
                            padding: const EdgeInsets.all(16),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: hallPlacements.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1.8,
                                  ),
                              itemBuilder: (context, sIndex) {
                                final placement = hallPlacements[sIndex];
                                final student = students.firstWhere(
                                  (s) => s.id == placement.studentId,
                                  orElse: () => const Student(
                                    id: '',
                                    number: '',
                                    name: 'Unknown',
                                    className: '',
                                    branch: '',
                                  ),
                                );

                                // Basic filter check
                                if (_searchController.text.isNotEmpty &&
                                    !student.name.toLowerCase().contains(
                                      _searchController.text.toLowerCase(),
                                    ) &&
                                    !student.number.contains(
                                      _searchController.text,
                                    )) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  );
                                }

                                return Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _getClassColor(student.className),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        student.number,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                      Text(
                                        student.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                      ),
                                      Text(
                                        '${student.className}-${student.branch}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontSize: 10,
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dağıtım SMS/E-posta ile bildirildi.'),
            ),
          );
        },
        icon: const Icon(Icons.send),
        label: const Text('Sonuçları Bildir'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Color _getClassColor(String className) {
    if (className.startsWith('9')) return const Color(0xFFE3F2FD); // Light Blue
    if (className.startsWith('10'))
      return const Color(0xFFF3E5F5); // Light Purple
    if (className.startsWith('11'))
      return const Color(0xFFE8F5E9); // Light Green
    if (className.startsWith('12'))
      return const Color(0xFFFFF3E0); // Light Orange
    return AppColors.surface;
  }
}
