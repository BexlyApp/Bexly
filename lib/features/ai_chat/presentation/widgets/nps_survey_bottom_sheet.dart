import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NPS/CSAT Survey bottom sheet shown after every 10 AI interactions.
/// Collects 1-5 star rating and optional text feedback.
class NpsSurveyBottomSheet extends StatefulWidget {
  final SharedPreferences prefs;

  const NpsSurveyBottomSheet({super.key, required this.prefs});

  /// Check if survey should be shown based on message count
  static bool shouldShow(SharedPreferences prefs) {
    final totalMessages = prefs.getInt(_totalMessagesKey) ?? 0;
    final lastSurveyAt = prefs.getInt(_lastSurveyAtKey) ?? 0;
    // Show every 10 messages since last survey
    return totalMessages > 0 &&
        totalMessages >= lastSurveyAt + 10;
  }

  /// Increment the total AI message counter
  static void incrementMessageCount(SharedPreferences prefs) {
    final current = prefs.getInt(_totalMessagesKey) ?? 0;
    prefs.setInt(_totalMessagesKey, current + 1);
  }

  static const _totalMessagesKey = 'nps_total_ai_messages';
  static const _lastSurveyAtKey = 'nps_last_survey_at_count';
  static const _ratingsKey = 'nps_ratings';

  @override
  State<NpsSurveyBottomSheet> createState() => _NpsSurveyBottomSheetState();
}

class _NpsSurveyBottomSheetState extends State<NpsSurveyBottomSheet> {
  int _rating = 0;
  final _feedbackController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) return;

    // Save rating and mark survey as shown
    final totalMessages = widget.prefs.getInt(NpsSurveyBottomSheet._totalMessagesKey) ?? 0;
    widget.prefs.setInt(NpsSurveyBottomSheet._lastSurveyAtKey, totalMessages);

    // Append rating to local list (for analytics sync later)
    final ratings = widget.prefs.getStringList(NpsSurveyBottomSheet._ratingsKey) ?? [];
    final entry = '${DateTime.now().toIso8601String()}|$_rating|${_feedbackController.text.trim()}';
    ratings.add(entry);
    widget.prefs.setStringList(NpsSurveyBottomSheet._ratingsKey, ratings);

    setState(() => _submitted = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_submitted) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            Text('Thank you!', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How helpful was Bexly AI?',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Your feedback helps us improve',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // Star rating row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = starIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 40,
                    color: starIndex <= _rating ? Colors.amber : Colors.grey.shade400,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Optional feedback text field
          TextField(
            controller: _feedbackController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Any suggestions? (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _rating > 0 ? _submit : null,
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
