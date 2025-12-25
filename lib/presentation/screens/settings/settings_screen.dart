import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/chat_provider.dart'; // For aiConfigProvider
import 'package:ai_assistant_app/domain/entities/ai_config.dart';
import '../../providers/voice_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiConfig = ref.watch(aiConfigProvider);
    final voiceConfig = ref.watch(voiceConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('AI Provider', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<AIProvider>(
            value: aiConfig.provider,
            items: AIProvider.values.map((provider) {
              return DropdownMenuItem(
                value: provider,
                child: Text(provider.toString().split('.').last.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                // Update model name based on provider default
                final defaultModel = value == AIProvider.gemini ? 'gemini-pro' : 'gpt-3.5-turbo';
                ref.read(aiConfigProvider.notifier).state = aiConfig.copyWith(
                  provider: value,
                  modelName: defaultModel,
                );
              }
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          _ModelNameField(
            provider: aiConfigProvider,
          ),
          const SizedBox(height: 24),
          const Text('Notification Settings (Android Only)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Read Notifications'),
            value: ref.watch(notificationEnabledProvider),
            onChanged: (value) {
              ref.read(notificationEnabledProvider.notifier).state = value;
            },
          ),
          SwitchListTile(
            title: const Text('Summarize with AI'),
            subtitle: const Text('If off, reads raw text.'),
            value: ref.watch(notificationSummaryProvider),
            onChanged: ref.watch(notificationEnabledProvider) ? (value) {
              ref.read(notificationSummaryProvider.notifier).state = value;
            } : null,
          ),
          const SizedBox(height: 24),
          const Text('Voice Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          DropdownButtonFormField<VoiceType>(
            value: voiceConfig.type,
            items: VoiceType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.toString().split('.').last.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(voiceConfigProvider.notifier).state = voiceConfig.copyWith(type: value);
              }
            },
            decoration: const InputDecoration(labelText: 'Voice Type', border: OutlineInputBorder()),
          ),
          if (voiceConfig.type == VoiceType.aivis) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: voiceConfig.voiceId,
              items: const [
                DropdownMenuItem(value: '888753760', child: Text('Announcer A')),
                DropdownMenuItem(value: '888753761', child: Text('Announcer B')),
                DropdownMenuItem(value: '888753762', child: Text('Korosuke')),
                DropdownMenuItem(value: '888753763', child: Text('Zundamon')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(voiceConfigProvider.notifier).state = voiceConfig.copyWith(voiceId: value);
                }
              },
              decoration: const InputDecoration(labelText: 'Aivis Speaker', border: OutlineInputBorder()),
            ),
          ],
          const SizedBox(height: 24),
          const Text('AI Character Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _SystemPromptField(
            provider: aiConfigProvider,
          ),
          const SizedBox(height: 24),
          const Text('API Keys (Stored Locally)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _ApiKeyField(
            label: 'Gemini API Key',
            provider: geminiKeyProvider,
          ),
          const SizedBox(height: 16),
          _ApiKeyField(
            label: 'OpenAI API Key',
            provider: openaiKeyProvider,
          ),
          const SizedBox(height: 16),
          _ApiKeyField(
            label: 'Aivis API Key',
            provider: aivisKeyProvider,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final gemini = ref.read(geminiKeyProvider);
              final openai = ref.read(openaiKeyProvider);
              final aivis = ref.read(aivisKeyProvider);

              await ref.read(settingsServiceProvider).saveKeys(
                geminiKey: gemini,
                openAiKey: openai,
                aivisKey: aivis,
                ref: ref,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keys saved securely')));
              }
            },
            child: const Text('Save Keys'),
          ),
        ],
      ),
    );
  }
}

class _ModelNameField extends ConsumerStatefulWidget {
  final StateProvider<AIConfig> provider;

  const _ModelNameField({required this.provider});

  @override
  ConsumerState<_ModelNameField> createState() => _ModelNameFieldState();
}

class _ModelNameFieldState extends ConsumerState<_ModelNameField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(widget.provider);

    // Update controller if the model name changes externally (e.g. provider switch)
    if (_controller.text != config.modelName) {
      _controller.text = config.modelName;
    }

    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        labelText: 'Model Name (e.g. gpt-4o, gemini-1.5-flash)',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        if (value.isNotEmpty) {
          ref.read(widget.provider.notifier).state = config.copyWith(modelName: value);
        }
      },
    );
  }
}

class _SystemPromptField extends ConsumerStatefulWidget {
  final StateProvider<AIConfig> provider;

  const _SystemPromptField({required this.provider});

  @override
  ConsumerState<_SystemPromptField> createState() => _SystemPromptFieldState();
}

class _SystemPromptFieldState extends ConsumerState<_SystemPromptField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(widget.provider);

    // Update controller if the prompt changes externally (e.g. load from storage)
    if (_controller.text != config.systemPrompt && config.systemPrompt.isNotEmpty) {
      // Avoid overwriting if user is typing (checking exact equality handles this usually,
      // but simplistic check is safer if we assume unidirectional flow from state mostly)
      // Since typing updates state, state updates controller... it loops but text remains same.
      // However, initial load from empty -> loaded string needs this.
      if (_controller.text.isEmpty || _controller.text != config.systemPrompt) {
         _controller.text = config.systemPrompt;
      }
    }

    return TextField(
      controller: _controller,
      maxLines: 5,
      decoration: const InputDecoration(
        labelText: 'System Prompt (Persona)',
        border: OutlineInputBorder(),
        hintText: 'You are a helpful assistant...',
      ),
      onChanged: (value) {
        ref.read(widget.provider.notifier).state = config.copyWith(systemPrompt: value);
      },
    );
  }
}

class _ApiKeyField extends ConsumerStatefulWidget {
  final String label;
  final StateProvider<String> provider;

  const _ApiKeyField({required this.label, required this.provider});

  @override
  ConsumerState<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends ConsumerState<_ApiKeyField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to provider state to initialize or update the controller text
    final currentKey = ref.watch(widget.provider);

    // Only update controller if text is empty (initial load) or if it significantly changed externally
    if (_controller.text != currentKey && currentKey.isNotEmpty) {
       _controller.text = currentKey;
    }

    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => ref.read(widget.provider.notifier).state = value,
      obscureText: true,
    );
  }
}
