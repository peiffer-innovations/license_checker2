import 'dart:io';

import 'package:yaml/yaml.dart';

/// Represents the config parsed from a config file for the license checker.
class Config {
  Config._({
    required this.approvedPackages,
    required this.copyrightNotice,
    required this.customLicenses,
    required this.omitDisclaimer,
    required this.packageLicenseOverride,
    required this.packageSourceOverride,
    required this.permittedLicenses,
    required this.rejectedLicenses,
  });

  /// Parses and creates config from a file
  factory Config.fromFile(File configFile) {
    if (!configFile.existsSync()) {
      return throw FileSystemException(
        '${configFile.path} file not found in current directory.',
      );
    }

    final YamlMap config = loadYaml(configFile.readAsStringSync());

    final Object? permittedLicenses = config['permittedLicenses'];
    final Object? rejectedLicenses = config['rejectedLicenses'];
    final Object? approvedPackages = config['approvedPackages'];
    final Object? copyrightNotice = config['copyrightNotice'];
    final Object? customLicenses = config['customLicenses'];
    final Object? packageLicenseOverride = config['packageLicenseOverride'];
    final Object? packageSourceOverride = config['packageSourceOverride'];
    final Object? omitDisclaimer = config['omitDisclaimer'];
    if (permittedLicenses == null) {
      return throw FormatException('`permittedLicenses` not defined');
    }
    if (permittedLicenses is! List) {
      return throw FormatException(
        '`permittedLicenses` is not defined as a list',
      );
    }
    if (rejectedLicenses != null && rejectedLicenses is! List) {
      return throw FormatException(
        '`rejectedLicenses` is not defined as a list',
      );
    }
    if (omitDisclaimer != null && omitDisclaimer is! List) {
      return throw FormatException(
        '`omitDisclaimer` is not defined as a list',
      );
    }

    var stringRejectLicenses = <String>[];
    var stringOmitDisclaimer = <String>[];
    final stringLicenses = permittedLicenses.whereType<String>().toList();
    if (rejectedLicenses != null && rejectedLicenses is List) {
      stringRejectLicenses = rejectedLicenses.whereType<String>().toList();
    }
    if (omitDisclaimer != null && omitDisclaimer is List) {
      stringOmitDisclaimer = omitDisclaimer.whereType<String>().toList();
    }

    final checkedApprovedPackages = <String, List<String>>{};
    if (approvedPackages != null) {
      if (approvedPackages is! Map) {
        return throw FormatException('`approvedPackages` not defined as a map');
      }
      for (var entry in approvedPackages.entries) {
        final Object license = entry.key;
        final Object packages = entry.value;
        if (license is! String) {
          return throw FormatException(
            '`approvedPackages` must be keyed by a string license name',
          );
        }
        if (packages is! List) {
          return throw FormatException(
            '`approvedPackages` value must specified as a list',
          );
        }

        final stringApprovedPackages = packages.whereType<String>().toList();

        checkedApprovedPackages[license] = stringApprovedPackages;
      }
    }

    final checkedCustomLicenses = _checkStringMap(
      customLicenses,
      'customLicenses',
    );
    final checkedCopyrightNotice =
        _checkStringMap(copyrightNotice, 'copyrightNotice');

    final checkedPackageLicenseOverride =
        _checkStringMap(packageLicenseOverride, 'packageLicenseOverride');

    final checkedPackageSourceOverride =
        _checkStringMap(packageSourceOverride, 'packageSourceOverride');

    return Config._(
      approvedPackages: checkedApprovedPackages,
      copyrightNotice: checkedCopyrightNotice,
      customLicenses: checkedCustomLicenses,
      omitDisclaimer: stringOmitDisclaimer,
      packageLicenseOverride: checkedPackageLicenseOverride,
      packageSourceOverride: checkedPackageSourceOverride,
      permittedLicenses: stringLicenses,
      rejectedLicenses: stringRejectLicenses,
    );
  }

  /// [List] of permitted license.
  final List<String> permittedLicenses;

  /// [List] of licenses that are not allowed to be used by default.
  final List<String> rejectedLicenses;

  /// [Map] for packages by license that have been explicitly approved.
  final Map<String, List<String>> approvedPackages;

  /// [Map] to override copyright notices for packages, if they are not parsed correctly.
  final Map<String, String> copyrightNotice;

  final Map<String, String> customLicenses;

  /// [Map] to override licenses for packages, if they are not parsed correctly.
  final Map<String, String> packageLicenseOverride;

  /// [Map] to override the source location for packages, if they are not parsed correctly
  /// or present in the pubspec.yaml.
  final Map<String, String> packageSourceOverride;

  /// [List] of packages who's license and copyright notice should not be added to the discalimer
  final List<String> omitDisclaimer;
}

Map<String, String> _checkStringMap(Object? map, String variableName) {
  final checkedMap = <String, String>{};
  if (map != null) {
    if (map is! Map) {
      return throw FormatException('`$variableName` not defined as a map');
    }
    for (var entry in map.entries) {
      final Object mapKey = entry.key;
      final Object mapValue = entry.value;

      if (mapKey is! String) {
        return throw FormatException(
          '`$variableName` must be keyed by a string',
        );
      }

      if (mapValue is! String) {
        return throw FormatException(
          '`$variableName` value must be a string',
        );
      }
      checkedMap[mapKey] = mapValue;
    }
  }

  return checkedMap;
}
