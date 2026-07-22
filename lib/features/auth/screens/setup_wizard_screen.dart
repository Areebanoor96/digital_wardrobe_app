import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final PageController _controller = PageController();
  int _step = 0;

  void _next() {
    if (_step == 2) {
      context.go('/app');
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/app'),
                  child: const Text('Skip setup'),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (int step) => setState(() => _step = step),
                  children: const <Widget>[
                    _SetupStep(
                      icon: Icons.location_city_outlined,
                      title: 'Where are you based?',
                      description:
                          'Add your city to prepare weather-aware outfit suggestions.',
                      fieldLabel: 'City',
                    ),
                    _SetupStep(
                      icon: Icons.family_restroom_outlined,
                      title: 'Who is in your wardrobe?',
                      description: 'You can add family members now or later.',
                      fieldLabel: 'Family member name',
                    ),
                    _SetupStep(
                      icon: Icons.notifications_none_rounded,
                      title: 'Stay in the loop',
                      description:
                          'Choose notification preferences when your Supabase and device setup are ready.',
                      fieldLabel: null,
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _next,
                child: Text(_step == 2 ? 'Finish' : 'Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.fieldLabel,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? fieldLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(description, textAlign: TextAlign.center),
        if (fieldLabel != null) ...<Widget>[
          const SizedBox(height: 24),
          TextField(decoration: InputDecoration(labelText: fieldLabel)),
        ],
      ],
    );
  }
}
