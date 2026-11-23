import 'dart:async';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:kalan/features/export/export_service.dart';

/// Records what the share sheet was given; ends as [outcome] (or throws).
class FakeShare implements FileShareGateway {
  FakeShare([this.outcome = ShareOutcome.shared]);

  ShareOutcome outcome;
  bool fail = false;
  final shared = <({String name, String mimeType, List<int> bytes})>[];
  Completer<void> called = Completer();

  @override
  Future<ShareOutcome> shareFile(
    String path, {
    required String mimeType,
    Rect? origin,
  }) async {
    final file = File(path);
    shared.add((
      name: file.uri.pathSegments.last,
      mimeType: mimeType,
      bytes: file.readAsBytesSync(),
    ));
    if (!called.isCompleted) called.complete();
    if (fail) throw const FileSystemException('share failed');
    return outcome;
  }
}
