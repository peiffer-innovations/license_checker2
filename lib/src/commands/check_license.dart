import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:barbecue/barbecue.dart';
import 'package:io/io.dart';
import 'package:license_checker2/src/check_license.dart';
import 'package:license_checker2/src/commands/utils.dart';
import 'package:license_checker2/src/dependency_checker.dart';
import 'package:license_checker2/src/format.dart';
import 'package:license_checker2/src/package_checker.dart';

/// Command that checks license for compliance.
class CheckLicenses extends Command<int> {
  /// Creates the check-license command and add a flag to show only "problematic"
  /// packages (non approved and permitted packages).
  CheckLicenses() {
    argParser
      ..addOption(
        'ignore',
        abbr: 'g',
        help: 'Packages to ignore; separated by a comma',
      )
      ..addFlag(
        'problematic',
        abbr: 'i',
        help:
            'Show only package with problematic license statuses (filter approved and permitted packages).',
        negatable: false,
        defaultsTo: false,
      )
      ..addFlag(
        'alpha-sort',
        abbr: 'a',
        help: 'Sort list of packages alphabetically',
        defaultsTo: false,
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file path',
      )
      ..addFlag(
        'priority-sort',
        abbr: 'p',
        help: 'Sort list of packages by the priority of their license status',
        defaultsTo: false,
      );
  }

  @override
  final String name = 'check-licenses';
  @override
  final String description =
      'Checks licenses of all dependencies for compliance.';

  @override
  Future<int> run() async {
    final bool filterApproved = argResults?['problematic'];
    final bool prioritySort = argResults?['priority-sort'];
    final bool alphaSort = argResults?['alpha-sort'];
    final bool showDirectDepsOnly = globalResults?['direct'];
    final String configPath = globalResults?['config'];
    final String? outputPath = argResults?['output'];
    final List<String> ignore =
        argResults?['ignore']?.split(',') ?? const <String>[];

    if (filterApproved) {
      printInfo('Filtering out approved packages ...');
    }

    final config = loadConfig(configPath);
    if (config == null) {
      return ExitCode.ioError.code;
    }

    printInfo(
      'Checking ${showDirectDepsOnly ? 'direct' : 'all'} dependencies ...',
    );

    var rows = <LicenseDisplayWithPriority<Row>>[];
    try {
      final packageConfig =
          await PackageChecker.fromCurrentDirectory(config: config);
      rows = await checkAllPackageLicenses<Row>(
        ignore: ignore,
        packageConfig: packageConfig,
        showDirectDepsOnly: showDirectDepsOnly,
        filterApproved: filterApproved,
        licenseDisplay: formatLicenseRow,
        sortByPriority: prioritySort,
        sortByName: alphaSort,
      );
    } on FileSystemException catch (error) {
      printError(error.message);
      return ExitCode.ioError.code;
    }

    if (rows.isNotEmpty) {
      print(formatLicenseTable(rows.map((e) => e.display).toList()).render());
    }

    if (outputPath != null) {
      final outputFile = File(outputPath);
      try {
        if (outputFile.existsSync()) {
          outputFile.createSync(recursive: true);
        }
        final outputContent = formatLicenseMarkdown(rows);
        await outputFile.writeAsString(
          outputContent,
          flush: true,
        );
        printInfo('Output written to $outputPath');
      } on FileSystemException catch (error) {
        printError('Failed to write output: ${error.message}');
        return ExitCode.ioError.code;
      }
    }

    final failed = rows.where((r) =>
        r.status != LicenseStatus.approved &&
        r.status != LicenseStatus.permitted);

    for (final f in failed) {
      printError(
        'Package: [${f.name}] failed due to license: [${f.licenseName}] and status: [${f.status.name}].',
      );
    }

    var code = ExitCode.software.code;

    if (failed.isEmpty) {
      code = ExitCode.success.code;
      printSuccess('No package licenses need approval!');
    }

    // Return error status code if any package has a license that has not been approved.
    return code;
  }
}
