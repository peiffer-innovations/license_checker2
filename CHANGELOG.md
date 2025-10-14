## [2.3.0+2] - October 14, 2025

* Automated dependency updates


## [2.3.0+1] - September 9, 2025

* Automated dependency updates


## 2.3.0 - June 20th, 2025

* Fixed issue with `flutter_gen` when using the legacy `i18n` mechanism.
* Added `--ignore` to completely ignore comma delimited list of packages from the scan.
* Fixed markdown to display the name of the license rather than the status.

## 2.2.0 - June 18th, 2025

* Updated to automatically accept the licenses for packages provided by Dart / Flutter SDKs

## 2.1.0 - June 3rd, 2025

* Updated to support a new Markdown output option to be able to check into Git on runs.
* Updated to support a new `customLicenses` config option where the key is the license name and the value is a RegEx that can be used to detect that particular license to assist with privately hosted packages for commercial software where they're willing to accept their own license or that of certain vendors without constantly having to add overrides to the license.
* Removed disclaimer generation

## 2.0.0 - January 11th, 2025

* Forked
* Updated to work with [Dart Workspaces](https://dart.dev/tools/pub/workspaces)

## 1.5.0

* Allow omitting of all dev dependencies in the generated disclaimer.

## 1.4.0

* Allow overrideing package source locations used in the disclaimer.

## 1.3.0

* Allow overriding package license text used in disclaimer.
* Allow omitting of packages from the generated disclaimer.

## 1.2.1

* Allow unknown license to be approved via the config file

## 1.2.0

* Add yes flag to skip prompts when generating disclaimers
* Fix exit codes

## 1.1.0

* Add version flag
* Use proper exit codes

## 1.0.0

* Add priority and alphabetical sorting option

## 0.0.5

* Fix exit code conditional

## 0.0.4

* Clean up print statements.
* Add successful completion print.
## 0.0.3

* More refactors
* Add tests
* Expose some private library functions
* Add ability to override the parsed copyright notice in the configuration file. ("copyrightNotice" field)

## 0.0.2

* General refactors
* Add disclaimer generator
* Add test

## 0.0.1

* Initial version