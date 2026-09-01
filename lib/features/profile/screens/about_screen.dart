import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/services/app_info_service.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// About Digital Wardrobe — shows the installed app version and build number.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppInfo> appInfo = ref.watch(appInfoProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrowButton(),
        title: const Text('About Digital Wardrobe'),
      ),
      body: appInfo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load app info.')),
        data: (AppInfo info) => ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            const SizedBox(height: 16),
            Icon(Icons.checkroom, size: 64, color: colors.primary),
            const SizedBox(height: 16),
            Text(
              info.appName.isEmpty ? 'Digital Wardrobe' : info.appName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your personal wardrobe, outfit and style assistant.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 28),
            Card(
              elevation: 0,
              color: colors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('App Version'),
                subtitle: Text(info.displayVersion),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
