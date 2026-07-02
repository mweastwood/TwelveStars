import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'bible_db',
      sqlite3Uri: Uri.parse(
        'https://unpkg.com/sqlite3@5.1.6/dist/sqlite3.wasm',
      ),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}
