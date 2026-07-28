class ImportedPuzzle {
  const ImportedPuzzle({
    required this.externalId,
    required this.fen,
    required this.moves,
    required this.rating,
    required this.themes,
    required this.openingTags,
    required this.source,
  });

  final String externalId;
  final String fen;
  final List<String> moves;
  final int rating;
  final List<String> themes;
  final List<String> openingTags;
  final String source;

  Map<String, dynamic> toDatabaseMap() {
    return {
      'external_id': externalId,
      'fen': fen,
      'moves': moves.join(' '),
      'rating': rating,
      'themes': themes.join(' '),
      'opening_tags': openingTags.join(' '),
      'source': source,
    };
  }
}

class PuzzleSyncState {
  const PuzzleSyncState({
    required this.sourceId,
    required this.attribution,
    this.lastSyncedAt,
    this.cursor,
    this.datasetVersion,
    this.contentHash,
    this.importedCount = 0,
    this.lastError,
  });

  final String sourceId;
  final DateTime? lastSyncedAt;
  final String? cursor;
  final String? datasetVersion;
  final String? contentHash;
  final int importedCount;
  final String attribution;
  final String? lastError;

  PuzzleSyncState copyWith({
    DateTime? lastSyncedAt,
    String? cursor,
    String? datasetVersion,
    String? contentHash,
    int? importedCount,
    String? attribution,
    String? lastError,
    bool clearError = false,
  }) {
    return PuzzleSyncState(
      sourceId: sourceId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      cursor: cursor ?? this.cursor,
      datasetVersion: datasetVersion ?? this.datasetVersion,
      contentHash: contentHash ?? this.contentHash,
      importedCount: importedCount ?? this.importedCount,
      attribution: attribution ?? this.attribution,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }

  factory PuzzleSyncState.fromMap(Map<String, dynamic> map) {
    return PuzzleSyncState(
      sourceId: map['source_id'] as String,
      lastSyncedAt: map['last_synced_at'] == null
          ? null
          : DateTime.parse(map['last_synced_at'] as String),
      cursor: map['cursor'] as String?,
      datasetVersion: map['dataset_version'] as String?,
      contentHash: map['content_hash'] as String?,
      importedCount: map['imported_count'] as int? ?? 0,
      attribution: map['attribution'] as String? ?? '',
      lastError: map['last_error'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'source_id': sourceId,
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'cursor': cursor,
      'dataset_version': datasetVersion,
      'content_hash': contentHash,
      'imported_count': importedCount,
      'attribution': attribution,
      'last_error': lastError,
    };
  }
}

class PuzzleSyncReport {
  const PuzzleSyncReport({
    required this.sourceId,
    required this.importedCount,
    required this.resumedFromCursor,
    required this.completedAt,
    required this.attribution,
  });

  final String sourceId;
  final int importedCount;
  final String? resumedFromCursor;
  final DateTime completedAt;
  final String attribution;
}

class PuzzleSourceChunk {
  const PuzzleSourceChunk({
    required this.puzzles,
    required this.nextCursor,
    required this.isLastChunk,
    this.datasetVersion,
    this.contentHash,
  });

  final List<ImportedPuzzle> puzzles;
  final String nextCursor;
  final bool isLastChunk;
  final String? datasetVersion;
  final String? contentHash;
}

class PuzzleSourceException implements Exception {
  const PuzzleSourceException(this.message);

  final String message;

  @override
  String toString() => 'PuzzleSourceException(message: $message)';
}
