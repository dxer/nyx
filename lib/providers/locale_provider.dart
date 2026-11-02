import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage/storage_service.dart';
import 'services_provider.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return LocaleNotifier(storage);
});

class LocaleNotifier extends StateNotifier<Locale?> {
  final StorageService _storage;
  String _currentLanguageCode = 'system';

  LocaleNotifier(this._storage) : super(null) {
    _loadLocale();
  }

  String get currentLanguageCode => _currentLanguageCode;

  void _loadLocale() {
    final lang = _storage.loadAppLanguage();
    _currentLanguageCode = lang;
    if (lang == 'zh') {
      state = const Locale('zh');
    } else if (lang == 'en') {
      state = const Locale('en');
    } else {
      state = null; // Follow system default
    }
  }

  Future<void> setLanguage(String lang) async {
    _currentLanguageCode = lang;
    if (lang == 'zh') {
      state = const Locale('zh');
    } else if (lang == 'en') {
      state = const Locale('en');
    } else {
      state = null; // Follow system default
    }
    await _storage.saveAppLanguage(lang);
  }
}
