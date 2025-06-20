import 'dart:async';
import 'dart:io';

import 'package:license_checker2/src/config.dart';
import 'package:license_checker2/src/dependency_checker.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

typedef PropertyGetter<T> = FutureOr<T> Function(
  DependencyChecker dependencyChecker,
);
typedef ReturnMatcher<M> = M Function();

class DependencyTest<R> {
  DependencyTest({
    required this.testProperty,
    required this.expectedReturnMatcher,
    required this.testDescription,
  });
  final PropertyGetter<R> testProperty;
  final ReturnMatcher<R> expectedReturnMatcher;
  final String testDescription;
}

void main() {
  group('General tests', () {
    final config =
        Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));
    final dc = DependencyChecker(
      config: config,
      package: Package(
        'dodgers',
        Uri(
          scheme: 'file',
          path:
              '${Directory.current.absolute.path}/test/lib/src/fixtures/dodgers/',
        ),
      ),
    );

    final validTests = <DependencyTest<Object?>>[
      DependencyTest<Object?>(
        testProperty: (d) => d.name,
        expectedReturnMatcher: () => 'dodgers',
        testDescription: 'should get the package name from Package',
      ),
      DependencyTest<Object?>(
        testProperty: (d) => dc.licenseFile?.path,
        expectedReturnMatcher: () =>
            '${Directory.current.absolute.path}/test/lib/src/fixtures/dodgers/LICENSE',
        testDescription: 'should get a license file',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.licenseName;
        },
        expectedReturnMatcher: () => 'BSD-3-Clause',
        testDescription: 'should get the license name',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.packageLicenseStatus;
        },
        expectedReturnMatcher: () => LicenseStatus.needsApproval,
        testDescription: 'should get the license status based on the config',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.copyright;
        },
        expectedReturnMatcher: () => '2022 Los Angeles',
        testDescription: 'should extract the copyright from the license',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.sourceLocation;
        },
        expectedReturnMatcher: () => 'https://chavez.ravine',
        testDescription: 'should return the location of the source',
      ),
    ];

    for (var t in validTests) {
      test(t.testDescription, () async {
        expect(await t.testProperty(dc), t.expectedReturnMatcher());
      });
    }
  });
  group('license override', () {
    final config = Config.fromFile(
      File('test/lib/src/fixtures/valid_config_license_override.yaml'),
    );
    final dc = DependencyChecker(
      config: config,
      package: Package(
        'dodgers',
        Uri(
          scheme: 'file',
          path:
              '${Directory.current.absolute.path}/test/lib/src/fixtures/dodgers/',
        ),
      ),
    );

    final validTests = <DependencyTest<Object?>>[
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.licenseName;
        },
        expectedReturnMatcher: () => 'BSD-3-Clause',
        testDescription: 'should get the license name',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.packageLicenseStatus;
        },
        expectedReturnMatcher: () => LicenseStatus.permitted,
        testDescription: 'should get the license status based on the config',
      ),
    ];

    for (var t in validTests) {
      test(t.testDescription, () async {
        expect(await t.testProperty(dc), t.expectedReturnMatcher());
      });
    }
  });

  group('No license file', () {
    final config = Config.fromFile(
      File('test/lib/src/fixtures/valid_config.yaml'),
    );
    final dc = DependencyChecker(
      config: config,
      package: Package(
        'angeles',
        Uri(
          scheme: 'file',
          path:
              '${Directory.current.absolute.path}/test/lib/src/fixtures/angeles/',
        ),
      ),
    );

    final validTests = <DependencyTest<Object?>>[
      DependencyTest<Object?>(
        testProperty: (d) => d.name,
        expectedReturnMatcher: () => 'angeles',
        testDescription: 'should get the package name from Package',
      ),
      DependencyTest<Object?>(
        testProperty: (d) => dc.licenseFile?.path,
        expectedReturnMatcher: () => null,
        testDescription: 'should return that no file was found',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.licenseName;
        },
        expectedReturnMatcher: () => noFileLicense,
        testDescription: 'should return $noFileLicense as the license name',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.packageLicenseStatus;
        },
        expectedReturnMatcher: () => LicenseStatus.noLicense,
        testDescription: 'should return no license as the status',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.copyright;
        },
        expectedReturnMatcher: () => unknownCopyright,
        testDescription: 'should return $unknownCopyright',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.sourceLocation;
        },
        expectedReturnMatcher: () => 'https://www.mlb.com/angels',
        testDescription: 'should return the location of the source',
      ),
    ];

    for (var t in validTests) {
      test(t.testDescription, () async {
        expect(await t.testProperty(dc), t.expectedReturnMatcher());
      });
    }
  });

  group('Unknown license file', () {
    final config =
        Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));
    final dc = DependencyChecker(
      config: config,
      package: Package(
        'mets',
        Uri(
          scheme: 'file',
          path:
              '${Directory.current.absolute.path}/test/lib/src/fixtures/mets/',
        ),
      ),
    );

    final configChanged = Config.fromFile(
      File('test/lib/src/fixtures/valid_config_approved_unknown_license.yaml'),
    );
    final dcChanged = DependencyChecker(
      config: configChanged,
      package: Package(
        'mets',
        Uri(
          scheme: 'file',
          path:
              '${Directory.current.absolute.path}/test/lib/src/fixtures/mets/',
        ),
      ),
    );

    final validTests = <DependencyTest<Object?>>[
      DependencyTest<Object?>(
        testProperty: (d) => d.name,
        expectedReturnMatcher: () => 'mets',
        testDescription: 'should get the package name from Package',
      ),
      DependencyTest<Object?>(
        testProperty: (d) => d.licenseFile?.path,
        expectedReturnMatcher: () =>
            '${Directory.current.absolute.path}/test/lib/src/fixtures/mets/LICENSE',
        testDescription: 'should return the license file',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.licenseName;
        },
        expectedReturnMatcher: () => unknownLicense,
        testDescription: 'should return unknown-license as license name',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.packageLicenseStatus;
        },
        expectedReturnMatcher: () => LicenseStatus.unknown,
        testDescription:
            'should return that this package has unknown license status',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return dcChanged.packageLicenseStatus;
        },
        expectedReturnMatcher: () => LicenseStatus.approved,
        testDescription:
            'should return that this package has approved license status',
      ),
    ];

    for (var t in validTests) {
      test(t.testDescription, () async {
        expect(await t.testProperty(dc), t.expectedReturnMatcher());
      });
    }
  });

  group('Approved Package', () {
    final config =
        Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));
    final dc = DependencyChecker(
      config: config,
      package: Package(
        'mlb',
        Uri(
          scheme: 'file',
          path: '${Directory.current.absolute.path}/test/lib/src/fixtures/mlb/',
        ),
      ),
    );

    final configChanged = Config.fromFile(
      File('test/lib/src/fixtures/valid_config_changed_approved_pkg_lic.yaml'),
    );
    final dcChanged = DependencyChecker(
      config: configChanged,
      package: Package(
        'mlb',
        Uri(
          scheme: 'file',
          path: '${Directory.current.absolute.path}/test/lib/src/fixtures/mlb/',
        ),
      ),
    );

    final validTests = <DependencyTest<Object?>>[
      DependencyTest<Object?>(
        testProperty: (d) => d.name,
        expectedReturnMatcher: () => 'mlb',
        testDescription: 'should get the package name from Package',
      ),
      DependencyTest<Object?>(
        testProperty: (d) => dc.licenseFile?.path,
        expectedReturnMatcher: () =>
            '${Directory.current.absolute.path}/test/lib/src/fixtures/mlb/LICENSE',
        testDescription: 'should return the license file',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.licenseName;
        },
        expectedReturnMatcher: () => 'GPL-1.0',
        testDescription: 'should return the license name',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.packageLicenseStatus;
        },
        expectedReturnMatcher: () => LicenseStatus.approved,
        testDescription:
            'should return that this particular package was explicitly approved',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.copyright;
        },
        expectedReturnMatcher: () => '1989 Free Software Foundation, Inc.',
        testDescription:
            'should return parsed copyright (the license copyright that needs to be corrected)',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.sourceLocation;
        },
        expectedReturnMatcher: () => null,
        testDescription: 'should return null as the source location',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return dcChanged.packageLicenseStatus;
        },
        expectedReturnMatcher: () => LicenseStatus.needsApproval,
        testDescription:
            "should return needs approval, if a previously approved package change it's license",
      ),
    ];

    for (var t in validTests) {
      test(t.testDescription, () async {
        expect(await t.testProperty(dc), t.expectedReturnMatcher());
      });
    }
  });

  group('Not a package with pubspec.yaml', () {
    final config =
        Config.fromFile(File('test/lib/src/fixtures/valid_config.yaml'));
    final dc = DependencyChecker(
      config: config,
      package: Package(
        'padres',
        Uri(
          scheme: 'file',
          path:
              '${Directory.current.absolute.path}/test/lib/src/fixtures/padres/',
        ),
      ),
    );

    final validTests = <DependencyTest<Object?>>[
      DependencyTest<Object?>(
        testProperty: (d) => d.name,
        expectedReturnMatcher: () => 'padres',
        testDescription: 'should get the package name from Package',
      ),
      DependencyTest<Object?>(
        testProperty: (d) => dc.licenseFile?.path,
        expectedReturnMatcher: () =>
            '${Directory.current.absolute.path}/test/lib/src/fixtures/padres/LICENSE',
        testDescription: 'should return the license file',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.licenseName;
        },
        expectedReturnMatcher: () => 'MIT',
        testDescription: 'should return the license name',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.packageLicenseStatus;
        },
        expectedReturnMatcher: () => LicenseStatus.rejected,
        testDescription: 'should return that this license is rejected',
      ),
      DependencyTest<Object?>(
        testProperty: (d) async {
          return d.copyright;
        },
        expectedReturnMatcher: () => unknownCopyright,
        testDescription: 'should return $unknownCopyright',
      ),
      DependencyTest<Object?>(
        testProperty: (d) => d.sourceLocation,
        expectedReturnMatcher: () => isNull,
        testDescription: 'should return null for pubspec.yaml file',
      ),
    ];

    for (var t in validTests) {
      test(t.testDescription, () async {
        expect(await t.testProperty(dc), t.expectedReturnMatcher());
      });
    }
  });
}
