import 'dart:io';

import 'package:license_checker2/src/config.dart';
import 'package:license_checker2/src/package_checker.dart';
import 'package:pana/pana.dart';
import 'package:test/test.dart';

void main() {
  final config =
      Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));

  test('should properly create a PackageChecker with all proper attributes',
      () async {
    final pubspec = Pubspec.parseYaml(
      await File('test/lib/src/fixtures/dodgers/pubspec.yaml').readAsString(),
    );
    final pc = await PackageChecker.fromDirectory(
      directory: Directory('test/lib/src/fixtures/dodgers'),
      config: config,
    );
    expect(
      pc.packages.map((p) => p.name),
      containsAll(['padres', 'as', 'angeles', 'mlb']),
    );
    expect(pc.config, config);
    expect(pc.pubspec.name, pubspec.name);
  });

  test('should load package checker from the current directory', () async {
    final pc = await PackageChecker.fromCurrentDirectory(config: config);
    expect(pc.pubspec.name, 'license_checker2');
    expect(pc.config, config);
  });

  test('should throw an exception when no pubspec.yaml is found', () {
    expect(
      () async {
        await PackageChecker.fromDirectory(
          directory: Directory('test/lib/src/fixtures/padres'),
          config: config,
        );
      },
      throwsA(
        predicate(
          (e) =>
              e is FileSystemException &&
              e.message
                  .contains('pubspec.yaml file not found in current directory'),
        ),
      ),
    );
  });

  test('should throw an exception when no package_config.json is found', () {
    expect(
      () async {
        await PackageChecker.fromDirectory(
          directory: Directory('test/lib/src/fixtures/angeles'),
          config: config,
        );
      },
      throwsA(
        predicate(
          (e) =>
              e is FileSystemException &&
              e.message.contains('No package_config.json found'),
        ),
      ),
    );
  });
}
