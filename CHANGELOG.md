# Auctionator

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
