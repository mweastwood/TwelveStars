import 'package:material_ui/material_ui.dart';
import 'package:twelve_stars/logic/ai_service_helper.dart';
import 'package:twelve_stars/widgets/ai_generation_sheet.dart';

class TranslationExplainerSheet extends StatelessWidget {
  final String originalPhrase;
  final String translatedPhrase;
  final String originalContext;
  final String translatedContext;
  final String originalLang;
  final String translatedLang;

  const TranslationExplainerSheet({
    super.key,
    required this.originalPhrase,
    required this.translatedPhrase,
    required this.originalContext,
    required this.translatedContext,
    required this.originalLang,
    required this.translatedLang,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AiGenerationSheet(
      title: 'Translation Explainer',
      subtitle: '$originalLang ➜ $translatedLang',
      loadingMessage: 'Running AI analysis locally...',
      errorTitle: 'Failed to generate explanation',
      downloadDescription:
          'The on-device Gemini Nano model needs to be downloaded before it can explain translations.',
      emptyResultMessage: 'No explanation generated.',
      generationErrorPrefix: 'Error generating explanation',
      onGenerate: () =>
          LocalAgentHelper.instance.generateTranslationExplanation(
            originalPhrase: originalPhrase,
            translatedPhrase: translatedPhrase,
            originalContext: originalContext,
            translatedContext: translatedContext,
            originalLang: originalLang,
            translatedLang: translatedLang,
          ),
      contextCard: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$originalLang:',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              originalPhrase,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$translatedLang:',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            Text(
              translatedPhrase,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
