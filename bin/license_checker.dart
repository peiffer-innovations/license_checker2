import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:io/io.dart';
import 'package:license_checker2/command_runner.dart';
import 'package:license_checker2/src/commands/check_license.dart';
import 'package:license_checker2/src/commands/generate_disclaimer.dart';
import 'package:license_checker2/src/commands/utils.dart';

void main(List<String> arguments) async {
  exitCode = ExitCode.success.code;

  final cmd = LicenseCommandRunner()
    ..addCommand(CheckLicenses())
    ..addCommand(GenerateDisclaimer());

  try {
    final errors = await cmd.run(arguments);
    if (errors != null && errors != 0) {
      exitCode = ExitCode.software.code;
    }
  } on UsageException catch (e) {
    printError(e.message);
    print('');
    print(e.usage);
    exitCode = ExitCode.usage.code;
  }
}
