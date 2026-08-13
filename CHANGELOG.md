# Changelog

All notable changes to Logistician are documented in this file. This project
uses [Semantic Versioning](https://semver.org/) and the
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

## [Unreleased]

## [2.0.0] - 2026-08-13

### Changed

- Limited the addon to TBC Anniversary (`Interface 20506`).
- Migrated all runtime globals, templates, APIs, localization keys, and saved
  variables to the Logistician namespace.
- Removed unsupported client implementations and assets.
- Reorganized shared legacy-era code as explicit TBC support code.

### Breaking

- Previous saved variables are not loaded because the namespace is now
  Logistician-native.

## [1.1.77] - 2026-08-13

### Fixed

- Constrained Shopping result viewports to the legacy Auction House frame.
- Tuned empty and filled Shopping viewport edges independently.
- Added per-tab scrollbar offsets so Shopping adjustments do not affect
  Selling or Cancelling.
- Aligned the Selling and Cancelling viewport right edges with their frames.
- Reduced seller-name text size to improve readability in narrow columns.

### Maintenance

- Established Git version control and GitHub release automation.
- Added repository hygiene, contribution, and release documentation.

[Unreleased]: https://github.com/dfhzcnc/Logistician/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/dfhzcnc/Logistician/releases/tag/v2.0.0
[1.1.77]: https://github.com/dfhzcnc/Logistician/releases/tag/v1.1.77
