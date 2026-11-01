import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/custom_rule.dart';
import 'services_provider.dart';

class CustomRulesNotifier extends StateNotifier<List<CustomRule>> {
  final Ref _ref;

  CustomRulesNotifier(this._ref, List<CustomRule> initial) : super(initial);

  void addRule(CustomRule rule) {
    state = [...state, rule];
    _ref.read(storageServiceProvider).saveCustomRules(state);
  }

  void updateRule(CustomRule updated) {
    state = [
      for (final r in state)
        if (r.id == updated.id) updated else r
    ];
    _ref.read(storageServiceProvider).saveCustomRules(state);
  }

  void toggleRule(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(enabled: !r.enabled) else r
    ];
    _ref.read(storageServiceProvider).saveCustomRules(state);
  }

  void removeRule(String id) {
    state = state.where((r) => r.id != id).toList();
    _ref.read(storageServiceProvider).saveCustomRules(state);
  }
}

final customRulesProvider = StateNotifierProvider<CustomRulesNotifier, List<CustomRule>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final saved = storage.loadCustomRules();
  
  if (saved.isEmpty) {
    // Provide sensible default rules
    final defaults = [
      const CustomRule(
        id: 'default_ai_rule',
        name: 'AI Assistants (OpenAI & Claude)',
        type: RuleType.domainSuffix,
        values: ['openai.com', 'chatgpt.com', 'claude.ai', 'anthropic.com'],
        outbound: RuleOutbound.proxy,
      ),
      const CustomRule(
        id: 'default_media_rule',
        name: 'Media Streaming (YouTube & Netflix)',
        type: RuleType.geosite,
        values: ['youtube', 'netflix'],
        outbound: RuleOutbound.proxy,
      ),
    ];
    storage.saveCustomRules(defaults);
    return CustomRulesNotifier(ref, defaults);
  }
  return CustomRulesNotifier(ref, saved);
});
