Displays the license of dependencies. Permitted, rejected and approved packages are configurable
through a YAML config file.

# Fork

**Note** this is a fork of [license_checker](https://pub.dev/packages/license_checker) as it appears that package was abandoned and no longer works with the new [Dart Workspaces](https://dart.dev/tools/pub/workspaces) feature.

# Install

`dart pub global activate license_checker2`

# Getting Started

Create a YAML config file. Example:

```yaml
permittedLicenses:
  - MIT
  - BSD-3-Clause

approvedPackages:
  Apache-2.0:
    - barbecue

# RegEx that can use custom detectors to detect the licensedar
customLicenses:
  MyCompany: |-
    (\(c\))?©?\sMy Company Name

rejectedLicenses:
  - GPL

copyrightNotice:
  mlb: "2000 MLB."

packageLicenseOverride:
  dodgers: BSD-3-Clause

packageSourceOverride:
  dodgers: https://dodgers.com
```

This file can be referenced when calling `lic_ck check-licenses` with the `--config` option.

`lic_ck` or `lic_ck -h` will display help
