import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twelve_stars/logic/confirmation_discernment.dart';
import 'package:twelve_stars/widgets/confirmation_bracket_view.dart';

class ConfirmationChampionView extends StatelessWidget {
  final TournamentState tournament;
  final VoidCallback onRestart;

  const ConfirmationChampionView({
    super.key,
    required this.tournament,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final champion = tournament.champion;
    if (champion == null) return const SizedBox.shrink();
    final saint = champion.saint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation Patron Chosen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Start New Discernment',
            onPressed: onRestart,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Celebration Trophy Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade100.withValues(alpha: 0.8),
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade600, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 56,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'YOUR CONFIRMATION PATRON SAINT',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.3,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      saint.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (saint.dateRange.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        saint.dateRange,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${champion.matchPercentage}% Compatibility Match',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Patron Details Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patronage & Significance',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vocation: ${saint.profession}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (saint.feastDay != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Feast Day: ${saint.feastDay}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      if (saint.patronage != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Patron Saint of: ${saint.patronage}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      if (saint.summary != null) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Biography Summary',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          saint.summary!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Patron Saint Prayer for Confirmation
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_stories,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Confirmation Intercessory Prayer',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        final invocationName = saint.invocationName;
                        return Text(
                          '$invocationName, you lived a life of extraordinary holiness, faith, and love for Jesus Christ. As I prepare for the Sacrament of Confirmation, I choose you as my patron and intercessor before the throne of God. Pray for me that the gifts of the Holy Spirit may be stirred into flame in my life, that I may witness to the Gospel with courage and truth. Amen.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              FilledButton.icon(
                key: const Key('copy_dossier_button'),
                icon: const Icon(Icons.copy),
                label: const Text('Copy Confirmation Saint Dossier'),
                onPressed: () {
                  final invocationName = saint.invocationName;
                  final dossier =
                      '''
CONFIRMATION SAINT DOSSIER
===========================
Patron Saint: ${saint.name}
Dates: ${saint.dateRange}
Feast Day: ${saint.feastDay ?? 'N/A'}
Patronage: ${saint.patronage ?? 'N/A'}
Vocation: ${saint.profession}

BIOGRAPHY & SIGNIFICANCE:
${saint.summary ?? ''}

CONFIRMATION PRAYER:
$invocationName, pray for me as I receive the gifts of the Holy Spirit in Confirmation, that I may follow Christ faithfully all the days of my life. Amen.
''';
                  Clipboard.setData(ClipboardData(text: dossier));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Confirmation dossier copied to clipboard!',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.account_tree),
                label: const Text('View Full Tournament Bracket Recap'),
                onPressed: () =>
                    ConfirmationBracketView.show(context, tournament),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Discern Again (New Quiz & Tournament)'),
                onPressed: onRestart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
