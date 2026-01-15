import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/csv_service.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';
import '../../features/duty_planning/domain/logic/duty_distributor.dart';
import '../../features/butterfly_system/domain/logic/butterfly_distributor.dart';

// Services
final fileServiceProvider = Provider<FileService>((ref) => FileService());
final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());
final csvServiceProvider = Provider<CsvService>((ref) => CsvService());

// Logic
final dutyDistributorProvider = Provider<DutyDistributor>(
  (ref) => DutyDistributor(),
);
final butterflyDistributorProvider = Provider<ButterflyDistributor>(
  (ref) => ButterflyDistributor(),
);
