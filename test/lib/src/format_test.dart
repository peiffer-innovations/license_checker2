import 'package:colorize/colorize.dart';
import 'package:license_checker2/src/dependency_checker.dart';
import 'package:license_checker2/src/format.dart';
import 'package:test/test.dart';

class _ColorizeTest {
  _ColorizeTest({
    required this.color,
    required this.formatFunction,
    required this.testDescription,
  });
  final Colorize color;
  final Colorize formatFunction;
  final String testDescription;
}

void main() {
  group('Colorize formatting functions', () {
    const text = 'opening day';
    final colorizeTests = <_ColorizeTest>[
      _ColorizeTest(
        color: Colorize(text).lightGray().bgBlue(),
        formatFunction: licenseNoInfoFormat(text),
        testDescription:
            'should color no license info as gray with blue background',
      ),
      _ColorizeTest(
        color: Colorize(text).yellow(),
        formatFunction: licenseNeedsApprovalFormat(text),
        testDescription: 'should color needs approval in yellow',
      ),
      _ColorizeTest(
        color: Colorize(text).green(),
        formatFunction: licenseOKFormat(text),
        testDescription: 'should color approved in green',
      ),
      _ColorizeTest(
        color: Colorize(text).red(),
        formatFunction: licenseErrorFormat(text),
        testDescription: 'should color rejected in red',
      ),
      _ColorizeTest(
        color: Colorize(unknownCopyright).red(),
        formatFunction: formatCopyright(unknownCopyright),
        testDescription: 'should color unknown copyright in red',
      ),
      _ColorizeTest(
        color: Colorize(text).default_slyle(),
        formatFunction: formatCopyright(text),
        testDescription: 'should color known copyright in default style',
      ),
      _ColorizeTest(
        color: Colorize(text).green(),
        formatFunction: formatLicenseName(text, LicenseStatus.permitted),
        testDescription: 'should color permitted license name in green',
      ),
      _ColorizeTest(
        color: Colorize(text).green(),
        formatFunction: formatLicenseName(text, LicenseStatus.approved),
        testDescription: 'should color approved license name in green',
      ),
      _ColorizeTest(
        color: Colorize(text).red(),
        formatFunction: formatLicenseName(text, LicenseStatus.rejected),
        testDescription: 'should color rejected license name in red',
      ),
      _ColorizeTest(
        color: Colorize(text).red(),
        formatFunction: formatLicenseName(text, LicenseStatus.unknown),
        testDescription: 'should color unknown license name in red',
      ),
      _ColorizeTest(
        color: Colorize(
          'No license file found. Add to approvedPackages under `$text` license.',
        ).lightGray().bgBlue(),
        formatFunction: formatLicenseName(text, LicenseStatus.noLicense),
        testDescription:
            'should color no license in gray with blue background with proper text',
      ),
      _ColorizeTest(
        color: Colorize(text).yellow(),
        formatFunction: formatLicenseName(text, LicenseStatus.needsApproval),
        testDescription:
            'should color license name that needs approval in yellow',
      ),
    ];

    for (var t in colorizeTests) {
      test(t.testDescription, () {
        expect(t.formatFunction.toString(), t.color.toString());
      });
    }
  });

  group('License table formatting', () {
    final r = formatLicenseRow(
      licenseName: 'baseball',
      licenseStatus: LicenseStatus.unknown,
      packageName: 'mlb',
    );
    test('should properly format a row', () {
      expect(r.cells.length, equals(2));
      expect(r.cells.first.content, equals('mlb'));
      expect(r.cells.last.content, contains('baseball'));
    });

    test('should properly format the table', () {
      final t = formatLicenseTable([r]);

      expect(t.body.rows.length, equals(1));
      expect(t.body.rows[0].cells.length, equals(2));
      expect(t.header?.rows.length, equals(1));
      expect(t.header?.rows.first.cells.length, equals(2));
      expect(t.header?.rows.first.cells[0].content, contains('Package Name'));
      expect(t.header?.rows.first.cells[1].content, contains('License'));
    });
  });
}
