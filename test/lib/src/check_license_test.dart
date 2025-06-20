import 'dart:io';

import 'package:license_checker2/src/check_license.dart';
import 'package:license_checker2/src/dependency_checker.dart';
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
  final Pubspec pubspec = Pubspec(
    {
      'name': 'MLB',
      'dependencies': {'Dodgers': '1.0.0', 'Giants': '1.0.0'},
    },
  );
}

void main() {
  group('Check License', () {
    String licenseDisplay({
      required String packageName,
      required LicenseStatus licenseStatus,
      required String licenseName,
    }) {
      return '$packageName $licenseName ${licenseStatus.toString()}';
    }

    test('should check the license and return the display for one package',
        () async {
      final DependencyChecker package =
          MockedDependencyChecker('Dodgers', LicenseStatus.approved);

      expect(
        await checkPackageLicense(
          package: package,
          licenseDisplay: licenseDisplay,
        ),
        'Dodgers swag LicenseStatus.approved',
      );
    });

    test('should check the license of all dependencies of a package', () async {
      final PackageChecker packageConfig = MockedPackageChecker([
        MockedDependencyChecker('Dodgers', LicenseStatus.approved),
        MockedDependencyChecker('Giants', LicenseStatus.rejected),
      ]);
      final result = await checkAllPackageLicenses(
        ignore: [],
        packageConfig: packageConfig,
        showDirectDepsOnly: false,
        filterApproved: false,
        licenseDisplay: licenseDisplay,
      );

      expect(result.map((e) => e.display.toString()), [
        'Dodgers swag LicenseStatus.approved',
        'Giants swag LicenseStatus.rejected',
      ]);

      expect(result.map((e) => e.status), [
        LicenseStatus.approved,
        LicenseStatus.rejected,
      ]);
    });

    test('should check the license of direct dependencies of a package',
        () async {
      final PackageChecker packageConfig = MockedPackageChecker([
        MockedDependencyChecker('Dodgers', LicenseStatus.approved),
        MockedDependencyChecker('Giants', LicenseStatus.rejected),
        MockedDependencyChecker('Kings', LicenseStatus.approved),
      ]);
      final result = await checkAllPackageLicenses(
        ignore: [],
        packageConfig: packageConfig,
        showDirectDepsOnly: true,
        filterApproved: false,
        licenseDisplay: licenseDisplay,
      );

      expect(result.map((e) => e.display.toString()), [
        'Dodgers swag LicenseStatus.approved',
        'Giants swag LicenseStatus.rejected',
      ]);

      expect(result.map((e) => e.status), [
        LicenseStatus.approved,
        LicenseStatus.rejected,
      ]);
    });

    test(
        'should check the license of all dependencies of a package and filter out approved and permitted license',
        () async {
      final PackageChecker packageConfig = MockedPackageChecker([
        MockedDependencyChecker('Dodgers', LicenseStatus.approved),
        MockedDependencyChecker('Giants', LicenseStatus.rejected),
        MockedDependencyChecker('Angles', LicenseStatus.unknown),
        MockedDependencyChecker('As', LicenseStatus.permitted),
        MockedDependencyChecker('Padres', LicenseStatus.needsApproval),
        MockedDependencyChecker('Rockies', LicenseStatus.noLicense),
      ]);
      final result = await checkAllPackageLicenses(
        ignore: [],
        packageConfig: packageConfig,
        showDirectDepsOnly: false,
        filterApproved: true,
        licenseDisplay: licenseDisplay,
      );

      expect(result.map((e) => e.display.toString()), [
        'Giants swag LicenseStatus.rejected',
        'Angles swag LicenseStatus.unknown',
        'Padres swag LicenseStatus.needsApproval',
        'Rockies swag LicenseStatus.noLicense',
      ]);

      expect(result.map((e) => e.status), [
        LicenseStatus.rejected,
        LicenseStatus.unknown,
        LicenseStatus.needsApproval,
        LicenseStatus.noLicense,
      ]);
    });

    test(
        'should check the license of all dependencies and sort them correctly by status priority',
        () async {
      final PackageChecker packageConfig = MockedPackageChecker([
        MockedDependencyChecker('Dodgers', LicenseStatus.approved),
        MockedDependencyChecker('Giants', LicenseStatus.rejected),
        MockedDependencyChecker('Angles', LicenseStatus.unknown),
        MockedDependencyChecker('As', LicenseStatus.permitted),
        MockedDependencyChecker('Padres', LicenseStatus.needsApproval),
        MockedDependencyChecker('Rockies', LicenseStatus.noLicense),
      ]);
      final result = await checkAllPackageLicenses(
        ignore: [],
        packageConfig: packageConfig,
        showDirectDepsOnly: false,
        filterApproved: false,
        licenseDisplay: licenseDisplay,
        sortByPriority: true,
      );

      expect(result.map((e) => e.display.toString()), [
        'Dodgers swag LicenseStatus.approved',
        'As swag LicenseStatus.permitted',
        'Angles swag LicenseStatus.unknown',
        'Rockies swag LicenseStatus.noLicense',
        'Padres swag LicenseStatus.needsApproval',
        'Giants swag LicenseStatus.rejected',
      ]);

      expect(result.map((e) => e.status), [
        LicenseStatus.approved,
        LicenseStatus.permitted,
        LicenseStatus.unknown,
        LicenseStatus.noLicense,
        LicenseStatus.needsApproval,
        LicenseStatus.rejected,
      ]);
    });

    test(
        'should check the license of all dependencies and sort them correctly by name',
        () async {
      final PackageChecker packageConfig = MockedPackageChecker([
        MockedDependencyChecker('Dodgers', LicenseStatus.approved),
        MockedDependencyChecker('Giants', LicenseStatus.rejected),
        MockedDependencyChecker('Angles', LicenseStatus.unknown),
        MockedDependencyChecker('As', LicenseStatus.permitted),
        MockedDependencyChecker('Padres', LicenseStatus.needsApproval),
        MockedDependencyChecker('Rockies', LicenseStatus.noLicense),
      ]);
      final result = await checkAllPackageLicenses(
        ignore: [],
        packageConfig: packageConfig,
        showDirectDepsOnly: false,
        filterApproved: false,
        licenseDisplay: licenseDisplay,
        sortByName: true,
      );

      expect(result.map((e) => e.display.toString()), [
        'Angles swag LicenseStatus.unknown',
        'As swag LicenseStatus.permitted',
        'Dodgers swag LicenseStatus.approved',
        'Giants swag LicenseStatus.rejected',
        'Padres swag LicenseStatus.needsApproval',
        'Rockies swag LicenseStatus.noLicense',
      ]);

      expect(result.map((e) => e.status), [
        LicenseStatus.unknown,
        LicenseStatus.permitted,
        LicenseStatus.approved,
        LicenseStatus.rejected,
        LicenseStatus.needsApproval,
        LicenseStatus.noLicense,
      ]);
    });

    test(
        'should check the license of all dependencies and sort them correctly by status priority and then name',
        () async {
      final PackageChecker packageConfig = MockedPackageChecker([
        MockedDependencyChecker('Dodgers', LicenseStatus.approved),
        MockedDependencyChecker('Giants', LicenseStatus.rejected),
        MockedDependencyChecker('Angles', LicenseStatus.unknown),
        MockedDependencyChecker('As', LicenseStatus.permitted),
        MockedDependencyChecker('Padres', LicenseStatus.needsApproval),
        MockedDependencyChecker('Rockies', LicenseStatus.noLicense),
      ]);
      final result = await checkAllPackageLicenses(
        ignore: [],
        packageConfig: packageConfig,
        showDirectDepsOnly: false,
        filterApproved: false,
        licenseDisplay: licenseDisplay,
        sortByPriority: true,
        sortByName: true,
      );

      expect(result.map((e) => e.display.toString()), [
        'As swag LicenseStatus.permitted',
        'Dodgers swag LicenseStatus.approved',
        'Angles swag LicenseStatus.unknown',
        'Rockies swag LicenseStatus.noLicense',
        'Padres swag LicenseStatus.needsApproval',
        'Giants swag LicenseStatus.rejected',
      ]);

      expect(result.map((e) => e.status), [
        LicenseStatus.permitted,
        LicenseStatus.approved,
        LicenseStatus.unknown,
        LicenseStatus.noLicense,
        LicenseStatus.needsApproval,
        LicenseStatus.rejected,
      ]);
    });
  });
}
