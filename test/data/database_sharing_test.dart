import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalan/data/db/app_database.dart';

/// The app and a notification action write at the same time.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp('kalan_db'));
  tearDown(() => dir.delete(recursive: true));

  SourcesCompanion source(String name) =>
      SourcesCompanion.insert(name: name, kind: SourceKind.provider);

  test(
    'app and two actions write at once: no lock error, no lost write',
    () async {
      // The production path: every isolate in the process talks to the one
      // shared database (AppDatabase.openShared), so writers never meet at
      // the SQLite level, however hard they write.
      final path = '${dir.path}/kalan.sqlite';
      final tmp = dir.path;
      final name = 'kalan-load-${DateTime.now().microsecondsSinceEpoch}';

      Future<void> writes(AppDatabase db, String who) async {
        for (var i = 0; i < 40; i++) {
          await db.transaction(() async {
            await db.into(db.sources).insert(source('$who $i a'));
            await db.into(db.sources).insert(source('$who $i b'));
          });
        }
      }

      Future<void> inAnotherIsolate(String who) => Isolate.run(() async {
        final db = AppDatabase(
          AppDatabase.openShared(
            name: name,
            path: () async => path,
            tempDirectory: () async => tmp,
          ),
        );
        await writes(db, who);
        await db.close();
      });

      final app = AppDatabase(
        AppDatabase.openShared(
          name: name,
          path: () async => path,
          tempDirectory: () async => tmp,
        ),
      );
      await app.select(app.sources).get();
      await Future.wait([
        writes(app, 'app'),
        inAnotherIsolate('paid'),
        inAnotherIsolate('snooze'),
      ]);
      expect(await app.select(app.sources).get(), hasLength(240));
      await app.close();
    },
  );

  test('shared across isolates: one server, the app sees the write', () async {
    final path = '${dir.path}/shared.sqlite';
    final tmp = dir.path;
    final name = 'kalan-test-${DateTime.now().microsecondsSinceEpoch}';
    QueryExecutor open() => AppDatabase.openShared(
      name: name,
      path: () async => path,
      tempDirectory: () async => tmp,
    );

    final app = AppDatabase(open());
    final seen = app.select(app.sources).watch().map((r) => r.length);
    final counts = <int>[];
    final sub = seen.listen(counts.add);
    await app.into(app.sources).insert(source('Klarna'));

    // A notification action runs in another isolate.
    await Isolate.run(() async {
      final action = AppDatabase(
        AppDatabase.openShared(
          name: name,
          path: () async => path,
          tempDirectory: () async => tmp,
        ),
      );
      await Future.wait([
        for (var i = 0; i < 20; i++)
          action.into(action.sources).insert(source('Tabby $i')),
      ]);
      await action.close();
    });
    await Future.wait([
      for (var i = 0; i < 20; i++)
        app.into(app.sources).insert(source('Zip $i')),
    ]);

    expect(await app.select(app.sources).get(), hasLength(41));
    await pumpEventQueue();
    expect(counts.last, 41);
    await sub.cancel();
    await app.close();
  });
}
