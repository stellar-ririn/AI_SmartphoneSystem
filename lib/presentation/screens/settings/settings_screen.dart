import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/chat_provider.dart'; // For aiConfigProvider
import 'package:ai_assistant_app/domain/entities/ai_config.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiConfig = ref.watch(aiConfigProvider);

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
          const SizedBox(height: 24),
          const Text('AI Character Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: aiConfig.systemPrompt,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'System Prompt (Persona)',
              border: OutlineInputBorder(),
              hintText: 'You are a helpful assistant...',
            ),
            onChanged: (value) {
              ref.read(aiConfigProvider.notifier).state = aiConfig.copyWith(systemPrompt: value);
            },
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
