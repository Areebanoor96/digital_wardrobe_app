import 'package:digital_wardrobe_app/core/config/help_faq_config.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:flutter/material.dart';

/// Help / FAQ entry. Provides quick answers using the app's existing behavior
/// and the navigation structure for the future web help/FAQ page (see
/// [HelpFaqConfig.webUrl], which is intentionally empty until finalized).
class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrowButton(),
        title: const Text('Help / FAQ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const _FaqCard(
            question: 'How do I switch the wardrobe I am using?',
            answer:
                'Open Profile, then Settings → Switch Profile and choose the '
                'family member whose wardrobe you want to use.',
          ),
          const _FaqCard(
            question: 'How do I manage family members?',
            answer:
                'Open Profile → Manage Family Members to add, edit or remove '
                'profiles for each person.',
          ),
          const _FaqCard(
            question: 'How do I change my notification preferences?',
            answer:
                'Open Profile → Notifications and toggle the alerts you want, '
                'such as unused garment, laundry and outfit of the day alerts.',
          ),
          const _FaqCard(
            question: 'How do I plan an outfit for a specific day?',
            answer:
                'Open the Calendar, choose a date and tap the plan action to '
                'get an outfit suggestion for that day.',
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Online help center'),
              subtitle: Text(
                HelpFaqConfig.webUrl.isEmpty
                    ? 'The Digital Wardrobe web help/FAQ page is coming soon.'
                    : 'Opens the Digital Wardrobe web help/FAQ page.',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Still need help? The alerts in the app are reminders only. '
            'For anything else, check the app\'s settings and privacy '
            'information.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              question,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(answer),
          ],
        ),
      ),
    );
  }
}