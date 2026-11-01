import 'custom_rule.dart';

class RulePresetKit {
  final String id;
  final String title;
  final String icon;
  final String description;
  final RuleType type;
  final List<String> values;
  final RuleOutbound defaultOutbound;

  const RulePresetKit({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.type,
    required this.values,
    this.defaultOutbound = RuleOutbound.proxy,
  });

  static const List<RulePresetKit> presets = [
    RulePresetKit(
      id: 'preset_ai_platforms',
      title: 'AI Assistants Suite',
      icon: '🤖',
      description: 'OpenAI, ChatGPT, Claude, Anthropic, Gemini, Copilot',
      type: RuleType.domainSuffix,
      defaultOutbound: RuleOutbound.proxy,
      values: [
        'openai.com',
        'chatgpt.com',
        'claude.ai',
        'anthropic.com',
        'oaistatic.com',
        'oaiusercontent.com',
        'sora.com',
        'gemini.google.com',
        'copilot.microsoft.com',
      ],
    ),
    RulePresetKit(
      id: 'preset_media_streaming',
      title: 'Global Streaming Media',
      icon: '🎬',
      description: 'YouTube, Netflix, Disney+, Spotify, HBO Max',
      type: RuleType.domainSuffix,
      defaultOutbound: RuleOutbound.proxy,
      values: [
        'youtube.com',
        'googlevideo.com',
        'ytimg.com',
        'netflix.com',
        'nflxvideo.net',
        'nflximg.net',
        'disneyplus.com',
        'spotify.com',
        'hbo.com',
      ],
    ),
    RulePresetKit(
      id: 'preset_developer_tools',
      title: 'Developer Cloud & Repos',
      icon: '💻',
      description: 'GitHub, Docker, StackOverflow, HuggingFace, Vercel',
      type: RuleType.domainSuffix,
      defaultOutbound: RuleOutbound.proxy,
      values: [
        'github.com',
        'githubusercontent.com',
        'docker.com',
        'docker.io',
        'huggingface.co',
        'stackoverflow.com',
        'vercel.app',
      ],
    ),
    RulePresetKit(
      id: 'preset_domestic_office',
      title: 'Domestic Office Direct',
      icon: '💼',
      description: 'Feishu/Lark, DingTalk, WeChat Work, Tencent Meeting',
      type: RuleType.domainSuffix,
      defaultOutbound: RuleOutbound.direct,
      values: [
        'feishu.cn',
        'larksuite.com',
        'dingtalk.com',
        'work.weixin.qq.com',
        'tencent.com',
        'meeting.tencent.com',
      ],
    ),
  ];
}
