import 'dart:io' show Directory, File;
import 'package:path/path.dart' show joinAll;
import 'package:yaml/yaml.dart' show YamlMap, loadYaml;

Future<void> main() async {
  final outputPath =
      joinAll([Directory.current.path, 'lib', 'version.g.dart']);
  final YamlMap pubspec = loadYaml(
    await File(joinAll([Directory.current.path, 'pubspec.yaml']))
        .readAsString(),
  );
  final String currentVersion = pubspec['version'];

  await File(outputPath).writeAsString(
    "// This file is generated. Do not manually edit.\n/// Command version string\nconst String licenseCheckerVersion = '$currentVersion';\n",
  );
}
