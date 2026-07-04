import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/logic/prayer_database.dart';
import 'package:twelve_stars/logic/liturgical_calendar.dart';
import 'package:twelve_stars/logic/time_helper.dart';
import 'package:twelve_stars/logic/bible_database.dart'
    show LectionaryReading, BibleDatabaseHelper;
import 'package:twelve_stars/widgets/prayer_card.dart';
import 'package:twelve_stars/widgets/mass_reading_card.dart';

class MissalTab extends StatefulWidget {
  final PrayerLanguage primaryLanguage;
  final PrayerLanguage compareLanguage;

  const MissalTab({
    super.key,
    required this.primaryLanguage,
    required this.compareLanguage,
  });

  @override
  State<MissalTab> createState() => _MissalTabState();
}

class _MissalTabState extends State<MissalTab> {
  late DateTime _selectedDate;
  bool _loading = true;
  String? _error;
  List<Prayer>? _prayers;
  UserSettings? _settings;
  late PrayerLanguage _primaryLanguage;
  late PrayerLanguage _compareLanguage;
  bool _showNiceneCreed = true;

  @override
  void initState() {
    super.initState();
    final now = TimeHelper.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _primaryLanguage = widget.primaryLanguage;
    _compareLanguage = widget.compareLanguage;
    _loadData();
  }

  @override
  void didUpdateWidget(MissalTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryLanguage != widget.primaryLanguage ||
        oldWidget.compareLanguage != widget.compareLanguage) {
      setState(() {
        _primaryLanguage = widget.primaryLanguage;
        _compareLanguage = widget.compareLanguage;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final prayers = await PrayerDatabase.loadPrayers();
      final settings = await PrayerDatabase.loadSettings();
      if (mounted) {
        setState(() {
          _prayers = prayers;
          _settings = settings;
          _primaryLanguage = settings.primaryLanguage;
          _compareLanguage = settings.compareLanguage;
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

  void _changeDay(int offset) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + offset,
      );
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  String _formatFullDate(DateTime date) {
    final weekday = LiturgicalCalendar.getDayOfWeekName(date.weekday);
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final month = monthNames[date.month - 1];
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  Prayer? _findPrayer(String id) {
    if (_prayers == null) return null;
    try {
      return _prayers!.firstWhere((p) => p.prayerId == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _launchSourceUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch source URL: $urlString'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool get _isTodaySelected {
    final now = TimeHelper.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  DateTime _getNextSunday(DateTime date) {
    final offset = 7 - date.weekday % 7;
    return DateTime(date.year, date.month, date.day + offset);
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(thickness: 1),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(Prayer prayer) {
    final prefKey =
        '${prayer.prayerId}_${_primaryLanguage.toString().split('.').last}';
    final initialVersion =
        _settings?.preferredVersions
            ?.firstWhere(
              (p) => p.key == prefKey,
              orElse: () => PrayerVersionPreference(),
            )
            .versionIndex ??
        0;

    return PrayerCard(
      prayer: prayer,
      selectedLanguage: _primaryLanguage,
      compareLanguage: _compareLanguage,
      initialVersionIndex: initialVersion,
      onVersionChanged: (newIndex) async {
        if (_settings != null) {
          final list = _settings!.preferredVersions ?? [];
          final idx = list.indexWhere((p) => p.key == prefKey);
          if (idx >= 0) {
            list[idx].versionIndex = newIndex;
          } else {
            list.add(PrayerVersionPreference(prefKey, newIndex));
          }
          _settings!.preferredVersions = list;
          await PrayerDatabase.saveSettings(_settings!);
        }
      },
      onLaunchSource: _launchSourceUrl,
    );
  }

  Widget _buildMassPartPlaceholder(
    String title,
    String description,
    IconData icon,
    ThemeData theme,
  ) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error loading missal data: $_error',
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final currentDay = LiturgicalCalendar.computeDay(_selectedDate);

    final signOfTheCross = _findPrayer('sign_of_the_cross');
    final confiteor = _findPrayer('confiteor');
    final gloria = _findPrayer('gloria');
    final niceneCreed = _findPrayer('nicene_creed');
    final apostlesCreed = _findPrayer('apostles_creed');
    final ourFather = _findPrayer('our_father');

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isTodaySelected) ...[
            FloatingActionButton.extended(
              heroTag: 'missal_today_fab',
              onPressed: () {
                setState(() {
                  final now = TimeHelper.now();
                  _selectedDate = DateTime(now.year, now.month, now.day);
                });
              },
              icon: const Icon(Icons.restore),
              label: const Text('Today'),
            ),
            const SizedBox(height: 8),
          ],
          FloatingActionButton.extended(
            heroTag: 'missal_next_sunday_fab',
            onPressed: () {
              setState(() {
                _selectedDate = _getNextSunday(_selectedDate);
              });
            },
            icon: const Icon(Icons.navigate_next),
            label: const Text('Next Sunday'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  'Mass Missal',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              // 1. Date Header & Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeDay(-1),
                    tooltip: 'Previous Day',
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _formatFullDate(_selectedDate),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeDay(1),
                    tooltip: 'Next Day',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 2. Main Liturgical Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 10, color: currentDay.colorWidget),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    currentDay.seasonName.toUpperCase(),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.secondary,
                                          letterSpacing: 1.1,
                                        ),
                                  ),
                                  Text(
                                    'Cycle ${currentDay.sundayCycle} • Year ${currentDay.weekdayCycle}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                currentDay.weekName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.lens,
                                    size: 10,
                                    color: currentDay.colorWidget,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Color: ${currentDay.colorName}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Special Solemnity / Feast Alert Card (if any)
              if (currentDay.name != null) ...[
                Card(
                  elevation: 0,
                  color: currentDay.colorWidget.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: currentDay.colorWidget.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.church,
                          color: currentDay.colorWidget,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SOLEMNITY / FEAST',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: currentDay.colorWidget,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentDay.name!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 4. Introductory Rites Section
              _buildSectionHeader('INTRODUCTORY RITES', theme),
              _buildMassPartPlaceholder(
                'Entrance Chant & Greeting',
                'Greeting dialogue: "The Lord be with you..."',
                Icons.message,
                theme,
              ),
              const SizedBox(height: 12),
              if (signOfTheCross != null) ...[
                _buildPrayerCard(signOfTheCross),
                const SizedBox(height: 12),
              ],
              if (confiteor != null) ...[
                _buildPrayerCard(confiteor),
                const SizedBox(height: 12),
              ],
              _buildMassPartPlaceholder(
                'Kyrie Eleison',
                'Kyrie, eleison (Lord, have mercy...)',
                Icons.volunteer_activism,
                theme,
              ),
              const SizedBox(height: 12),
              if (gloria != null) ...[
                _buildPrayerCard(gloria),
                const SizedBox(height: 12),
              ],
              _buildMassPartPlaceholder(
                'Collect (Opening Prayer)',
                'Opening prayer of the day',
                Icons.bookmark_border,
                theme,
              ),
              const SizedBox(height: 12),

              // 5. Liturgy of the Word Section
              _buildSectionHeader('LITURGY OF THE WORD', theme),
              FutureBuilder<List<LectionaryReading>>(
                future: BibleDatabaseHelper.db.getReadings(
                  currentDay.lectionaryKey,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'Error loading readings: ${snapshot.error}',
                      style: TextStyle(color: theme.colorScheme.error),
                    );
                  }
                  final readings = (snapshot.data ?? []).toList();

                  // Sort readings: First Reading, Responsorial Psalm, Second Reading, Gospel
                  readings.sort((a, b) {
                    const order = {
                      'first': 0,
                      'psalm': 1,
                      'second': 2,
                      'gospel': 3,
                    };
                    final indexA = order[a.readingType] ?? 99;
                    final indexB = order[b.readingType] ?? 99;
                    return indexA.compareTo(indexB);
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (readings.isEmpty)
                        Card(
                          elevation: 0,
                          color: theme.colorScheme.surfaceContainerHigh,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 32,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No readings seeded for this date.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...readings.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: MassReadingCard(reading: r),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildMassPartPlaceholder(
                'Homily',
                'Reflective instruction by the priest',
                Icons.hearing,
                theme,
              ),
              const SizedBox(height: 12),

              // Creed segment selector
              Center(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Nicene Creed'),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Apostles\' Creed'),
                    ),
                  ],
                  selected: {_showNiceneCreed},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _showNiceneCreed = newSelection.first;
                    });
                  },
                  showSelectedIcon: false,
                ),
              ),
              const SizedBox(height: 12),
              if (_showNiceneCreed && niceneCreed != null)
                _buildPrayerCard(niceneCreed)
              else if (!_showNiceneCreed && apostlesCreed != null)
                _buildPrayerCard(apostlesCreed),
              const SizedBox(height: 12),
              _buildMassPartPlaceholder(
                'Universal Prayer (Prayers of the Faithful)',
                'Petitions for the Church, the world, and those in need',
                Icons.people,
                theme,
              ),
              const SizedBox(height: 12),

              // 6. Liturgy of the Eucharist Section
              _buildSectionHeader('LITURGY OF THE EUCHARIST', theme),
              _buildMassPartPlaceholder(
                'Preparation of the Altar (Offertory)',
                'Presentation and preparation of bread and wine',
                Icons.restaurant,
                theme,
              ),
              const SizedBox(height: 12),
              _buildMassPartPlaceholder(
                'Sanctus (Holy, Holy, Holy)',
                'Holy, Holy, Holy Lord God of hosts...',
                Icons.notifications_active,
                theme,
              ),
              const SizedBox(height: 12),
              _buildMassPartPlaceholder(
                'Eucharistic Prayer & Consecration',
                'Eucharistic prayer and consecration of bread and wine',
                Icons.brightness_high,
                theme,
              ),
              const SizedBox(height: 12),
              if (ourFather != null) ...[
                _buildPrayerCard(ourFather),
                const SizedBox(height: 12),
              ],
              _buildMassPartPlaceholder(
                'Sign of Peace',
                'Greeting one another with a sign of peace',
                Icons.handshake,
                theme,
              ),
              const SizedBox(height: 12),
              _buildMassPartPlaceholder(
                'Agnus Dei (Lamb of God)',
                'Lamb of God, you take away the sins of the world...',
                Icons.spa,
                theme,
              ),
              const SizedBox(height: 12),
              _buildMassPartPlaceholder(
                'Communion Rite',
                'Reception of Holy Communion and silent thanksgiving',
                Icons.church,
                theme,
              ),
              const SizedBox(height: 12),

              // 7. Concluding Rites Section
              _buildSectionHeader('CONCLUDING RITES', theme),
              _buildMassPartPlaceholder(
                'Concluding Blessing & Dismissal',
                'Blessing and sending forth: "Go in peace..."',
                Icons.logout,
                theme,
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}
