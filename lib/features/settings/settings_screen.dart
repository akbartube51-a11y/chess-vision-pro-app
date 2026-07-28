import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_preferences.dart';
import '../puzzles/presentation/providers/puzzle_provider.dart';
import 'providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final provider = context.watch<PuzzleProvider>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: l10n.appearance),
          ListTile(
            leading: const Icon(Icons.brightness_medium),
            title: Text(l10n.theme),
            trailing: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode, size: 18),
                  label: Text(l10n.light),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto, size: 18),
                  label: Text(l10n.auto),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode, size: 18),
                  label: Text(l10n.dark),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (values) =>
                  settings.setThemeMode(values.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),
          _DropdownTile<BoardThemePreset>(
            icon: Icons.palette_outlined,
            title: l10n.boardTheme,
            value: settings.boardThemePreset,
            items: BoardThemePreset.values,
            itemLabel: (value) => _boardThemeLabel(context, value),
            onChanged: settings.setBoardThemePreset,
          ),
          _DropdownTile<PieceSetStyle>(
            icon: Icons.extension_outlined,
            title: l10n.pieceStyle,
            value: settings.pieceSetStyle,
            items: PieceSetStyle.values,
            itemLabel: (value) => _pieceStyleLabel(context, value),
            onChanged: settings.setPieceSetStyle,
          ),
          _DropdownTile<CoordinateStyle>(
            icon: Icons.grid_4x4,
            title: l10n.coordinates,
            value: settings.coordinateStyle,
            items: CoordinateStyle.values,
            itemLabel: (value) => _coordinateStyleLabel(context, value),
            onChanged: settings.setCoordinateStyle,
          ),
          const Divider(),
          _SectionHeader(title: l10n.board),
          SwitchListTile(
            secondary: const Icon(Icons.flip),
            title: Text(l10n.autoFlipBoard),
            subtitle: Text(l10n.autoFlipBoardSubtitle),
            value: settings.boardFlipEnabled,
            onChanged: settings.setBoardFlipEnabled,
          ),
          const Divider(),
          _SectionHeader(title: l10n.accessibility),
          SwitchListTile(
            secondary: const Icon(Icons.record_voice_over_outlined),
            title: Text(l10n.voiceGuidance),
            subtitle: Text(l10n.voiceGuidanceSubtitle),
            value: settings.voiceGuidanceEnabled,
            onChanged: settings.setVoiceGuidanceEnabled,
          ),
          _DropdownTile<VoiceGuidanceVerbosity>(
            icon: Icons.volume_up_outlined,
            title: l10n.voiceVerbosity,
            value: settings.voiceGuidanceVerbosity,
            items: VoiceGuidanceVerbosity.values,
            itemLabel: (value) => _voiceVerbosityLabel(context, value),
            onChanged: settings.voiceGuidanceEnabled
                ? settings.setVoiceGuidanceVerbosity
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: DropdownButton<String>(
              value: settings.localeCode ?? 'system',
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(l10n.languageSystem),
                ),
                const DropdownMenuItem(value: 'en', child: Text('English')),
                const DropdownMenuItem(value: 'es', child: Text('Español')),
              ],
              onChanged: (value) =>
                  settings.setLocaleCode(value == 'system' ? null : value),
            ),
          ),
          const Divider(),
          _SectionHeader(title: l10n.dataAndSync),
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: Text(l10n.onlinePuzzleSync),
            subtitle: Text(
              settings.puzzleSourceUrl ?? l10n.sourceNotConfigured,
            ),
            trailing: TextButton(
              onPressed: () => _editSourceUrl(context, settings),
              child: Text(l10n.editSourceUrl),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l10n.sourceUrlHelper),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(l10n.syncSourceNotice),
          ),
          if (provider.syncState?.lastSyncedAt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                l10n.syncLastRun(
                  provider.syncState!.lastSyncedAt!.toLocal().toString(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: provider.syncLoading
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text(l10n.syncInProgress)),
                        );
                      final report = await context
                          .read<PuzzleProvider>()
                          .syncFromSourceUrl(settings.puzzleSourceUrl);
                      if (!context.mounted) return;
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              report == null
                                  ? l10n.syncFailed
                                  : l10n.syncImported(
                                      report.importedCount,
                                      report.sourceId,
                                    ),
                            ),
                          ),
                        );
                    },
              icon: provider.syncLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(l10n.syncNow),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyAndPermissions),
            subtitle: Text(l10n.privacyAndPermissionsSubtitle),
            onTap: () => context.go('/privacy'),
          ),
          const Divider(),
          _SectionHeader(title: l10n.about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.appTitle),
            subtitle: const Text('Version 1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l10n.openSource),
            subtitle: Text(l10n.openSourceSubtitle),
          ),
        ],
      ),
    );
  }

  Future<void> _editSourceUrl(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final controller = TextEditingController(text: settings.puzzleSourceUrl);
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.sourceUrl),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: l10n.sourceUrlHelper),
            minLines: 2,
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.clear();
                settings.setPuzzleSourceUrl(null);
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n.clear),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                settings.setPuzzleSourceUrl(controller.text);
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  String _boardThemeLabel(BuildContext context, BoardThemePreset value) {
    final l10n = context.l10n;
    return switch (value) {
      BoardThemePreset.tournament => l10n.boardThemeTournament,
      BoardThemePreset.forest => l10n.boardThemeForest,
      BoardThemePreset.midnight => l10n.boardThemeMidnight,
    };
  }

  String _pieceStyleLabel(BuildContext context, PieceSetStyle value) {
    final l10n = context.l10n;
    return switch (value) {
      PieceSetStyle.classic => l10n.pieceStyleClassic,
      PieceSetStyle.neo => l10n.pieceStyleNeo,
      PieceSetStyle.initials => l10n.pieceStyleInitials,
    };
  }

  String _coordinateStyleLabel(BuildContext context, CoordinateStyle value) {
    final l10n = context.l10n;
    return switch (value) {
      CoordinateStyle.inside => l10n.coordinatesInside,
      CoordinateStyle.outside => l10n.coordinatesOutside,
      CoordinateStyle.hidden => l10n.coordinatesHidden,
    };
  }

  String _voiceVerbosityLabel(
    BuildContext context,
    VoiceGuidanceVerbosity value,
  ) {
    final l10n = context.l10n;
    return switch (value) {
      VoiceGuidanceVerbosity.concise => l10n.voiceVerbosityConcise,
      VoiceGuidanceVerbosity.detailed => l10n.voiceVerbosityDetailed,
    };
  }
}

class _DropdownTile<T> extends StatelessWidget {
  const _DropdownTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final Future<void> Function(T value)? onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: DropdownButton<T>(
        value: value,
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item)),
              ),
            )
            .toList(),
        onChanged: onChanged == null
            ? null
            : (value) {
                if (value != null) {
                  onChanged!(value);
                }
              },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
