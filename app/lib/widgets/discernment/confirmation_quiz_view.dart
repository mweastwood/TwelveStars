import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/confirmation_discernment.dart';

class ConfirmationQuizView extends StatefulWidget {
  final List<DiscernmentQuestion> questions;
  final VoidCallback onRestart;
  final void Function(Map<String, int> selectedAnswers) onComplete;

  const ConfirmationQuizView({
    super.key,
    required this.questions,
    required this.onRestart,
    required this.onComplete,
  });

  @override
  State<ConfirmationQuizView> createState() => _ConfirmationQuizViewState();
}

class _ConfirmationQuizViewState extends State<ConfirmationQuizView> {
  int _currentQuestionIndex = 0;
  final Map<String, int> _selectedAnswers = {};

  @override
  void didUpdateWidget(covariant ConfirmationQuizView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.questions != oldWidget.questions) {
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
    }
  }

  void _handleRestart() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswers.clear();
    });
    widget.onRestart();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentQ = widget.questions[_currentQuestionIndex];
    final selectedOption = _selectedAnswers[currentQ.id];
    final isLastQuestion = _currentQuestionIndex == widget.questions.length - 1;
    final canProceed = selectedOption != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation Discernment'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Restart'),
            onPressed: _handleRestart,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / widget.questions.length,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: theme.colorScheme.primary,
              minHeight: 6,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'QUESTION ${_currentQuestionIndex + 1} OF ${widget.questions.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Question Card & Options
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      currentQ.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (int i = 0; i < currentQ.options.length; i++)
                      _buildOptionTile(
                        context,
                        option: currentQ.options[i],
                        index: i,
                        isSelected: selectedOption == i,
                        onTap: () {
                          setState(() {
                            _selectedAnswers[currentQ.id] = i;
                          });
                        },
                        theme: theme,
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      onPressed: () {
                        setState(() {
                          _currentQuestionIndex--;
                        });
                      },
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    key: const Key('discernment_next_button'),
                    icon: Icon(
                      isLastQuestion ? Icons.emoji_events : Icons.arrow_forward,
                    ),
                    label: Text(
                      isLastQuestion ? 'Start Tournament' : 'Next Question',
                    ),
                    onPressed: canProceed
                        ? () {
                            if (isLastQuestion) {
                              widget.onComplete(_selectedAnswers);
                            } else {
                              setState(() {
                                _currentQuestionIndex++;
                              });
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required DiscernmentOption option,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        key: Key('discernment_option_$index'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (option.icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    option.icon,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.text,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (option.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        option.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
