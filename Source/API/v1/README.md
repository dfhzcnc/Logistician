# Logistician External API

Calling any other functions related to Logistician is not supported and may
break without warning in future releases.

This API is intended to remain stable.

```lua
-- Returns the last scanned price for an item identified by itemID
-- Returns the price in coppers, or nil if one wasn't found
Logistician.API.v1.GetAuctionPriceByItemID(callerID, itemID)

-- Returns the last scanned price for an item identified by itemLink
-- Returns the price in coppers, or nil if one wasn't found
Logistician.API.v1.GetAuctionPriceByItemLink(callerID, itemLink)

-- Searches for an array of search terms and displays the results
-- The auction house MUST be open.
Logistician.API.v1.MultiSearch(callerID, terms)
```


### Current market snapshot / depth price (custom integrated build)

```lua
Logistician.API.v1.GetMarketSnapshotByItemID(callerID, itemID)
Logistician.API.v1.GetMarketSnapshotByItemLink(callerID, itemLink)
Logistician.API.v1.GetMarketPriceByItemID(callerID, itemID)
Logistician.API.v1.GetMarketPriceByItemLink(callerID, itemLink)
```

On the legacy Classic/TBC AH, the full scan retains a compact structural
snapshot from the same auction rows already returned by Blizzard. No extra AH
query is issued. The snapshot includes the literal minimum price, a 10%-depth
market price, listing and unit counts, quantity at the price floor, quantity
within +5/+10/+20% of the floor, known seller count, top-seller share, seller
data coverage, and median stack size.

`GetMarketPrice...` returns the 10%-depth price in copper. It is designed as a
more robust current-market reference than a one-unit undercut; it is not a
claim about a completed sale price.


### Robust historical average (custom integrated build)

```lua
Logistician.API.v1.GetAuctionAverageByItemID(callerID, itemID, days)
Logistician.API.v1.GetAuctionAverageByItemLink(callerID, itemLink, days)
```

The first return value is the robust historical auction price in copper. The
optional second and third return values are the number of historical day
samples used and the number of samples rejected by the final Tukey biweight
stage.

The estimator uses Logistician's stored daily price history, log-price space,
exponential recency weighting, a Huber M-estimator warm start, and Tukey
biweight refinement.


### Sale likelihood / marketability score (custom integrated build)

```lua
Logistician.API.v1.GetSaleLikelihoodByItemID(callerID, itemID, days)
Logistician.API.v1.GetSaleLikelihoodByItemLink(callerID, itemLink, days)
```

Returns a 0-100 score, qualitative label, confidence label, and a details table.

This score is intentionally not described as a calibrated probability of a
completed sale: Logistician's historical database observes listing-market
snapshots, not verified outcomes for every auction. The model combines
Bayesian-shrunk stock-depletion evidence, current price versus robust history,
relative supply pressure, robust price stability, and recency, then shrinks
toward 50 when evidence is sparse.


### Expiration-aware exposure history (custom integrated build)

```lua
Logistician.API.v1.GetSaleExposureHistoryByItemID(callerID, itemID)
```

Returns compact watched-item scan observations used by the Sale Likelihood
model. Legacy fields remain timestamp, total quantity, minimum price, and
quantity in each legacy AH remaining-time band. New observations can also
append the 10%-depth market price, listing count, floor quantity, +10% depth,
seller count, top-seller share, seller-data coverage, and median stack size.
Older SavedVariables observations remain valid because the original field
positions are unchanged.

The Sale Likelihood model treats inventory that could naturally expire before
the next scan as censored exposure rather than assuming disappearance means a
sale. Because cancellation cannot be distinguished perfectly from a purchase
with the legacy API, the result remains a conservative marketability score
rather than a claimed completed-sale probability.
