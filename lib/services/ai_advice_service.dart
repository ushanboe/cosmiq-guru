import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiAdviceService {
  AiAdviceService._();

  /// Generate personalised cosmic advice via LLM API.
  /// Falls back to [fallbackAdvice] if no API key or on error.
  static Future<String> generateAdvice({
    required String question,
    required String category,
    required int score,
    required String riskLevel,
    required String moonPhase,
    required int personalDay,
    required String dasaPlanet,
    required String archetypeName,
    required String bestWindow,
    required String luckyColor,
    required String luckyDirection,
    required int luckyNumber,
    required Map<String, int> systemScores,
    required String fallbackAdvice,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('ai_api_key') ?? '';
    final provider = prefs.getString('ai_provider') ?? 'OpenAI';

    if (apiKey.isEmpty) return fallbackAdvice;

    final prompt = _buildPrompt(
      question: question,
      category: category,
      score: score,
      riskLevel: riskLevel,
      moonPhase: moonPhase,
      personalDay: personalDay,
      dasaPlanet: dasaPlanet,
      archetypeName: archetypeName,
      bestWindow: bestWindow,
      luckyColor: luckyColor,
      luckyDirection: luckyDirection,
      luckyNumber: luckyNumber,
      systemScores: systemScores,
    );

    try {
      if (provider == 'Anthropic') {
        return await _callAnthropic(apiKey, prompt);
      } else {
        return await _callOpenAI(apiKey, prompt);
      }
    } catch (_) {
      return fallbackAdvice;
    }
  }

  static String _buildPrompt({
    required String question,
    required String category,
    required int score,
    required String riskLevel,
    required String moonPhase,
    required int personalDay,
    required String dasaPlanet,
    required String archetypeName,
    required String bestWindow,
    required String luckyColor,
    required String luckyDirection,
    required int luckyNumber,
    required Map<String, int> systemScores,
  }) {
    final scoresStr = systemScores.entries
        .map((e) => '${e.key}: ${e.value}/100')
        .join(', ');

    return '''You are a mystical cosmic advisor speaking to someone who asked: "$question"

Category: $category
Overall Cosmic Score: $score/100 (Risk: $riskLevel)
Moon Phase: $moonPhase
Personal Day Number: $personalDay
Current Dasa Planet: $dasaPlanet
Soul Archetype: $archetypeName
Best Timing Window: $bestWindow
Lucky Color: $luckyColor | Direction: $luckyDirection | Number: $luckyNumber

System Scores: $scoresStr

Write a personalised 3-4 sentence cosmic reading that:
- Directly addresses their specific question "$question"
- References 2-3 of the cosmic data points naturally (moon phase, archetype, planetary influence, etc.)
- Gives clear actionable guidance (yes/no/wait/proceed with caution)
- Feels mystical and wise, not generic
- Does NOT list the scores or repeat data verbatim

Reply with ONLY the advice text, no quotes, no labels, no markdown.''';
  }

  static Future<String> _callOpenAI(String apiKey, String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 200,
        'temperature': 0.9,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return '';

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List;
    if (choices.isEmpty) return '';
    final message = choices[0]['message'] as Map<String, dynamic>;
    return (message['content'] as String).trim();
  }

  static Future<String> _callAnthropic(String apiKey, String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-haiku-4-5-20251001',
        'max_tokens': 200,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return '';

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final content = json['content'] as List;
    if (content.isEmpty) return '';
    return (content[0]['text'] as String).trim();
  }
}
