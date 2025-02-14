import 'dart:io';

import 'package:license_checker2/src/config.dart';
import 'package:license_checker2/src/dependency_checker.dart';
import 'package:license_checker2/src/package_checker.dart';

/// Type defintion for the function that formats the display of the disclaimer
/// based on the license for the CLI.
typedef DisclaimerCLIDisplayFunction<D> = D Function({
  required String packageName,
  required String licenseName,
  required String copyright,
  required String sourceLocation,
});

/// Type defintion for the function that formats the display of the disclaimer
/// based on the license for a file.
typedef DisclaimerFileDisplayFunction<D> = D Function({
  required String packageName,
  required String licenseName,
  required String copyright,
  required String sourceLocation,
  required File? licenseFile,
});

/// Encapsulates a generic cli and file display.
class DisclaimerDisplay<C, F> {
  /// Default constructor
  DisclaimerDisplay({required this.cli, required this.file});

  /// The display for CLI.
  final C cli;

  /// The display for a file.
  final F file;
}

/// Generate disclaimers for all packages
Future<DisclaimerDisplay<List<C>, List<F>>> generateDisclaimers<C, F>({
  required Config config,
  required PackageChecker packageConfig,
  required bool showDirectDepsOnly,
  required bool noDevDependencies,
  required DisclaimerCLIDisplayFunction<C> disclaimerCLIDisplay,
  required DisclaimerFileDisplayFunction<F> disclaimerFileDisplay,
}) async {
  final disclaimers = DisclaimerDisplay<List<C>, List<F>>(cli: [], file: []);

  for (var package in packageConfig.packages) {
    if (showDirectDepsOnly &&
            !packageConfig.pubspec.dependencies.containsKey(package.name) ||
        config.omitDisclaimer.contains(package.name)) {
      // Ignore dependencies not defined in the packages pubspec.yaml
      // Do not generate disclaimer for ignored packages
      continue;
    }
    if (noDevDependencies &&
        packageConfig.pubspec.devDependencies.containsKey(package.name)) {
      // Ignore dev dependencies
      continue;
    }
    final packageDisclaimer = await generatePackageDisclaimer<C, F>(
      config: config,
      package: package,
      disclaimerCLIDisplay: disclaimerCLIDisplay,
      disclaimerFileDisplay: disclaimerFileDisplay,
    );
    disclaimers.cli.add(packageDisclaimer.cli);
    disclaimers.file.add(packageDisclaimer.file);
  }

  return disclaimers;
}

/// Generate the disclaimer for a single package/
Future<DisclaimerDisplay<C, F>> generatePackageDisclaimer<C, F>({
  required Config config,
  required DependencyChecker package,
  required DisclaimerCLIDisplayFunction<C> disclaimerCLIDisplay,
  required DisclaimerFileDisplayFunction<F> disclaimerFileDisplay,
}) async {
  final copyright =
      config.copyrightNotice[package.name] ?? await package.copyright;
  final licenseName =
      config.packageLicenseOverride[package.name] ?? await package.licenseName;
  final sourceLocation =
      config.packageSourceOverride[package.name] ?? package.sourceLocation;

  return DisclaimerDisplay(
    cli: disclaimerCLIDisplay(
      packageName: package.name,
      copyright: copyright,
      licenseName: licenseName,
      sourceLocation: sourceLocation,
    ),
    file: disclaimerFileDisplay(
      packageName: package.name,
      copyright: copyright,
      licenseName: licenseName,
      sourceLocation: sourceLocation,
      licenseFile: package.licenseFile,
    ),
  );
}
