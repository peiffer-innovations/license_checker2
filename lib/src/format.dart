import 'dart:io';

import 'package:barbecue/barbecue.dart';
import 'package:colorize/colorize.dart';
import 'package:license_checker2/check_license.dart';
import 'package:license_checker2/src/dependency_checker.dart';

/// Formats package licenses using the Markdown format.
String formatLicenseMarkdown(List<LicenseDisplayWithPriority> rows) {
  final buf = StringBuffer();

  buf.writeln('| Package |  Status  | License |');
  buf.writeln('|---------|:--------:|---------|');

  for (final row in rows) {
    final approved = row.status == LicenseStatus.approved ||
        row.status == LicenseStatus.permitted;
    final status = approved ? ':white_check_mark:' : ':x:';
    final (start, end) = approved ? ('', '') : ('**_', '_**');
    buf.writeln(
      '| [${row.name}](${row.sourceLocation ?? 'https://pub.dev/packages/${row.name}'}) | $status | $start${row.status.name}$end |',
    );
  }
  buf.writeln('');

  return buf.toString();
}

/// Formats package licenses as a table.
Table formatLicenseTable(List<Row> rows) {
  return Table(
    tableStyle: TableStyle(border: true),
    header: TableSection(
      rows: [
        Row(
          cells: [
            Cell(
              Colorize('Package Name').bold().toString(),
              style:
                  CellStyle(alignment: TextAlignment.TopRight, paddingRight: 2),
            ),
            Cell(Colorize('License').bold().toString()),
          ],
          cellStyle: CellStyle(borderBottom: true),
        ),
      ],
    ),
    body: TableSection(
      cellStyle: CellStyle(paddingRight: 2),
      rows: rows,
    ),
  );
}

/// Formats a table that shows the output that needs to be verified before
/// generating the disclaimer
Table formatDisclaimerTable(List<Row> rows) {
  return Table(
    tableStyle: TableStyle(border: true),
    header: TableSection(
      rows: [
        Row(
          cells: [
            Cell(
              Colorize('Package Name').bold().toString(),
              style:
                  CellStyle(alignment: TextAlignment.TopRight, paddingRight: 2),
            ),
            Cell(Colorize('License').bold().toString()),
            Cell(Colorize('Detected Copyright').bold().toString()),
            Cell(Colorize('Source Download Location').bold().toString()),
          ],
          cellStyle: CellStyle(borderBottom: true),
        ),
      ],
    ),
    body: TableSection(
      cellStyle: CellStyle(paddingRight: 2),
      rows: rows,
    ),
  );
}

/// Formats the output of the package disclaimer for a file.
StringBuffer formatDisclaimer({
  required String packageName,
  required String licenseName,
  required String copyright,
  required String sourceLocation,
  required File? licenseFile,
}) {
  final disclaimer = StringBuffer();
  final licenseText = licenseFile?.readAsStringSync();

  disclaimer.writeln(
    'The following software may be included in this product: $packageName',
  );
  disclaimer.writeln(
    'A copy of the source code may be downloaded from: $sourceLocation',
  );

  if (licenseText != null || copyright != unknownCopyright) {
    disclaimer.writeln();
    disclaimer.writeln(
      'This software contains the following license and notice below:',
    );
    if (copyright != unknownCopyright) {
      disclaimer.writeln('Copyright (c) $copyright');
    }
    if (licenseText != null) {
      // Remove copyright from license text since it's displayed above.
      disclaimer.writeln(licenseText.replaceFirst(coprightRegex, ''));
    }
    disclaimer.writeln();
  }

  return disclaimer;
}

/// Formats the name of a license based on organization rules.
Colorize formatLicenseName(String name, LicenseStatus licenseStatus) {
  switch (licenseStatus) {
    case LicenseStatus.approved:
    case LicenseStatus.permitted:
      {
        return licenseOKFormat(name);
      }
    case LicenseStatus.rejected:
      {
        return licenseErrorFormat(name);
      }
    case LicenseStatus.unknown:
      {
        return licenseErrorFormat(name);
      }
    case LicenseStatus.noLicense:
      {
        return licenseNoInfoFormat(
          'No license file found. Add to approvedPackages under `$name` license.',
        );
      }
    case LicenseStatus.needsApproval:
      {
        return licenseNeedsApprovalFormat(name);
      }
  }
}

/// Formats the copyright to highlight issues found
Colorize formatCopyright(String copyright) {
  switch (copyright) {
    case unknownCopyright:
      {
        return licenseErrorFormat(copyright);
      }
    default:
      {
        return Colorize(copyright).default_slyle();
      }
  }
}

/// Formats a license row.
Row formatLicenseRow({
  required String packageName,
  required String licenseName,
  required LicenseStatus licenseStatus,
}) {
  return Row(
    cells: [
      Cell(packageName, style: CellStyle(alignment: TextAlignment.TopRight)),
      Cell(formatLicenseName(licenseName, licenseStatus).toString()),
    ],
  );
}

/// Formats the text in grey.
Colorize licenseNoInfoFormat(String text) {
  return Colorize(text).lightGray().bgBlue();
}

/// Formats the text in yellow.
Colorize licenseNeedsApprovalFormat(String text) {
  return Colorize(text).yellow();
}

/// Formats the text in green.
Colorize licenseOKFormat(String text) {
  return Colorize(text).green();
}

/// Formats the text in red.
Colorize licenseErrorFormat(String text) {
  return Colorize(text).red();
}
