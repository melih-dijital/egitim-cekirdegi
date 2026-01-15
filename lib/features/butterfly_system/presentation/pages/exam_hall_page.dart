import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../domain/entities/entities.dart';
import '../providers/butterfly_providers.dart';

class ExamHallPage extends ConsumerStatefulWidget {
  const ExamHallPage({super.key});

  @override
  ConsumerState<ExamHallPage> createState() => _ExamHallPageState();
}

class _ExamHallPageState extends ConsumerState<ExamHallPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  double _columnCount = 4;

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int capacity = int.tryParse(_capacityController.text) ?? 20;

    return Scaffold(
      appBar: AppBar(title: const Text('Salon Tanımlama')),
      body: Row(
        children: [
          // Left Side: Form
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Salon Bilgileri',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Salon Adı',
                        hintText: 'Örn: 9-A Sınıfı',
                        prefixIcon: Icon(Icons.meeting_room_outlined),
                      ),
                      validator: (val) =>
                          val?.isEmpty ?? true ? 'Zorunlu' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(
                        labelText: 'Sıra Kapasitesi',
                        hintText: 'Örn: 20',
                        prefixIcon: Icon(Icons.event_seat_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => setState(() {}),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Zorunlu';
                        if (int.tryParse(val) == null) return 'Sayı giriniz';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sütun Düzeni: ${_columnCount.toInt()}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Slider(
                      value: _columnCount,
                      min: 2,
                      max: 8,
                      divisions: 6,
                      label: _columnCount.toInt().toString(),
                      onChanged: (val) {
                        setState(() {
                          _columnCount = val;
                        });
                      },
                    ),
                    const Spacer(),
                    CustomButton(
                      text: 'Salonu Kaydet',
                      icon: Icons.save,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final hall = ExamHall(
                            id: const Uuid().v4(),
                            name: _nameController.text,
                            capacity: capacity,
                            columnCount: _columnCount.toInt(),
                          );

                          ref
                              .read(hallsProvider.notifier)
                              .update((state) => [...state, hall]);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Salon başarıyla kaydedildi.'),
                            ),
                          );

                          _nameController.clear();
                          _capacityController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right Side: Visual Preview
          Expanded(
            flex: 3,
            child: Container(
              color: AppColors.surfaceVariant,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Sıra Düzeni Önizleme',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        constraints: const BoxConstraints(maxWidth: 500),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Teacher Desk
                            Container(
                              width: 120,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Öğretmen Masası',
                                style: TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Students Grid
                            Expanded(
                              child: GridView.builder(
                                itemCount: capacity,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _columnCount.toInt(),
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.5,
                                    ),
                                itemBuilder: (context, index) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.textLight.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: AppColors.textLight,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
