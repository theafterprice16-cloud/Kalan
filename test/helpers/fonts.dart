import 'dart:io';

import 'package:flutter/services.dart';

/// Real fonts from the Flutter SDK, so text has its real width (the test
/// font draws every letter as a square).
Future<void> loadFonts() async {
  var dir = File(Platform.resolvedExecutable).parent;
  Directory? fonts;
  for (var i = 0; i < 8 && fonts == null; i++) {
    final candidate = Directory(
      '${dir.path}/bin/cache/artifacts/material_fonts',
    );
    if (candidate.existsSync()) fonts = candidate;
    final env = Platform.environment['FLUTTER_ROOT'];
    if (fonts == null && env != null) {
      final fromEnv = Directory('$env/bin/cache/artifacts/material_fonts');
      if (fromEnv.existsSync()) fonts = fromEnv;
    }
    dir = dir.parent;
  }
  if (fonts == null) return;
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      final bytes = File('${fonts!.path}/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  const roboto = ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf'];
  await family('Roboto', roboto);
  // iOS text styles ask for the system font; Roboto stands in for it.
  await family('CupertinoSystemText', roboto);
  await family('CupertinoSystemDisplay', roboto);
  await family('MaterialIcons', ['MaterialIcons-Regular.otf']);
}
