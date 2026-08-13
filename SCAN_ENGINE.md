# WPP Scan Engine — 334-WPP3

This custom TBC Anniversary build retains Logistician's single Blizzard full-AH
query and improves the client-side analysis performed on the returned rows.

## Current snapshot

Each database key can store one compact `entry.x` snapshot containing the
10%-depth market price, listing/unit supply, floor and near-floor market depth,
seller concentration/coverage, and median stack size. Existing price/history
fields are unchanged.

## Tooltips

Normal item tooltips show the literal Auction price and robust historical Avg.
Hold Alt to reveal Market (10% depth), sale likelihood, model confidence, and
the detailed current market structure.

## Full scan diagnostics

The scan status cycles through Query, Read, Depth, Save, and Finish. Completion
chat output reports cached auction rows, elapsed time, and scan quality.

## API

See `Source/API/v1/README.md` for the market snapshot/depth APIs.

## WPP3 reliability improvements

- High-quality full scans record watched items that disappear completely.
- Partial searches cannot create absence observations.
- Database scan jobs are serialized so searches cannot cancel full-scan saves.
- Watched exposure history expires when both watch and retention windows lapse.
- The hard observation cap accommodates the documented 14-day thinning tiers.
- Interval price continuity prefers the robust 10%-depth price over the floor.
- Well-covered seller-concentration changes reduce cancellation/relist ambiguity.
