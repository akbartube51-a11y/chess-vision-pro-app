import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/localization_extensions.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/settings')),
        title: Text(l10n.privacyScreenTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.privacySummary,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _Section(title: l10n.privacyNetworkHeading, body: l10n.privacyNetworkBody),
          _Section(title: l10n.privacyStorageHeading, body: l10n.privacyStorageBody),
          _Section(title: l10n.privacyPermissionsHeading, body: l10n.privacyPermissionsBody),
          _Section(title: l10n.privacyLicenseHeading, body: l10n.privacyLicenseBody),
          const SizedBox(height: 12),
          Text(
            l10n.privacyDocsLink,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}
