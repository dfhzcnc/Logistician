# Changelog

All notable changes to Logistician are documented in this file. This project
uses [Semantic Versioning](https://semver.org/) and the
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

## [Unreleased]

## [2.2.0] - 2026-08-16

### Added

- Added exact required bank quantities and one-click material withdrawal with bag-space validation.
- Added a movable, position-saving Materials sidecar for relevant production goals at the bank.

### Improved

- Made the profession Logistician window movable with persistent positioning.
- Kept the bank Materials sidecar visible after withdrawing the final required item for the current bank session.

### Fixed

- Corrected production-goal progress in the bank Materials sidecar.
- Restored Mining/Smelting profession switching when resuming mixed-profession crafting queues.

## [2.1.0] - 2026-08-16

### Added

- Added paged production goals with independent crafting queues and bills of materials.
- Added complete BOM coverage indicators, bank markers, scrolling, and per-goal removal.
- Added material-level conversion with synchronized queue and quantity calculations.
- Added favorite crafting materials with profession and bag indicators.
- Added one Auction House procurement list per production goal without covered or vendor items.

### Improved

- Refined profession-panel navigation, icons, item selection, and queue controls.

## [2.0.1] - 2026-08-13

### Fixed

- Restored the stable Auction House interface and initialization path.
- Preserved compatibility with existing shopping lists and scan history.
- Removed item-level suffixes from the selected Selling item name.
- Reduced the selected Selling item icon from 60 to 40 pixels.

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

## Inherited Auctionator history

## 334-WPP3 (scan reliability and confidence)

- Records zero-supply observations for watched items absent from >=98% quality
  full scans, while excluding partial searches.
- Serializes database processing jobs so searches no longer cancel full-scan
  commits or strand completion callbacks.
- Fixes watched-history expiry and raises the observation cap to 224.
- Uses 10%-depth price for interval continuity when available.
- Adds seller-structure reliability to reduce cancellation/relist ambiguity.

## 334-WPP2 (custom TBC Anniversary scan engine)

- Replaced fixed full-scan row sleeps with adaptive ~3 ms frame-time budgets.
- Corrected legacy full-scan enumeration to use auction indices 1..N.
- Removed overlapping batch boundaries in scan aggregation/database processing.
- Added cold-cache item resolution and scan completeness/quality telemetry.
- Added compact current market snapshots: 10%-depth price, listing/unit supply,
  floor/+5/+10/+20% depth, seller concentration, and median stack size.
- Enriched watched-item exposure observations while preserving old history data.
- Sale Likelihood now blends the literal floor with the 10%-depth market price
  when measuring current price attractiveness.
- Added public v1 APIs for market snapshot and market depth price.
- Added Market (10% depth) tooltip; hold Alt for detailed AH structure.
- Added scan progress phases and final auction-count/time/quality diagnostics.
- Completed hard-coded `Interface\AddOns\!Auctionator` asset-path migration.
- Preserves the existing Auctionator SavedVariables schema and price history.

## [334](https://github.com/TheMouseNest/Auctionator/tree/334) (2026-08-11)
[Full Changelog](https://github.com/TheMouseNest/Auctionator/compare/333...334) 

- Update toc for 12.1.0  

[Unreleased]: https://github.com/dfhzcnc/Logistician/compare/v2.2.0...HEAD
[2.2.0]: https://github.com/dfhzcnc/Logistician/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/dfhzcnc/Logistician/compare/v2.0.1...v2.1.0
[2.0.1]: https://github.com/dfhzcnc/Logistician/releases/tag/v2.0.1
[1.1.77]: https://github.com/dfhzcnc/Logistician/releases/tag/v1.1.77
