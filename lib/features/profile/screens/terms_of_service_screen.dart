import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const String _fullTermsUrl =
      'https://reliable-grain-c87.notion.site/Privacy-Policy-for-Digital-Wardrobe-38d457eae7328042bb95c163739f68ef?source=copy_link';

  Future<void> _openFullTerms(BuildContext context) async {
    final Uri uri = Uri.parse(_fullTermsUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open browser link.')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrowButton(),
        title: const Text('Terms of Service'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'Terms Overview',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Last updated: September 2026',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // Highlights Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildSummaryPoint(
                  context,
                  icon: Icons.check_circle_outline,
                  title: 'Account & Service Use',
                  description:
                  'You are responsible for keeping your account secure and using Digital Wardrobe features responsibly.',
                ),
                const Divider(height: 24),
                _buildSummaryPoint(
                  context,
                  icon: Icons.image_outlined,
                  title: 'Content Ownership',
                  description:
                  'You retain ownership of all wardrobe photos you upload. You grant us permission only to display them within your app.',
                ),
                const Divider(height: 24),
                _buildSummaryPoint(
                  context,
                  icon: Icons.gavel_outlined,
                  title: 'Acceptable Conduct',
                  description:
                  'Do not upload unlawful, abusive, or copyrighted content that does not belong to you.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // External Document Link Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  'Need the complete legal agreement?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _openFullTerms(context),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Read Full Terms Online'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPoint(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
      }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: colors.primary, size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
