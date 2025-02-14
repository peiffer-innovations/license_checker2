import 'dart:io';

import 'package:license_checker2/src/config.dart';
import 'package:license_checker2/src/dependency_checker.dart';
import 'package:license_checker2/src/generate_disclaimer.dart';
import 'package:license_checker2/src/package_checker.dart';
import 'package:mockito/mockito.dart';
import 'package:pana/pana.dart';
import 'package:test/test.dart';

class MockedDependencyChecker extends Mock implements DependencyChecker {
  MockedDependencyChecker(this.name, this._status) : _licenseFile = null;

  MockedDependencyChecker.withLicenseFile(
    this.name,
    this._status,
    this._licenseFile,
  );
  @override
  final String name;

  final LicenseStatus _status;
  final File? _licenseFile;

  @override
  Future<LicenseStatus> get packageLicenseStatus {
    return Future.value(_status);
  }

  @override
  Future<String> get licenseName => Future.value('swag');

  @override
  Future<String> get copyright => Future.value('1958 Los Angeles');

  @override
  String get sourceLocation => 'Chavez Ravine';

  @override
  File? get licenseFile => _licenseFile;
}

class MockedPackageChecker extends Mock implements PackageChecker {
  MockedPackageChecker(this.packages);
  @override
  final List<DependencyChecker> packages;

  @override
  final Pubspec pubspec = Pubspec({
    'name': 'MLB',
    'dependencies': {'Dodgers': '1.0.0', 'angles': '1.0.0'},
    'dev_dependencies': {'giants': '1.0.0'},
    'packages': {'Dodgers': '1.0.0', 'angles': '1.0.0', 'giants': '1.0.0'},
  });
}

void main() {
  group('Generate Disclaimer', () {
    String disclaimerCLIDisplay({
      required String packageName,
      required String licenseName,
      required String copyright,
      required String sourceLocation,
    }) {
      return 'cli: $packageName $licenseName $copyright $sourceLocation';
    }

    String disclaimerFileDisplay({
      required String packageName,
      required String licenseName,
      required String copyright,
      required String sourceLocation,
      required File? licenseFile,
    }) {
      return 'file: $packageName $licenseName $copyright $sourceLocation ${licenseFile?.path}';
    }

    test('should generate the disclaimer for a single package', () async {
      final config =
          Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));
      final result = await generatePackageDisclaimer<String, String>(
        config: config,
        package: MockedDependencyChecker.withLicenseFile(
          'Dodgers',
          LicenseStatus.approved,
          File('/dodger/stadium'),
        ),
        disclaimerCLIDisplay: disclaimerCLIDisplay,
        disclaimerFileDisplay: disclaimerFileDisplay,
      );

      expect(result.cli, 'cli: Dodgers swag 1958 Los Angeles Chavez Ravine');
      expect(
        result.file,
        'file: Dodgers swag 1958 Los Angeles Chavez Ravine /dodger/stadium',
      );
    });

    test('should generate the disclaimer with package license overrides',
        () async {
      final config = Config.fromFile(
        File('test/lib/src/fixtures/valid_config_license_override.yaml'),
      );
      final result = await generatePackageDisclaimer<String, String>(
        config: config,
        package: MockedDependencyChecker.withLicenseFile(
          'dodgers',
          LicenseStatus.approved,
          File('/dodger/stadium'),
        ),
        disclaimerCLIDisplay: disclaimerCLIDisplay,
        disclaimerFileDisplay: disclaimerFileDisplay,
      );

      expect(
        result.cli,
        'cli: dodgers BSD-3-Clause 1958 Los Angeles Chavez Ravine',
      );
      expect(
        result.file,
        'file: dodgers BSD-3-Clause 1958 Los Angeles Chavez Ravine /dodger/stadium',
      );
    });

    test('should generate the disclaimer with package source overrides',
        () async {
      final config = Config.fromFile(
        File('test/lib/src/fixtures/valid_config_source_override.yaml'),
      );
      final result = await generatePackageDisclaimer<String, String>(
        config: config,
        package: MockedDependencyChecker.withLicenseFile(
          'dodgers',
          LicenseStatus.approved,
          File('/dodger/stadium'),
        ),
        disclaimerCLIDisplay: disclaimerCLIDisplay,
        disclaimerFileDisplay: disclaimerFileDisplay,
      );

      expect(
        result.cli,
        'cli: dodgers swag 1958 Los Angeles https://dodgers.com',
      );
      expect(
        result.file,
        'file: dodgers swag 1958 Los Angeles https://dodgers.com /dodger/stadium',
      );
    });

    test(
        'should generate the disclaimer for a single package overriding the copyright with what is defined in the config',
        () async {
      final config = Config.fromFile(
        File('test/lib/src/fixtures/valid_config_copyright.yaml'),
      );
      final result = await generatePackageDisclaimer<String, String>(
        config: config,
        package: MockedDependencyChecker.withLicenseFile(
          'mlb',
          LicenseStatus.approved,
          File('/new/york'),
        ),
        disclaimerCLIDisplay: disclaimerCLIDisplay,
        disclaimerFileDisplay: disclaimerFileDisplay,
      );
      expect(result.cli, 'cli: mlb swag 2000 MLB. Chavez Ravine');
      expect(
        result.file,
        'file: mlb swag 2000 MLB. Chavez Ravine /new/york',
      );
    });

    test('should generate the disclaimer for all dependencies of a package',
        () async {
      final config =
          Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));
      final PackageChecker packageConfig = MockedPackageChecker([
        MockedDependencyChecker.withLicenseFile(
          'Dodgers',
          LicenseStatus.approved,
          File('/dodger/stadium'),
        ),
        MockedDependencyChecker.withLicenseFile(
          'Kings',
          LicenseStatus.approved,
          File('/crypto/.com'),
        ),
        MockedDependencyChecker.withLicenseFile(
          'angles',
          LicenseStatus.approved,
          File('/angles/stadium'),
        ),
        MockedDependencyChecker.withLicenseFile(
          'giants',
          LicenseStatus.approved,
          File('/att/park'),
        ),
      ]);
      final result = await generateDisclaimers<String, String>(
        config: config,
        packageConfig: packageConfig,
        showDirectDepsOnly: false,
        noDevDependencies: false,
        disclaimerCLIDisplay: disclaimerCLIDisplay,
        disclaimerFileDisplay: disclaimerFileDisplay,
      );

      expect(result.cli.length, equals(3));
      expect(
        result.cli[0],
        equals('cli: Dodgers swag 1958 Los Angeles Chavez Ravine'),
      );
      expect(
        result.cli[1],
        equals('cli: Kings swag 1958 Los Angeles Chavez Ravine'),
      );
      expect(
        result.cli[2],
        equals('cli: giants swag 1958 Los Angeles Chavez Ravine'),
      );
      expect(result.file.length, equals(3));
      expect(
        result.file[0],
        equals(
          'file: Dodgers swag 1958 Los Angeles Chavez Ravine /dodger/stadium',
        ),
      );
      expect(
        result.file[1],
        equals('file: Kings swag 1958 Los Angeles Chavez Ravine /crypto/.com'),
      );
      expect(
        result.file[2],
        equals('file: giants swag 1958 Los Angeles Chavez Ravine /att/park'),
      );
    });

    test('should generate the disclaimer for direct dependencies of a package',
        () async {
      final config =
          Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));
      final PackageChecker packageConfig = MockedPackageChecker([
        MockedDependencyChecker.withLicenseFile(
          'Dodgers',
          LicenseStatus.approved,
          File('/dodger/stadium'),
        ),
        MockedDependencyChecker.withLicenseFile(
          'Kings',
          LicenseStatus.approved,
          File('/crypto/.com'),
        ),
        MockedDependencyChecker.withLicenseFile(
          'angles',
          LicenseStatus.approved,
          File('/angles/stadium'),
        ),
      ]);
      final result = await generateDisclaimers<String, String>(
        config: config,
        packageConfig: packageConfig,
        showDirectDepsOnly: true,
        noDevDependencies: false,
        disclaimerCLIDisplay: disclaimerCLIDisplay,
        disclaimerFileDisplay: disclaimerFileDisplay,
      );

      expect(result.cli.length, equals(1));
      expect(
        result.cli[0],
        equals('cli: Dodgers swag 1958 Los Angeles Chavez Ravine'),
      );
      expect(result.file.length, equals(1));
      expect(
        result.file[0],
        equals(
          'file: Dodgers swag 1958 Los Angeles Chavez Ravine /dodger/stadium',
        ),
      );
    });

    test(
        'should generate the disclaimer for all dependencies of a package that are not dev dependencies',
        () async {
      final config =
          Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));
      final PackageChecker packageConfig = MockedPackageChecker([
        MockedDependencyChecker.withLicenseFile(
          'Dodgers',
          LicenseStatus.approved,
          File('/dodger/stadium'),
        ),
        MockedDependencyChecker.withLicenseFile(
          'Kings',
          LicenseStatus.approved,
          File('/crypto/.com'),
        ),
        MockedDependencyChecker.withLicenseFile(
          'angles',
          LicenseStatus.approved,
          File('/angles/stadium'),
        ),
        MockedDependencyChecker.withLicenseFile(
          'giants',
          LicenseStatus.approved,
          File('/att/park'),
        ),
      ]);
      final result = await generateDisclaimers<String, String>(
        config: config,
        packageConfig: packageConfig,
        showDirectDepsOnly: false,
        noDevDependencies: true,
        disclaimerCLIDisplay: disclaimerCLIDisplay,
        disclaimerFileDisplay: disclaimerFileDisplay,
      );

      expect(result.cli.length, equals(2));
      expect(
        result.cli[0],
        equals('cli: Dodgers swag 1958 Los Angeles Chavez Ravine'),
      );
      expect(
        result.cli[1],
        equals('cli: Kings swag 1958 Los Angeles Chavez Ravine'),
      );
      expect(result.file.length, equals(2));
      expect(
        result.file[0],
        equals(
          'file: Dodgers swag 1958 Los Angeles Chavez Ravine /dodger/stadium',
        ),
      );
      expect(
        result.file[1],
        equals('file: Kings swag 1958 Los Angeles Chavez Ravine /crypto/.com'),
      );
    });
  });
}
