import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('API Keys (Stored Locally)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Gemini API Key',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => ref.read(geminiKeyProvider.notifier).state = value,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'OpenAI API Key',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => ref.read(openaiKeyProvider.notifier).state = value,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Aivis API Key',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => ref.read(aivisKeyProvider.notifier).state = value,
            obscureText: true,
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
