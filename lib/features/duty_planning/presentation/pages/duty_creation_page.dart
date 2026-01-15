import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../providers/duty_providers.dart';

class DutyCreationPage extends ConsumerStatefulWidget {
  const DutyCreationPage({super.key});

  @override
  ConsumerState<DutyCreationPage> createState() => _DutyCreationPageState();
}

class _DutyCreationPageState extends ConsumerState<DutyCreationPage> {
  int _currentStep = 0;
  DateTimeRange? _selectedDateRange;

  final Map<String, bool> _dutyAreas = {
    'Okul Bahçesi': true,
    'Zemin Kat Koridor': true,
    '1. Kat Koridor': true,
    '2. Kat Koridor': true,
    'Kantin': true,
    'Spor Salonu': false,
  };

  void _onStepContinue() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep += 1;
      });
    } else {
      // Trigger creation via Riverpod
      if (_selectedDateRange == null) return;

      final activeAreas = _dutyAreas.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      ref
          .read(dutyCreationProvider.notifier)
          .createPlan(
            start: _selectedDateRange!.start,
            end: _selectedDateRange!.end,
            areas: activeAreas,
          );
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to creation state
    ref.listen(dutyCreationProvider, (previous, next) {
      next.when(
        data: (_) {
          if (previous?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nöbet planı başarıyla oluşturuldu.'),
              ),
            );
            context.go('/duty-result'); // Navigate to result
          }
        },
        error: (err, stack) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $err')));
        },
        loading: () {},
      );
    });

    final creationState = ref.watch(dutyCreationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nöbet Planı Oluştur')),
      body: Stack(
        children: [
          Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: _currentStep == 2 ? 'Planı Oluştur' : 'Devam Et',
                        onPressed: details.onStepContinue ?? () {},
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.textLight),
                            foregroundColor: AppColors.textSecondary,
                          ),
                          child: const Text('Geri'),
                        ),
                      ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Tarih Aralığı'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nöbet çizelgesinin geçerli olacağı tarih aralığını seçin.',
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  onSurface: AppColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDateRange = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.textLight),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _selectedDateRange == null
                                  ? 'Tarih Aralığı Seçiniz'
                                  : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                isActive: _currentStep >= 0,
                state: _currentStep > 0
                    ? StepState.complete
                    : StepState.indexed,
              ),
              Step(
                title: const Text('Nöbet Alanları'),
                content: Column(
                  children: _dutyAreas.keys.map((String key) {
                    return CheckboxListTile(
                      title: Text(key),
                      value: _dutyAreas[key],
                      activeColor: AppColors.primary,
                      onChanged: (bool? value) {
                        setState(() {
                          _dutyAreas[key] = value ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
                isActive: _currentStep >= 1,
                state: _currentStep > 1
                    ? StepState.complete
                    : StepState.indexed,
              ),
              Step(
                title: const Text('Özet ve Onay'),
                content: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryRow(
                        'Tarih:',
                        _selectedDateRange != null
                            ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}'
                            : 'Seçilmedi',
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Aktif Alanlar:',
                        '${_dutyAreas.values.where((e) => e).length} Adet',
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Otomatik dağıtım algoritması çalıştırılarak öğretmenlerin ders programına uygun en iyi yerleşim yapılacaktır.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                isActive: _currentStep >= 2,
              ),
            ],
          ),
          if (creationState.isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }
}
