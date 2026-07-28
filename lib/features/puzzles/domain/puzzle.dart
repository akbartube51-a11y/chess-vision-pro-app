class Puzzle {
  const Puzzle({
    required this.id,
    required this.fen,
    required this.moves,
    required this.rating,
    this.themes = const [],
    this.openingTags = const [],
    this.source = 'local',
    this.externalId,
  });

  final int id;
  final String? externalId;
  final String fen;

  /// UCI move sequence. First move is the opponent's "setup" move;
  /// subsequent moves alternate: player, engine, player, engine...
  final List<String> moves;
  final int rating;
  final List<String> themes;
  final List<String> openingTags;
  final String source;

  factory Puzzle.fromMap(Map<String, dynamic> map) {
    return Puzzle(
      id: map['id'] as int,
      externalId: map['external_id'] as String?,
      fen: map['fen'] as String,
      moves: (map['moves'] as String).split(' '),
      rating: map['rating'] as int,
      themes: _splitTags(map['themes'] as String),
      openingTags: _splitTags(map['opening_tags'] as String),
      source: map['source'] as String? ?? 'local',
    );
  }

  Map<String, dynamic> toMap() {
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

  static List<String> _splitTags(String raw) =>
      raw.isEmpty ? [] : raw.split(' ');

  String get difficultyLabel {
    if (rating < 1200) return 'Beginner';
    if (rating < 1600) return 'Intermediate';
    if (rating < 2000) return 'Advanced';
    return 'Expert';
  }

  @override
  String toString() => 'Puzzle(id: $id, rating: $rating, themes: $themes)';
}
