import 'dart:convert';

class FunctionCall {
  final String name;
  final Map<String, dynamic> args;

  FunctionCall({required this.name, required this.args});
}

class FunctionParser {
  /// Extracts a JSON function call from a text block.
  /// Looks for a block like ```json { "tool": "..." } ``` or just { "tool": ... }
  static FunctionCall? parse(String text) {
    try {
      // Regex to find JSON-like structures
      final regex = RegExp(r'\{.*"tool"\s*:\s*".*?\}', dotAll: true);
      final match = regex.firstMatch(text);

      if (match != null) {
        final jsonStr = match.group(0)!;
        final Map<String, dynamic> json = jsonDecode(jsonStr);

        if (json.containsKey('tool')) {
          return FunctionCall(
            name: json['tool'],
            args: json,
          );
        }
      }
    } catch (e) {
      // JSON parse error or structure mismatch
      return null;
    }
    return null;
  }
}
