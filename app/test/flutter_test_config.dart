import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

class TolerantComparator extends LocalFileComparator {
  final double precisionTolerance;

  TolerantComparator(super.testFile, this.precisionTolerance);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (result.passed || result.diffPercent <= precisionTolerance) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();

  final oldComparator = goldenFileComparator;
  if (oldComparator is LocalFileComparator) {
    // resolve('dummy.dart') is needed because LocalFileComparator constructor resolves the parent
    // directory if the passed URI is already a directory.
    goldenFileComparator = TolerantComparator(
      oldComparator.basedir.resolve('dummy.dart'),
      0.03, // 3% tolerance
    );
  }

  return GoldenToolkit.runWithConfiguration(() async {
    await testMain();
  }, config: GoldenToolkitConfiguration());
}
