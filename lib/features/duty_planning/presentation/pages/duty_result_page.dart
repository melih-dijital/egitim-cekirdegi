import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/duty_result_row.dart';
import '../providers/duty_providers.dart';

import '../../../../core/providers/global_providers.dart';

class DutyResultPage extends ConsumerStatefulWidget {
  const DutyResultPage({super.key});

  @override
  ConsumerState<DutyResultPage> createState() => _DutyResultPageState();
}

class _DutyResultPageState extends ConsumerState<DutyResultPage> {
  // Simple state for filter, could be moved to provider if needed globally
  String? _filterArea;

  @override
  void initState() {
    super.initState();
    // Auto-load if empty (optional)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // We can trigger distribution or fetch initial data here
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the list provider
    final dutyListAsync = ref.watch(dutyListProvider);
    final duties = dutyListAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nöbet Çizelgesi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () {
              if (duties.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Liste boş.')));
                return;
              }
              ref
                  .read(pdfServiceProvider)
                  .printDutyPlan(duties, 'Nöbet Çizelgesi');
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: () {
              if (duties.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Liste boş.')));
                return;
              }
              // In a real web app we would download, for now just generate string (logic is there)
              ref.read(csvServiceProvider).generateDutyCsv(duties);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV oluşturuldu (Demo).')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(dutyListProvider.notifier).distributeDuties();
        },
        label: const Text('Dağıtımı Başlat'),
        icon: const Icon(Icons.refresh),
      ),
      body: Column(
        children: [
          // Filter & Notification Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        hint: const Text('Nöbet Yeri Filtrele'),
                        value: _filterArea,
                        icon: const Icon(Icons.filter_list),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Tümü')),
                          DropdownMenuItem(
                            value: 'Okul Bahçesi',
                            child: Text('Okul Bahçesi'),
                          ),
                          DropdownMenuItem(
                            value: '1. Kat Koridor',
                            child: Text('1. Kat Koridor'),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _filterArea = val;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  text: 'Bildir',
                  icon: Icons.send,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Öğretmenlere bildirim gönderildi.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: AppColors.primaryLight.withValues(alpha: 0.5),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'TARİH',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'NÖBET YERİ',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'ÖĞRETMEN',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: dutyListAsync.when(
              data: (duties) {
                // Client-side filtering
                final filteredDuties = _filterArea == null
                    ? duties
                    : duties.where((d) => d.area == _filterArea).toList();

                if (filteredDuties.isEmpty) {
                  return const Center(
                    child: Text(
                      'Kayıt bulunamadı. "Dağıtımı Başlat" butonuna basınız.',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDuties.length,
                  itemBuilder: (context, index) {
                    final duty = filteredDuties[index];
                    return DutyResultRow(
                      date:
                          '${duty.date.day}.${duty.date.month}.${duty.date.year}',
                      dutyArea: duty.area,
                      teacherName: duty.teacherName,
                      isAlt: index % 2 != 0,
                    );
                  },
                );
              },
              error: (err, stack) => Center(child: Text('Hata: $err')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}
