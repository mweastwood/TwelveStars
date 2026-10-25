import 'package:flutter/material.dart';
import 'package:twelve_stars/logic/prayers.dart';
import 'package:twelve_stars/widgets/reader/missal_section_widgets.dart';

/// Builds the Introductory Rites section of the Mass in [MissalTab].
class MissalIntroductoryRitesSection extends StatelessWidget {
  final bool Function(String id) isPrayerVisible;
  final Widget Function(Prayer prayer) buildPrayerCard;
  final Prayer? massGreeting;
  final Prayer? confiteor;
  final Prayer? kyrieEleison;
  final Prayer? gloria;

  const MissalIntroductoryRitesSection({
    super.key,
    required this.isPrayerVisible,
    required this.buildPrayerCard,
    this.massGreeting,
    this.confiteor,
    this.kyrieEleison,
    this.gloria,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MissalSectionHeader(title: 'INTRODUCTORY RITES'),
        const MissalMassPartPlaceholder(
          title: 'Entrance Chant',
          description: 'Entrance Antiphon of the day',
          icon: Icons.music_note,
        ),
        const SizedBox(height: 12),
        if (isPrayerVisible('mass_greeting') && massGreeting != null) ...[
          buildPrayerCard(massGreeting!),
          const SizedBox(height: 12),
        ],
        if (isPrayerVisible('confiteor') && confiteor != null) ...[
          buildPrayerCard(confiteor!),
          const SizedBox(height: 12),
        ],
        if (isPrayerVisible('kyrie_eleison')) ...[
          if (kyrieEleison != null)
            buildPrayerCard(kyrieEleison!)
          else
            const MissalMassPartPlaceholder(
              title: 'Kyrie Eleison',
              description: 'Kyrie, eleison (Lord, have mercy...)',
              icon: Icons.volunteer_activism,
            ),
          const SizedBox(height: 12),
        ],
        if (isPrayerVisible('gloria') && gloria != null) ...[
          buildPrayerCard(gloria!),
          const SizedBox(height: 12),
        ],
        const MissalMassPartPlaceholder(
          title: 'Collect (Opening Prayer)',
          description: 'Opening prayer of the day',
          icon: Icons.bookmark_border,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Builds the Liturgy of the Eucharist section of the Mass in [MissalTab].
class MissalLiturgyOfTheEucharistSection extends StatelessWidget {
  final bool Function(String id) isPrayerVisible;
  final Widget Function(Prayer prayer) buildPrayerCard;
  final Prayer? offertoryResponse;
  final Prayer? orateFratres;
  final Prayer? prefaceDialogue;
  final Prayer? sanctus;
  final Prayer? mysteryOfFaith;
  final Prayer? ourFather;
  final Prayer? embolism;
  final Prayer? signOfPeace;
  final Prayer? agnusDei;
  final Prayer? domineNonSumDignus;
  final Prayer? animaChristi;
  final void Function(BuildContext context, Prayer prayer) onOpenAnimaChristi;

  const MissalLiturgyOfTheEucharistSection({
    super.key,
    required this.isPrayerVisible,
    required this.buildPrayerCard,
    this.offertoryResponse,
    this.orateFratres,
    this.prefaceDialogue,
    this.sanctus,
    this.mysteryOfFaith,
    this.ourFather,
    this.embolism,
    this.signOfPeace,
    this.agnusDei,
    this.domineNonSumDignus,
    this.animaChristi,
    required this.onOpenAnimaChristi,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MissalSectionHeader(title: 'LITURGY OF THE EUCHARIST'),
          const MissalMassPartPlaceholder(
            title: 'Preparation of the Altar (Offertory)',
            description: 'Presentation and preparation of bread and wine',
            icon: Icons.restaurant,
          ),
          const SizedBox(height: 12),
          if (isPrayerVisible('offertory_response') &&
              offertoryResponse != null) ...[
            buildPrayerCard(offertoryResponse!),
            const SizedBox(height: 12),
          ],
          if (isPrayerVisible('orate_fratres') && orateFratres != null) ...[
            buildPrayerCard(orateFratres!),
            const SizedBox(height: 12),
          ],
          if (isPrayerVisible('preface_dialogue') &&
              prefaceDialogue != null) ...[
            buildPrayerCard(prefaceDialogue!),
            const SizedBox(height: 12),
          ],
          if (isPrayerVisible('sanctus')) ...[
            if (sanctus != null)
              buildPrayerCard(sanctus!)
            else
              const MissalMassPartPlaceholder(
                title: 'Sanctus (Holy, Holy, Holy)',
                description: 'Holy, Holy, Holy Lord God of hosts...',
                icon: Icons.notifications_active,
              ),
            const SizedBox(height: 12),
          ],
          const MissalMassPartPlaceholder(
            title: 'Eucharistic Prayer & Consecration',
            description:
                'Eucharistic prayer and consecration of bread and wine',
            icon: Icons.brightness_high,
          ),
          const SizedBox(height: 12),
          if (isPrayerVisible('mystery_of_faith') &&
              mysteryOfFaith != null) ...[
            buildPrayerCard(mysteryOfFaith!),
            const SizedBox(height: 12),
          ],
          if (isPrayerVisible('our_father') && ourFather != null) ...[
            buildPrayerCard(ourFather!),
            const SizedBox(height: 12),
          ],
          if (isPrayerVisible('embolism') && embolism != null) ...[
            buildPrayerCard(embolism!),
            const SizedBox(height: 12),
          ],
          if (isPrayerVisible('sign_of_peace')) ...[
            if (signOfPeace != null)
              buildPrayerCard(signOfPeace!)
            else
              const MissalMassPartPlaceholder(
                title: 'Sign of Peace',
                description: 'Greeting one another with a sign of peace',
                icon: Icons.handshake,
              ),
            const SizedBox(height: 12),
          ],
          if (isPrayerVisible('agnus_dei')) ...[
            if (agnusDei != null)
              buildPrayerCard(agnusDei!)
            else
              const MissalMassPartPlaceholder(
                title: 'Agnus Dei (Lamb of God)',
                description:
                    'Lamb of God, you take away the sins of the world...',
                icon: Icons.spa,
              ),
            const SizedBox(height: 12),
          ],
          if (isPrayerVisible('domine_non_sum_dignus') &&
              domineNonSumDignus != null) ...[
            buildPrayerCard(domineNonSumDignus!),
            const SizedBox(height: 12),
          ],
          MissalCommunionSectionCard(
            animaChristi: animaChristi,
            onOpenAnimaChristi: onOpenAnimaChristi,
          ),
        ],
      ),
    );
  }
}

/// Builds the Concluding Rites section of the Mass in [MissalTab].
class MissalConcludingRitesSection extends StatelessWidget {
  final Widget Function(Prayer prayer) buildPrayerCard;
  final Prayer? dismissal;

  const MissalConcludingRitesSection({
    super.key,
    required this.buildPrayerCard,
    this.dismissal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MissalSectionHeader(title: 'CONCLUDING RITES'),
          if (dismissal != null) ...[
            buildPrayerCard(dismissal!),
            const SizedBox(height: 12),
          ] else ...[
            const MissalMassPartPlaceholder(
              title: 'Concluding Blessing & Dismissal',
              description: 'Blessing and sending forth: "Go in peace..."',
              icon: Icons.logout,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
