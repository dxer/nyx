import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/singbox/singbox_service.dart';
import '../../services/storage/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Initialize storageService in main() first');
});

final singBoxServiceProvider = Provider<SingBoxService>((ref) {
  return SingBoxServiceImpl();
});
