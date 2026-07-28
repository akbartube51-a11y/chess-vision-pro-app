import 'dart:io';

import 'puzzle_sync_models.dart';

abstract class PuzzleSource {
  const PuzzleSource();

  String get sourceId;
  String get displayName;
  String get attribution;
  String get licenseId;
  Uri? get defaultUri;

  bool get isLicenseAllowed =>
      licenseId == 'CC0-1.0' || licenseId == 'CC-BY-4.0';

  Stream<PuzzleSourceChunk> streamPuzzles({
    required Uri uri,
    String? cursor,
    int batchSize = 250,
  });
}

abstract class PuzzleNetworkClient {
  Future<PuzzleNetworkResponse> get(Uri uri);
}

class PuzzleNetworkResponse {
  const PuzzleNetworkResponse({
    required this.statusCode,
    required this.bytes,
    this.etag,
    this.lastModified,
  });

  final int statusCode;
  final Stream<List<int>> bytes;
  final String? etag;
  final String? lastModified;
}

class DefaultPuzzleNetworkClient implements PuzzleNetworkClient {
  const DefaultPuzzleNetworkClient();

  @override
  Future<PuzzleNetworkResponse> get(Uri uri) async {
    final client = HttpClient();
    final request = await client.getUrl(uri);
    final response = await request.close();
    return PuzzleNetworkResponse(
      statusCode: response.statusCode,
      bytes: response,
      etag: response.headers.value(HttpHeaders.etagHeader),
      lastModified: response.headers.value(HttpHeaders.lastModifiedHeader),
    );
  }
}
