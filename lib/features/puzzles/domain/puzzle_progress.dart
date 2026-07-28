class PuzzleProgress {
  const PuzzleProgress({
    required this.puzzleId,
    this.solved = false,
    this.attempts = 0,
    this.lastAttempted,
    this.id,
  });

  final int? id;
  final int puzzleId;
  final bool solved;
  final int attempts;
  final DateTime? lastAttempted;

  factory PuzzleProgress.fromMap(Map<String, dynamic> map) {
    return PuzzleProgress(
      id: map['id'] as int?,
      puzzleId: map['puzzle_id'] as int,
      solved: (map['solved'] as int) == 1,
      attempts: map['attempts'] as int,
      lastAttempted: map['last_attempted'] != null
          ? DateTime.parse(map['last_attempted'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'puzzle_id': puzzleId,
      'solved': solved ? 1 : 0,
      'attempts': attempts,
      'last_attempted': lastAttempted?.toIso8601String(),
    };
  }

  PuzzleProgress copyWith({
    bool? solved,
    int? attempts,
    DateTime? lastAttempted,
  }) {
    return PuzzleProgress(
      id: id,
      puzzleId: puzzleId,
      solved: solved ?? this.solved,
      attempts: attempts ?? this.attempts,
      lastAttempted: lastAttempted ?? this.lastAttempted,
    );
  }
}
