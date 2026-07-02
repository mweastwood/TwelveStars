import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/rosary_helper.dart';
import 'package:twelve_stars/widgets/prayer_card.dart';
import 'package:twelve_stars/widgets/rosary_bead_chain.dart';
import 'package:twelve_stars/widgets/rosary_mystery_card.dart';

class RosaryTab extends StatefulWidget {
  final List<Prayer>? prayers;
  final PrayerLanguage primaryLanguage;
  final PrayerLanguage compareLanguage;
  final Function(String) onLaunchSource;

  const RosaryTab({
    super.key,
    this.prayers,
    required this.primaryLanguage,
    required this.compareLanguage,
    required this.onLaunchSource,
  });

  @override
  State<RosaryTab> createState() => _RosaryTabState();
}

class _RosaryTabState extends State<RosaryTab> {
  RosaryMysteryType _mysteryType = RosaryMysteryType.joyful;
  int _currentStep = 0;
  late List<RosaryStep> _steps;
  final Map<String, int> _preferredVersions = {};

  @override
  void initState() {
    super.initState();
    _generateSteps();
  }

  void _generateSteps() {
    _steps = RosaryHelper.generateSteps(_mysteryType);
  }

  void _changeMysteryType(RosaryMysteryType? type) {
    if (type == null || type == _mysteryType) return;
    setState(() {
      _mysteryType = type;
      _generateSteps();
      _currentStep = 0;
    });
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _showFinishDialog();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _resetRosary() {
    setState(() {
      _currentStep = 0;
    });
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          icon: Icon(
            Icons.check_circle_outline,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          title: const Text('Rosary Completed'),
          content: const Text(
            'May the peace of the Lord be with you. You have completed the Rosary.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetRosary();
              },
              child: const Text('Amen'),
            ),
          ],
        );
      },
    );
  }

  Prayer? _findPrayer(String prayerId) {
    if (widget.prayers == null) return null;
    for (final p in widget.prayers!) {
      if (p.prayerId == prayerId) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeStep = _steps[_currentStep];

    final prayer1 = _findPrayer(activeStep.prayerId);
    final prayer2 = activeStep.secondaryPrayerId != null
        ? _findPrayer(activeStep.secondaryPrayerId!)
        : null;
    final prayer3 = activeStep.tertiaryPrayerId != null
        ? _findPrayer(activeStep.tertiaryPrayerId!)
        : null;

    final langSuffix = widget.primaryLanguage.toString().split('.').last;
    final prefKey1 = '${activeStep.prayerId}_$langSuffix';
    final initialVersion1 = _preferredVersions[prefKey1] ?? 0;

    final prefKey2 = activeStep.secondaryPrayerId != null
        ? '${activeStep.secondaryPrayerId}_$langSuffix'
        : '';
    final initialVersion2 = activeStep.secondaryPrayerId != null
        ? (_preferredVersions[prefKey2] ?? 0)
        : 0;

    final prefKey3 = activeStep.tertiaryPrayerId != null
        ? '${activeStep.tertiaryPrayerId}_$langSuffix'
        : '';
    final initialVersion3 = activeStep.tertiaryPrayerId != null
        ? (_preferredVersions[prefKey3] ?? 0)
        : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 600.0;

        return SizedBox(
          height: maxHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bead rail on the left
              RosaryBeadChain(
                steps: _steps,
                currentStep: _currentStep,
                onStepSelected: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
              ),
              // Main content area on the right
              Expanded(
                child: Column(
                  children: [
                    // Mystery selector at the top
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<RosaryMysteryType>(
                              initialValue: _mysteryType,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Select Mysteries',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: RosaryMysteryType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text('${type.name} (${type.days})'),
                                );
                              }).toList(),
                              onChanged: _changeMysteryType,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Scrollable content & Floating Bottom controls
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                16.0,
                                8.0,
                                16.0,
                                80.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Active Mystery Card
                                  if (activeStep.mystery != null) ...[
                                    RosaryMysteryCard(
                                      mystery: activeStep.mystery!,
                                      mysteryType: _mysteryType,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  // Prayer Card 1
                                  if (prayer1 != null) ...[
                                    PrayerCard(
                                      key: ValueKey(
                                        '${activeStep.prayerId}_$_currentStep',
                                      ),
                                      prayer: prayer1,
                                      selectedLanguage: widget.primaryLanguage,
                                      compareLanguage: widget.compareLanguage,
                                      initialVersionIndex: initialVersion1,
                                      onVersionChanged: (newIndex) {
                                        setState(() {
                                          _preferredVersions[prefKey1] =
                                              newIndex;
                                        });
                                      },
                                      onLaunchSource: widget.onLaunchSource,
                                    ),
                                  ] else ...[
                                    Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Center(
                                          child: Text(
                                            'Prayer "${activeStep.prayerId}" not found in database.',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.error,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  // Prayer Card 2 (if Fatima / Final Prayer is also present in step)
                                  if (prayer2 != null) ...[
                                    const SizedBox(height: 8),
                                    PrayerCard(
                                      key: ValueKey(
                                        '${activeStep.secondaryPrayerId!}_$_currentStep',
                                      ),
                                      prayer: prayer2,
                                      selectedLanguage: widget.primaryLanguage,
                                      compareLanguage: widget.compareLanguage,
                                      initialVersionIndex: initialVersion2,
                                      onVersionChanged: (newIndex) {
                                        setState(() {
                                          _preferredVersions[prefKey2] =
                                              newIndex;
                                        });
                                      },
                                      onLaunchSource: widget.onLaunchSource,
                                    ),
                                  ],
                                  // Prayer Card 3 (if Sign of the Cross closing prayer is also present in step)
                                  if (prayer3 != null) ...[
                                    const SizedBox(height: 8),
                                    PrayerCard(
                                      key: ValueKey(
                                        '${activeStep.tertiaryPrayerId!}_$_currentStep',
                                      ),
                                      prayer: prayer3,
                                      selectedLanguage: widget.primaryLanguage,
                                      compareLanguage: widget.compareLanguage,
                                      initialVersionIndex: initialVersion3,
                                      onVersionChanged: (newIndex) {
                                        setState(() {
                                          _preferredVersions[prefKey3] =
                                              newIndex;
                                        });
                                      },
                                      onLaunchSource: widget.onLaunchSource,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          // Floating Bottom controls
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                children: [
                                  Tooltip(
                                    message: 'Reset Rosary',
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: const CircleBorder(),
                                        padding: const EdgeInsets.all(12),
                                      ),
                                      onPressed: _resetRosary,
                                      child: const Icon(Icons.replay),
                                    ),
                                  ),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('Back'),
                                    onPressed: _currentStep > 0
                                        ? _prevStep
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  FilledButton.icon(
                                    icon: Icon(
                                      _currentStep == _steps.length - 1
                                          ? Icons.check
                                          : Icons.arrow_forward,
                                    ),
                                    label: Text(
                                      _currentStep == _steps.length - 1
                                          ? 'Finish'
                                          : 'Next',
                                    ),
                                    onPressed: _nextStep,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
