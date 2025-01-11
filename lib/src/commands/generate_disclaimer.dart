import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:barbecue/barbecue.dart';
import 'package:io/io.dart';
import 'package:license_checker2/src/commands/utils.dart';
import 'package:license_checker2/src/format.dart';
import 'package:license_checker2/src/generate_disclaimer.dart';
import 'package:license_checker2/src/package_checker.dart';
import 'package:path/path.dart';

/// Command that generates a disclaimer from all dependencies.
class GenerateDisclaimer extends Command<int> {
  /// Creates the generate-disclaimer command and adds two flags.
  /// The [file] flag allows the user to customize name of the discalimer file.
  /// The [path] flag allows the user to customize the write location for the discalimer file.
  GenerateDisclaimer() {
    argParser
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Write the disclaimers to the file without prompting.',
      )
      ..addFlag(
        'noDev',
        abbr: 'n',
        help: 'Do not include dev dependencies in the disclaimer.',
        negatable: false,
      )
      ..addOption(
        'file',
        abbr: 'f',
        help: 'The name of the disclaimer file.',
        defaultsTo: 'DISCLAIMER',
      )
      ..addOption(
        'path',
        abbr: 'p',
        help: 'The path at which to write the disclaimer.',
        defaultsTo: Directory.current.path,
      );
  }
  @override
  final String name = 'generate-disclaimer';
  @override
  final String description =
      'Generates a disclaimer that includes all licenses.';

  @override
  Future<int> run() async {
    final String disclaimerName = argResults?['file'];
    final String outputPath = argResults?['path'];
    final bool noDevDependencies = argResults?['noDev'];
    final bool skipPrompts = argResults?['yes'];
    final bool showDirectDepsOnly = globalResults?['direct'];
    final String configPath = globalResults?['config'];

    final config = loadConfig(configPath);
    if (config == null) {
      return ExitCode.ioError.code;
    }

    printInfo(
      'Generating disclaimer for ${showDirectDepsOnly ? 'direct' : 'all'} dependencies ...',
    );

    final packageConfig =
        await PackageChecker.fromCurrentDirectory(config: config);

    final disclaimer = await generateDisclaimers<Row, StringBuffer>(
      config: config,
      packageConfig: packageConfig,
      showDirectDepsOnly: showDirectDepsOnly,
      noDevDependencies: noDevDependencies,
      disclaimerCLIDisplay: formatDisclaimerRow,
      disclaimerFileDisplay: formatDisclaimer,
    );

    print(
      formatDisclaimerTable(disclaimer.cli).render(),
    );

    // Write disclaimer
    final outputFilePath = join(outputPath, disclaimerName);
    if (skipPrompts) {
      _writeFile(outputFilePath: outputFilePath, disclaimer: disclaimer);
      return ExitCode.success.code;
    }

    final correctInfo = _promptYN('Is this information correct?');
    if (correctInfo) {
      final writeFile = _promptYN(
        'Would you like to write the disclaimer to $outputFilePath?',
      );
      if (writeFile) {
        _writeFile(outputFilePath: outputFilePath, disclaimer: disclaimer);
      } else {
        printError('Did not write disclaimer.');
      }
    } else {
      printError('User stopped the disclaimer writing process.');
      return ExitCode.cantCreate.code;
    }

    return ExitCode.success.code;
  }

  bool _promptYN(String prompt) {
    stdout.write('$prompt (y/n): ');
    final input = stdin.readLineSync();
    if (input == 'y') {
      return true;
    }
    if (input == 'n') {
      return false;
    }
    // not y or n, so repromted
    stdout.writeln('you entered $input, please enter y or n.');
    return _promptYN(prompt);
  }

  void _writeFile({
    required DisclaimerDisplay<List<Row>, List<StringBuffer>> disclaimer,
    required String outputFilePath,
  }) {
    final output = File(outputFilePath);
    printInfo('Writing disclaimer to file $outputFilePath ...');
    final disclaimerText = StringBuffer();
    for (var d in disclaimer.file) {
      disclaimerText.write(d.toString());
    }
    output.writeAsStringSync(disclaimerText.toString());

    printSuccess('Finished writing disclaimer.');
  }
}
