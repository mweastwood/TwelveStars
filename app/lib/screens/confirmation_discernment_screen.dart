import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/confirmation_discernment.dart';
import 'package:twelve_stars/logic/saint_database.dart';
import 'package:twelve_stars/logic/saint_models.dart';
import 'package:twelve_stars/widgets/discernment/confirmation_champion_view.dart';
import 'package:twelve_stars/widgets/discernment/confirmation_quiz_view.dart';
import 'package:twelve_stars/widgets/discernment/confirmation_tournament_view.dart';

enum DiscernmentStage { quiz, tournament, champion }

/// Interactive Confirmation Saint Discernment screen featuring a dynamic quiz,
/// vector-similarity seeding, and a 16-entrant head-to-head tournament bracket.
class ConfirmationDiscernmentScreen extends StatefulWidget {
  final List<DiscernmentQuestion>? initialQuestions;

  const ConfirmationDiscernmentScreen({super.key, this.initialQuestions});

  @override
  State<ConfirmationDiscernmentScreen> createState() =>
      _ConfirmationDiscernmentScreenState();
}

class _ConfirmationDiscernmentScreenState
    extends State<ConfirmationDiscernmentScreen> {
  List<Saint> _allSaints = [];
  bool _loading = true;
  String? _error;

  DiscernmentStage _stage = DiscernmentStage.quiz;
  List<DiscernmentQuestion> _activeQuestions = [];
  TournamentState? _tournament;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final saints = await SaintDatabase.loadSaints();
      final questions =
          widget.initialQuestions ??
          ConfirmationDiscernmentEngine.selectQuestions(count: 14);
      if (mounted) {
        setState(() {
          _allSaints = saints;
          _activeQuestions = questions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _restartDiscernment() {
    setState(() {
      _stage = DiscernmentStage.quiz;
      _activeQuestions =
          widget.initialQuestions ??
          ConfirmationDiscernmentEngine.selectQuestions(count: 14);
      _tournament = null;
    });
  }

  void _startTournament(Map<String, int> selectedAnswers) {
    if (_allSaints.isEmpty) return;

    final userVector = ConfirmationDiscernmentEngine.calculateUserVector(
      selectedAnswers,
      _activeQuestions,
    );

    final seeds = ConfirmationDiscernmentEngine.generateTournamentSeeds(
      allSaints: _allSaints,
      userVector: userVector,
      noiseMagnitude: 0.08,
    );

    final tournament = ConfirmationDiscernmentEngine.createTournament(seeds);

    setState(() {
      _tournament = tournament;
      _stage = DiscernmentStage.tournament;
    });
  }

  void _selectWinner(TournamentSeed winner) {
    if (_tournament == null) return;

    setState(() {
      _tournament!.recordWinner(winner);
      if (_tournament!.isComplete) {
        _stage = DiscernmentStage.champion;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirmation Discernment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirmation Discernment')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _initialize();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    switch (_stage) {
      case DiscernmentStage.quiz:
        return ConfirmationQuizView(
          questions: _activeQuestions,
          onRestart: _restartDiscernment,
          onComplete: _startTournament,
        );
      case DiscernmentStage.tournament:
        final tournament = _tournament;
        if (tournament == null) return const SizedBox.shrink();
        return ConfirmationTournamentView(
          tournament: tournament,
          onSelectWinner: _selectWinner,
        );
      case DiscernmentStage.champion:
        final tournament = _tournament;
        if (tournament == null) return const SizedBox.shrink();
        return ConfirmationChampionView(
          tournament: tournament,
          onRestart: _restartDiscernment,
        );
    }
  }
}
