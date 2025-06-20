import 'dart:io';

import 'package:license_checker2/src/dependency_checker.dart';
import 'package:license_checker2/src/package_checker.dart';

/// Type defintion for the function that formats the display of the parsed license
/// result.
typedef LicenseDisplayFunction<D> = D Function({
  required String packageName,
  required LicenseStatus licenseStatus,
  required String licenseName,
});

/// Encapsulates a generic license display along with a priority that can be used
/// for sorting.
class LicenseDisplayWithPriority<D> {
  LicenseDisplayWithPriority._({
    required this.display,
    required this.licenseName,
    required this.name,
    required this.priority,
    required this.sourceLocation,
    required this.status,
  });

  /// Constructs the displayed license with a priority set by status.
  factory LicenseDisplayWithPriority.withStatusPriority({
    required D display,
    required String? licenseName,
    required LicenseStatus licenseStatus,
    required String packageName,
    required String? sourceLocation,
  }) {
    var priority = 0;
    switch (licenseStatus) {
      case LicenseStatus.approved:
        {
          priority = 1;
          break;
        }
      case LicenseStatus.permitted:
        {
          priority = 1;
          break;
        }
      case LicenseStatus.unknown:
        {
          priority = 2;
          break;
        }
      case LicenseStatus.rejected:
        {
          priority = 5;
          break;
        }
      case LicenseStatus.needsApproval:
        {
          priority = 4;
          break;
        }
      case LicenseStatus.noLicense:
        {
          priority = 3;
          break;
        }
    }
    return LicenseDisplayWithPriority._(
      display: display,
      licenseName: licenseName ?? 'Unknown',
      name: packageName,
      priority: priority,
      sourceLocation: sourceLocation,
      status: licenseStatus,
    );
  }

  /// The formatted license display.
  final D display;

  /// Name of the license.
  final String licenseName;

  /// The priority of the liscense display based on the status.
  final int priority;

  final String? sourceLocation;

  /// The associated license status.
  final LicenseStatus status;

  /// The name of the package
  final String name;
}

/// Checks all licenses in a the package.
///
/// Returns a list of [LicenseDisplayWithPriority] that contains all the parsed
/// licenses. If [filterApproved] is true, then this list will not contain approved
/// package.
///
/// Throws a [FileSystemException] if the necessary files are not found.
Future<List<LicenseDisplayWithPriority<D>>> checkAllPackageLicenses<D>({
  required List<String> ignore,
  required bool showDirectDepsOnly,
  required bool filterApproved,
  required LicenseDisplayFunction<D> licenseDisplay,
  required PackageChecker packageConfig,
  bool sortByPriority = false,
  bool sortByName = false,
}) async {
  final licenses = <LicenseDisplayWithPriority<D>>[];

  for (var package in packageConfig.packages) {
    // Skip packages where we've been explicitly told to ignore them.
    if (ignore.contains(package.name)) {
      continue;
    }
    if (showDirectDepsOnly) {
      // Ignore dependencies not defined in the packages pubspec.yaml
      if (!packageConfig.pubspec.dependencies.containsKey(package.name)) {
        continue;
      }
    }
    final status = await package.packageLicenseStatus;
    if (!filterApproved ||
        (filterApproved &&
            status != LicenseStatus.approved &&
            status != LicenseStatus.permitted)) {
      licenses.add(
        LicenseDisplayWithPriority.withStatusPriority(
          display: await checkPackageLicense(
            package: package,
            licenseDisplay: licenseDisplay,
          ),
          licenseName: await package.licenseName,
          licenseStatus: status,
          packageName: package.name,
          sourceLocation: package.sourceLocation,
        ),
      );
    }
  }

  if (sortByPriority && sortByName) {
    // sort by priority first
    licenses.sort((a, b) {
      final cmp = _prioritySort(a, b);
      if (cmp != 0) {
        return cmp;
      }
      return _alphaSort(a, b);
    });
  } else {
    if (sortByPriority) {
      // Sort by priority
      licenses.sort(_prioritySort);
    }

    if (sortByName) {
      // Sort by name
      licenses.sort(_alphaSort);
    }
  }

  return licenses;
}

/// Check the license of a single package.
///
/// Retruns the formatted license results.
/// Throws a [FileSystemException] if the necessary files are not found.
Future<D> checkPackageLicense<D>({
  required DependencyChecker package,
  required LicenseDisplayFunction<D> licenseDisplay,
}) async {
  return licenseDisplay(
    packageName: package.name,
    licenseStatus: await package.packageLicenseStatus,
    licenseName: await package.licenseName,
  );
}

int _alphaSort<D>(
  LicenseDisplayWithPriority<D> a,
  LicenseDisplayWithPriority<D> b,
) {
  return a.name.compareTo(b.name);
}

int _prioritySort<D>(
  LicenseDisplayWithPriority<D> a,
  LicenseDisplayWithPriority<D> b,
) {
  if (a.priority < b.priority) {
    return -1;
  }
  if (a.priority > b.priority) {
    return 1;
  }
  return 0;
}
