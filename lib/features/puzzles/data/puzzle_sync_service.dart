import 'puzzle_repository.dart';
import 'puzzle_source.dart';
import 'puzzle_sync_models.dart';

class PuzzleSyncService {
  PuzzleSyncService(this._repository);

  final PuzzleRepository _repository;

  Future<PuzzleSyncReport> syncSource(
    PuzzleSource source, {
    Uri? uri,
    int batchSize = 250,
    int maxRetries = 3,
    Duration initialBackoff = const Duration(milliseconds: 300),
    bool resetCursor = false,
  }) async {
    if (!source.isLicenseAllowed) {
      throw const PuzzleSourceException(
        'Only open licensed puzzle sources can be imported.',
      );
    }

    final targetUri = uri ?? source.defaultUri;
    if (targetUri == null) {
      throw const PuzzleSourceException('No puzzle source URL configured.');
    }

    final baselineState = await _repository.fetchSyncState(source.sourceId);
    var cursor = resetCursor ? null : baselineState?.cursor;
    var importedCount = 0;
    var retries = 0;

    while (true) {
      try {
        await for (final chunk in source.streamPuzzles(
          uri: targetUri,
          cursor: cursor,
          batchSize: batchSize,
        )) {
          if (chunk.puzzles.isEmpty) {
            cursor = chunk.nextCursor;
            continue;
          }
          await _repository.upsertImportedPuzzles(chunk.puzzles);
          importedCount += chunk.puzzles.length;
          cursor = chunk.nextCursor;
          await _repository.saveSyncState(
            (baselineState ??
                    PuzzleSyncState(
                      sourceId: source.sourceId,
                      attribution: source.attribution,
                    ))
                .copyWith(
              cursor: cursor,
              contentHash: chunk.contentHash,
              datasetVersion: chunk.datasetVersion,
              importedCount:
                  (baselineState?.importedCount ?? 0) + importedCount,
              lastSyncedAt: DateTime.now(),
              attribution: source.attribution,
              clearError: true,
            ),
          );
        }

        return PuzzleSyncReport(
          sourceId: source.displayName,
          importedCount: importedCount,
          resumedFromCursor: baselineState?.cursor,
          completedAt: DateTime.now(),
          attribution: source.attribution,
        );
      } catch (error) {
        retries++;
        await _repository.saveSyncState(
          (baselineState ??
                  PuzzleSyncState(
                    sourceId: source.sourceId,
                    attribution: source.attribution,
                  ))
              .copyWith(
            cursor: cursor,
            lastError: error.toString(),
            attribution: source.attribution,
          ),
        );
        if (retries >= maxRetries) rethrow;
        await Future<void>.delayed(initialBackoff * retries);
      }
    }
  }
}
