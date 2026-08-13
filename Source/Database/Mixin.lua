local LibCBOR = LibStub("LibCBOR-1.0")

local function GetScanDay()
  return (math.floor ((time() - Logistician.Constants.SCAN_DAY_0) / (86400)));
end

local daysSinceZero = tostring(GetScanDay())

-- -------------------------------------------------------------------------
-- Robust historical market average
--
-- Logistician's price history stores, for each day:
--   l = lowest minimum auction price seen that day
--   h = highest minimum auction price seen that day
--
-- For one daily observation we use the geometric midpoint of those two
-- positive prices (equivalently: their midpoint in log-price space).
--
-- The robust center is deliberately NOT a plain arithmetic mean:
--   1. Work in log-price space, so multiplicative moves are symmetric.
--   2. Give newer days exponentially more weight.
--   3. Warm-start with a Huber M-estimator (bounded influence).
--   4. Refine with Tukey's biweight; severe isolated outliers can receive
--      zero final weight.
--
-- References used for the model:
--   Peter J. Huber, "Robust Estimation of a Location Parameter" (1964)
--   NIST/SEMATECH robust biweight location / MAD documentation
--   NIST/SEMATECH exponential smoothing documentation
-- -------------------------------------------------------------------------

local ROBUST_AVG_HUBER_C = 1.345
local ROBUST_AVG_TUKEY_C = 6
local ROBUST_AVG_MAX_ITERATIONS = 12
local ROBUST_AVG_CONVERGENCE = 1e-7
local ROBUST_AVG_MIN_LOG_SIGMA = math.log(1.05)
local ROBUST_AVG_LN2 = math.log(2)

local function WeightedQuantile(samples, quantile, valueFunction)
  if #samples == 0 then
    return nil
  end

  local values = {}
  local totalWeight = 0

  for _, sample in ipairs(samples) do
    local weight = sample.timeWeight or 1
    local value = valueFunction(sample)

    if value ~= nil and weight > 0 then
      table.insert(values, {
        value = value,
        weight = weight,
      })
      totalWeight = totalWeight + weight
    end
  end

  if #values == 0 or totalWeight <= 0 then
    return nil
  end

  table.sort(values, function(a, b)
    return a.value < b.value
  end)

  local target = totalWeight * quantile
  local running = 0

  for _, entry in ipairs(values) do
    running = running + entry.weight
    if running >= target then
      return entry.value
    end
  end

  return values[#values].value
end

local function WeightedMedian(samples, valueFunction)
  return WeightedQuantile(samples, 0.5, valueFunction)
end

local function CombinedLocation(samples, weightFunction)
  local weightedTotal = 0
  local totalWeight = 0

  for _, sample in ipairs(samples) do
    local robustWeight = weightFunction(sample)
    local weight = (sample.timeWeight or 1) * robustWeight

    if weight > 0 then
      weightedTotal = weightedTotal + sample.logPrice * weight
      totalWeight = totalWeight + weight
    end
  end

  if totalWeight <= 0 then
    return nil
  end

  return weightedTotal / totalWeight
end

local function BuildRobustPriceSamples(entry, days)
  local samples = {}
  local today = GetScanDay()
  local halfLifeDays = math.max(7, days / 2)

  for rawDay, highSeen in pairs(entry.h or {}) do
    local day = tonumber(rawDay)
    local age = day and (today - day) or nil

    if age and age >= 0 and age < days then
      local lowSeen = (entry.l and entry.l[rawDay]) or highSeen
      highSeen = highSeen or lowSeen

      if type(lowSeen) == "number"
          and type(highSeen) == "number"
          and lowSeen > 0
          and highSeen > 0 then

        -- Midpoint on log scale == geometric midpoint sqrt(low * high), but
        -- avoids multiplication overflow and keeps ratio changes symmetric.
        local logPrice = (math.log(lowSeen) + math.log(highSeen)) / 2
        local timeWeight = math.exp(
          -ROBUST_AVG_LN2 * age / halfLifeDays
        )

        table.insert(samples, {
          logPrice = logPrice,
          age = age,
          timeWeight = timeWeight,
        })
      end
    end
  end

  return samples
end

local function HuberWarmStart(samples, center)
  for _ = 1, ROBUST_AVG_MAX_ITERATIONS do
    local rawMAD = WeightedMedian(samples, function(sample)
      return math.abs(sample.logPrice - center)
    end) or 0

    -- 1.4826 makes MAD approximately sigma-consistent for Gaussian data.
    -- A 5% log-price floor prevents a zero-MAD market from becoming unable
    -- to adapt when several recent observations establish a genuine new level.
    local sigma = math.max(
      rawMAD * 1.4826,
      ROBUST_AVG_MIN_LOG_SIGMA
    )

    local threshold = ROBUST_AVG_HUBER_C * sigma

    local nextCenter = CombinedLocation(samples, function(sample)
      local residual = math.abs(sample.logPrice - center)

      if residual <= threshold or residual == 0 then
        return 1
      end

      return threshold / residual
    end)

    if not nextCenter then
      break
    end

    if math.abs(nextCenter - center) <= ROBUST_AVG_CONVERGENCE then
      center = nextCenter
      break
    end

    center = nextCenter
  end

  return center
end

local function TukeyRefinement(samples, center)
  local rejected = 0

  for _ = 1, ROBUST_AVG_MAX_ITERATIONS do
    local rawMAD = WeightedMedian(samples, function(sample)
      return math.abs(sample.logPrice - center)
    end) or 0

    local scale = math.max(
      rawMAD,
      ROBUST_AVG_MIN_LOG_SIGMA / 1.4826
    )

    local nextCenter = CombinedLocation(samples, function(sample)
      local u = (sample.logPrice - center)
        / (ROBUST_AVG_TUKEY_C * scale)

      if math.abs(u) >= 1 then
        return 0
      end

      local oneMinusUSquared = 1 - (u * u)
      return oneMinusUSquared * oneMinusUSquared
    end)

    if not nextCenter then
      break
    end

    if math.abs(nextCenter - center) <= ROBUST_AVG_CONVERGENCE then
      center = nextCenter
      break
    end

    center = nextCenter
  end

  local rawMAD = WeightedMedian(samples, function(sample)
    return math.abs(sample.logPrice - center)
  end) or 0

  local scale = math.max(
    rawMAD,
    ROBUST_AVG_MIN_LOG_SIGMA / 1.4826
  )

  for _, sample in ipairs(samples) do
    local u = (sample.logPrice - center)
      / (ROBUST_AVG_TUKEY_C * scale)

    if math.abs(u) >= 1 then
      rejected = rejected + 1
    end
  end

  return center, rejected
end


-- -------------------------------------------------------------------------
-- Sale likelihood / marketability model
--
-- IMPORTANT:
-- Logistician does not observe verified completed sales for every listing.
-- Therefore this is deliberately exposed as a 0-100 "Sale Likelihood" score,
-- NOT as a calibrated probability that a specific auction will sell.
--
-- Signals available in Logistician's own historical database:
--   m = most recent minimum buyout price
--   l/h = daily low/high minimum prices
--   a = highest quantity observed that day
--
-- Model:
--   * Bayesian Beta shrinkage estimates directional stock-depletion pressure
--     from day-to-day quantity changes. Static quantity is treated as
--     uninformative rather than as evidence of no demand.
--   * Price attractiveness compares latest price to the robust historical
--     average in log-ratio space.
--   * Supply pressure compares latest observed quantity to that item's own
--     robust historical median quantity (not to other item classes).
--   * Price stability is measured with weighted MAD in log-price space.
--   * Recency exponentially discounts stale observations.
--   * Final evidence confidence shrinks the score toward neutral (50) when
--     history is sparse, so one or two scans cannot create an extreme score.
--
-- Mathematical references:
--   - Beta-Binomial conjugate updating for uncertain rates/proportions.
--   - Huber robust location and MAD-based robust scale.
--   - Exponentially decreasing time weights (NIST time-series guidance).
-- -------------------------------------------------------------------------

local SELLABILITY_PRIOR_ALPHA = 2
local SELLABILITY_PRIOR_BETA = 2
local SELLABILITY_HALF_LIFE_DAYS = 7
local SELLABILITY_PRICE_SCALE = math.log(1.20)
local SELLABILITY_SUPPLY_SCALE = math.log(1.50)
local SELLABILITY_STABILITY_SCALE = math.log(1.35)

local function Clamp01(value)
  if value < 0 then
    return 0
  elseif value > 1 then
    return 1
  else
    return value
  end
end

local function SellabilitySigmoid(value)
  if value >= 0 then
    local z = math.exp(-value)
    return 1 / (1 + z)
  else
    local z = math.exp(value)
    return z / (1 + z)
  end
end

local function SellabilityLabel(score)
  if score >= 78 then
    return "Very High"
  elseif score >= 63 then
    return "High"
  elseif score >= 42 then
    return "Medium"
  elseif score >= 27 then
    return "Low"
  else
    return "Very Low"
  end
end

local function SellabilityConfidenceLabel(confidence)
  if confidence >= 0.75 then
    return "High"
  elseif confidence >= 0.45 then
    return "Medium"
  else
    return "Low"
  end
end

local function BuildSellabilitySamples(entry, days)
  local samples = {}
  local today = GetScanDay()
  local halfLife = SELLABILITY_HALF_LIFE_DAYS

  for rawDay, highSeen in pairs(entry.h or {}) do
    local day = tonumber(rawDay)
    local age = day and (today - day) or nil

    if age and age >= 0 and age < days then
      local lowSeen = (entry.l and entry.l[rawDay]) or highSeen
      highSeen = highSeen or lowSeen

      if type(lowSeen) == "number"
          and type(highSeen) == "number"
          and lowSeen > 0
          and highSeen > 0 then

        table.insert(samples, {
          day = day,
          age = age,
          logPrice = (math.log(lowSeen) + math.log(highSeen)) / 2,
          available = entry.a and entry.a[rawDay] or nil,
          timeWeight = math.exp(
            -ROBUST_AVG_LN2 * age / halfLife
          ),
        })
      end
    end
  end

  table.sort(samples, function(a, b)
    return a.day < b.day
  end)

  return samples
end

local function AvailabilityMedian(samples)
  local availableSamples = {}

  for _, sample in ipairs(samples) do
    if type(sample.available) == "number" and sample.available >= 0 then
      table.insert(availableSamples, sample)
    end
  end

  if #availableSamples == 0 then
    return nil, 0
  end

  return WeightedMedian(availableSamples, function(sample)
    return sample.available
  end), #availableSamples
end

local function LatestAvailability(samples)
  for i = #samples, 1, -1 do
    if type(samples[i].available) == "number"
        and samples[i].available >= 0 then
      return samples[i].available, samples[i].age
    end
  end

  return nil, nil
end

local function PriceStability(samples)
  if #samples < 2 then
    return 0.5, nil
  end

  local center = WeightedMedian(samples, function(sample)
    return sample.logPrice
  end)

  local mad = WeightedMedian(samples, function(sample)
    return math.abs(sample.logPrice - center)
  end) or 0

  -- A perfectly stable market approaches 1. Larger multiplicative dispersion
  -- smoothly lowers stability without any one price outlier dominating it.
  local stability = math.exp(
    -mad / SELLABILITY_STABILITY_SCALE
  )

  return Clamp01(stability), mad
end

local function StockDepletionPosterior(samples)
  local alpha = SELLABILITY_PRIOR_ALPHA
  local beta = SELLABILITY_PRIOR_BETA
  local evidenceWeight = 0
  local informativeIntervals = 0

  local previous = nil

  for _, current in ipairs(samples) do
    if type(current.available) == "number" and current.available >= 0 then
      if previous then
        local gap = current.day - previous.day

        -- Large gaps are too ambiguous: stock can expire/relist several times.
        -- Use only nearby observations, with wider gaps downweighted.
        if gap >= 1 and gap <= 3 then
          local previousQuantity = previous.available
          local currentQuantity = current.available

          if previousQuantity ~= currentQuantity then
            local logRatio = math.log(
              (currentQuantity + 1) / (previousQuantity + 1)
            )

            -- A 2x quantity move is enough to count as a full informative
            -- interval; smaller changes contribute fractionally.
            local magnitude = math.min(
              1,
              math.abs(logRatio) / ROBUST_AVG_LN2
            )

            local recencyWeight = math.exp(
              -ROBUST_AVG_LN2
                * current.age
                / SELLABILITY_HALF_LIFE_DAYS
            )

            local weight = magnitude
              * recencyWeight
              / math.sqrt(gap)

            if currentQuantity < previousQuantity then
              -- Stock depletion: evidence toward easier sell-through.
              alpha = alpha + weight
            else
              -- Stock accumulation: evidence toward harder sell-through.
              beta = beta + weight
            end

            evidenceWeight = evidenceWeight + weight
            informativeIntervals = informativeIntervals + 1
          end
        end
      end

      previous = current
    end
  end

  return alpha / (alpha + beta), evidenceWeight, informativeIntervals
end

local function PriceAttractiveness(currentPrice, robustAverage)
  if not currentPrice or currentPrice <= 0
      or not robustAverage or robustAverage <= 0 then
    return 0.5
  end

  -- Equal to history => 0.5.
  -- Roughly 20% below history => ~0.73; 20% above => ~0.27.
  local logRatio = math.log(currentPrice / robustAverage)
  return SellabilitySigmoid(
    -logRatio / SELLABILITY_PRICE_SCALE
  )
end

local function RelativeSupplyScore(latestAvailable, historicalMedian)
  if latestAvailable == nil
      or historicalMedian == nil then
    return 0.5
  end

  -- Compare this item ONLY with its own normal stock depth.
  -- Lower-than-usual supply supports sellability; higher-than-usual supply
  -- suggests more competition.
  local logRatio = math.log(
    (latestAvailable + 1) / (historicalMedian + 1)
  )

  return SellabilitySigmoid(
    -logRatio / SELLABILITY_SUPPLY_SCALE
  )
end

local function RecencyScore(age)
  if age == nil then
    return 0.25
  end

  return math.exp(
    -ROBUST_AVG_LN2 * age / SELLABILITY_HALF_LIFE_DAYS
  )
end


-- -------------------------------------------------------------------------
-- Expiration-aware market exposure history (TBC / legacy AH)
--
-- Legacy GetAuctionItemTimeLeft exposes four remaining-time bands:
--   0 = < 30 minutes
--   1 = 30 minutes - 2 hours
--   2 = 2 hours - 12 hours
--   3 = 12 hours - 48 hours
--
-- Sellers choose 12 / 24 / 48 hour listing durations, but the scan API does
-- not reveal the original duration for other players' auctions. Remaining-time
-- bands are enough to model EXPIRATION RISK directly:
--
--   * inventory expected to expire before the next scan is treated as
--     censored and contributes neither a "sale" nor a "failure to sell";
--   * disappearance from inventory that mathematically should still be alive
--     is sale-like depletion (still not proof of a completed sale because a
--     seller may cancel an auction);
--   * new/relisted supply lowers interval reliability rather than being
--     mistaken for proof that nothing sold.
--
-- To keep SavedVariables bounded, detailed observations are only retained for
-- items whose Sale Likelihood tooltip/API has been requested recently.
--
-- Observation array layout (compact SavedVariables representation):
--   [1] timestamp
--   [2] total quantity
--   [3] minimum unit price
--   [4] qty in <30m band
--   [5] qty in 30m-2h band
--   [6] qty in 2h-12h band
--   [7] qty in 12h-48h band
-- Enhanced fields appended by the integrated scan build (old observations
-- remain valid because the expiry model only requires fields 1..7):
--   [8] 10%-depth market price
--   [9] listing count
--   [10] floor quantity
--   [11] quantity within 10% of floor
--   [12] known seller count
--   [13] top seller share (basis points)
--   [14] seller-data coverage (basis points)
--   [15] median stack size
--
-- Statistical interpretation:
-- This is an interval-censoring / survival-style exposure model. Within each
-- coarse Blizzard time-left band, remaining lifetime is assigned a uniform
-- maximum-entropy prior because the API gives no finer information.
-- -------------------------------------------------------------------------

local SALE_EXPOSURE_WATCH_SECONDS = 30 * 86400
local SALE_EXPOSURE_RETENTION_SECONDS = 14 * 86400
local SALE_EXPOSURE_REPLACE_SECONDS = 5 * 60
-- The documented thinning schedule can retain about 212 observations across
-- 14 days (144 + 24 + 44). Leave a small margin so the hard cap does not
-- silently truncate the oldest tier on frequently scanned items.
local SALE_EXPOSURE_MAX_OBSERVATIONS = 224

local TIME_LEFT_BOUNDS_HOURS = {
  { 0,    0.5 },
  { 0.5,  2   },
  { 2,   12   },
  { 12,  48   },
}

local function ObservationTimestamp(observation)
  return observation and tonumber(observation[1]) or nil
end

local function ObservationQuantity(observation)
  return observation and tonumber(observation[2]) or nil
end

local function ObservationPrice(observation)
  return observation and tonumber(observation[3]) or nil
end

local function ObservationMarketPrice(observation)
  local marketPrice = observation and tonumber(observation[8]) or nil
  if marketPrice and marketPrice > 0 then
    return marketPrice
  end
  return ObservationPrice(observation)
end

local function ObservationTopSellerShare(observation)
  if not observation or observation[13] == nil then return nil end
  return Clamp01((tonumber(observation[13]) or 0) / 10000)
end

local function ObservationSellerCoverage(observation)
  if not observation or observation[14] == nil then return nil end
  return Clamp01((tonumber(observation[14]) or 0) / 10000)
end

local function ObservationBandQuantity(observation, bandIndex)
  return observation and tonumber(observation[3 + bandIndex]) or 0
end

local function ExpiryProbabilityForBand(bandIndex, elapsedHours)
  local bounds = TIME_LEFT_BOUNDS_HOURS[bandIndex]
  if not bounds then
    return 0
  end

  local lower = bounds[1]
  local upper = bounds[2]

  if elapsedHours <= lower then
    return 0
  elseif elapsedHours >= upper then
    return 1
  end

  return (elapsedHours - lower) / (upper - lower)
end

local function PruneExposureObservations(observations, now)
  if type(observations) ~= "table" or #observations == 0 then
    return {}
  end

  table.sort(observations, function(a, b)
    return (ObservationTimestamp(a) or 0) < (ObservationTimestamp(b) or 0)
  end)

  -- Adaptive thinning:
  --   last 24h: retain roughly one observation per 10 minutes
  --   1-3 days : one per 2 hours
  --   3-14 days: one per 6 hours
  -- This keeps recent expiration transitions detailed without allowing a
  -- heavily-scanned item to grow forever.
  local retainedReverse = {}
  local lastKeptByTier = {}

  for i = #observations, 1, -1 do
    local observation = observations[i]
    local timestamp = ObservationTimestamp(observation)

    if timestamp and now - timestamp <= SALE_EXPOSURE_RETENTION_SECONDS then
      local age = now - timestamp
      local tier, spacing

      if age <= 86400 then
        tier = 1
        spacing = 10 * 60
      elseif age <= 3 * 86400 then
        tier = 2
        spacing = 2 * 3600
      else
        tier = 3
        spacing = 6 * 3600
      end

      local lastKept = lastKeptByTier[tier]

      if not lastKept or lastKept - timestamp >= spacing then
        table.insert(retainedReverse, observation)
        lastKeptByTier[tier] = timestamp
      end
    end
  end

  local retained = {}
  for i = #retainedReverse, 1, -1 do
    table.insert(retained, retainedReverse[i])
  end

  if #retained > SALE_EXPOSURE_MAX_OBSERVATIONS then
    local trimmed = {}
    local startIndex = #retained - SALE_EXPOSURE_MAX_OBSERVATIONS + 1

    for i = startIndex, #retained do
      table.insert(trimmed, retained[i])
    end

    retained = trimmed
  end

  return retained
end

local function BuildExposureObservation(
  timestamp,
  totalQuantity,
  minimumPrice,
  timeBands,
  marketSnapshot
)
  marketSnapshot = marketSnapshot or {}

  return {
    timestamp,
    math.max(0, tonumber(totalQuantity) or 0),
    math.max(0, tonumber(minimumPrice) or 0),
    math.max(0, tonumber(timeBands and timeBands[1]) or 0),
    math.max(0, tonumber(timeBands and timeBands[2]) or 0),
    math.max(0, tonumber(timeBands and timeBands[3]) or 0),
    math.max(0, tonumber(timeBands and timeBands[4]) or 0),
    math.max(0, tonumber(marketSnapshot.marketPrice) or 0),
    math.max(0, tonumber(marketSnapshot.listingCount) or 0),
    math.max(0, tonumber(marketSnapshot.floorQuantity) or 0),
    math.max(0, tonumber(marketSnapshot.depth10) or 0),
    math.max(0, tonumber(marketSnapshot.sellerCount) or 0),
    math.max(0, math.floor((tonumber(marketSnapshot.topSellerShare) or 0) * 10000 + 0.5)),
    math.max(0, math.floor((tonumber(marketSnapshot.sellerCoverage) or 0) * 10000 + 0.5)),
    math.max(0, tonumber(marketSnapshot.medianStack) or 0),
  }
end

local function GetExpiryAwareTurnover(entry, days)
  local observations = entry and entry.o

  if type(observations) ~= "table" or #observations < 2 then
    return 0.5, 0, 0, 0, 0
  end

  local now = time()
  local cutoff = now - math.max(1, tonumber(days) or 21) * 86400
  local usable = {}

  for _, observation in ipairs(observations) do
    local timestamp = ObservationTimestamp(observation)
    if timestamp and timestamp >= cutoff then
      table.insert(usable, observation)
    end
  end

  table.sort(usable, function(a, b)
    return (ObservationTimestamp(a) or 0) < (ObservationTimestamp(b) or 0)
  end)

  if #usable < 2 then
    return 0.5, 0, 0, 0, #usable
  end

  -- Symmetric Beta(2,2) prior. Evidence is interval-weighted rather than
  -- quantity-counted, preventing one enormous commodity stack from generating
  -- unjustified certainty from a single scan transition.
  local alpha = 2
  local beta = 2
  local evidenceWeight = 0
  local informativeIntervals = 0
  local expectedExpiredTotal = 0
  local startingExposureTotal = 0

  for i = 2, #usable do
    local previous = usable[i - 1]
    local current = usable[i]

    local previousTime = ObservationTimestamp(previous)
    local currentTime = ObservationTimestamp(current)
    local elapsedHours =
      previousTime and currentTime
      and (currentTime - previousTime) / 3600
      or nil

    -- Intervals beyond 12 hours are too ambiguous for high-resolution
    -- expiration inference: multiple expiry/relist cycles can occur.
    if elapsedHours
        and elapsedHours >= (5 / 60)
        and elapsedHours <= 12 then

      local previousBandTotal = 0
      local expectedNonExpired = 0
      local expectedExpired = 0

      for bandIndex = 1, 4 do
        local quantity = ObservationBandQuantity(previous, bandIndex)
        previousBandTotal = previousBandTotal + quantity

        local expiryProbability =
          ExpiryProbabilityForBand(bandIndex, elapsedHours)

        expectedExpired =
          expectedExpired + quantity * expiryProbability

        expectedNonExpired =
          expectedNonExpired
          + quantity * (1 - expiryProbability)
      end

      if previousBandTotal > 0 and expectedNonExpired > 0 then
        local currentQuantity = ObservationQuantity(current) or 0

        -- This is deliberately conservative:
        -- any newly posted inventory in currentQuantity masks disappearance,
        -- so sale-like depletion is a LOWER BOUND rather than an inflated one.
        local saleLikeDepletion =
          math.max(0, expectedNonExpired - currentQuantity)

        local turnoverFraction =
          Clamp01(saleLikeDepletion / expectedNonExpired)

        -- Small intervals carry little opportunity for turnover; very long
        -- intervals become less attributable. Peak information is around the
        -- 30m-6h range.
        local intervalOpportunity =
          math.min(1, elapsedHours / 0.5)
          * math.exp(
              -ROBUST_AVG_LN2
              * math.max(0, elapsedHours - 0.5)
              / 12
            )

        -- Large price regime changes make two snapshots less comparable.
        -- Prefer the unit-weighted 10%-depth price. The literal floor is
        -- vulnerable to a single one-unit undercut and can make two otherwise
        -- comparable snapshots look like a price-regime break.
        local previousPrice = ObservationMarketPrice(previous)
        local currentPrice = ObservationMarketPrice(current)
        local priceContinuity = 1

        if previousPrice and previousPrice > 0
            and currentPrice and currentPrice > 0 then
          priceContinuity = math.exp(
            -math.abs(math.log(currentPrice / previousPrice))
              / math.log(1.75)
          )
        end

        -- If total stock increased beyond expected survivors, new/relisted
        -- supply is clearly present. Do not turn that into strong negative
        -- "nothing sold" evidence; reduce interval reliability instead.
        local supplyInflux =
          math.max(0, currentQuantity - expectedNonExpired)

        local relistReliability =
          expectedNonExpired
          / math.max(expectedNonExpired, expectedNonExpired + supplyInflux)

        -- Abrupt changes in a well-observed top seller's share are compatible
        -- with cancellation/relisting as well as sales. Reduce attribution
        -- modestly when seller coverage is sufficient to make that signal
        -- meaningful; old observations without enhanced fields remain neutral.
        local sellerStructureReliability = 1
        local previousCoverage = ObservationSellerCoverage(previous)
        local currentCoverage = ObservationSellerCoverage(current)
        local previousTopShare = ObservationTopSellerShare(previous)
        local currentTopShare = ObservationTopSellerShare(current)

        if previousCoverage and currentCoverage
            and previousTopShare and currentTopShare then
          local coveredFraction = math.min(previousCoverage, currentCoverage)
          local concentrationChange =
            Clamp01(math.abs(currentTopShare - previousTopShare) / 0.5)
          sellerStructureReliability =
            1 - 0.35 * coveredFraction * concentrationChange
        end

        -- Saturating quantity term: enough exposure improves usefulness, but
        -- 500 auctions should not make one interval 50x more convincing than
        -- 10 auctions.
        local exposureReliability =
          1 - math.exp(-expectedNonExpired / 10)

        local latestAgeHours = math.max(0, (now - currentTime) / 3600)
        local recencyWeight =
          math.exp(
            -ROBUST_AVG_LN2
            * latestAgeHours
            / (SELLABILITY_HALF_LIFE_DAYS * 24)
          )

        local intervalWeight =
          intervalOpportunity
          * priceContinuity
          * relistReliability
          * sellerStructureReliability
          * exposureReliability
          * recencyWeight

        if intervalWeight > 0.01 then
          alpha = alpha + turnoverFraction * intervalWeight
          beta = beta + (1 - turnoverFraction) * intervalWeight

          evidenceWeight = evidenceWeight + intervalWeight
          informativeIntervals = informativeIntervals + 1
          expectedExpiredTotal = expectedExpiredTotal + expectedExpired
          startingExposureTotal =
            startingExposureTotal + previousBandTotal
        end
      end
    end
  end

  local censoredFraction = 0
  if startingExposureTotal > 0 then
    censoredFraction =
      Clamp01(expectedExpiredTotal / startingExposureTotal)
  end

  return alpha / (alpha + beta),
    evidenceWeight,
    informativeIntervals,
    censoredFraction,
    #usable
end

Logistician.DatabaseMixin = {}
function Logistician.DatabaseMixin:Init(db)
  self.db = db
  self.cutoffDay = GetScanDay() - Logistician.Config.Get(Logistician.Config.Options.PRICE_HISTORY_DAYS)
end

function Logistician.DatabaseMixin:SetPrice(dbKey, buyoutPrice, available)
  if not self.db[dbKey] then
    self.db[dbKey] = {
      l={}, -- Lowest low price on a given day
      h={}, -- Highest low price on a given day
      a={}, -- Highest quantity seen on a given day
      m=0   -- Last seen minimum price
    }
  end

  local priceData = self.db[dbKey]
  priceData.m = buyoutPrice

  -- Record price history
  local lowestLow  = priceData.l[daysSinceZero]
  local highestLow = priceData.h[daysSinceZero]

  if highestLow == nil or buyoutPrice > highestLow then
    priceData.h[daysSinceZero] = buyoutPrice
    highestLow = buyoutPrice
  end

  -- save memory by only saving lowestLow when different from highestLow
  if buyoutPrice < highestLow and (lowestLow == nil or buyoutPrice < lowestLow) then
    priceData.l[daysSinceZero] = buyoutPrice
  end

  if available ~= nil then
    -- Compatibility for databases without "Available" information in them, all
    -- databases prior to December 2020 would not have the "a" field in them
    if priceData.a == nil then
      priceData.a = {}
    end

    local prevAvailable = priceData.a[daysSinceZero]
    if prevAvailable ~= nil then
      priceData.a[daysSinceZero] = math.max(prevAvailable, available)
    else
      priceData.a[daysSinceZero] = available
    end
  end

  local cutoffDay = self.cutoffDay

  local daysToRemove = {}
  -- Prune old days
  for day, _ in pairs(priceData.h) do
    if tonumber(day) <= cutoffDay then
      priceData.h[day] = nil
    end
  end

  for day, _ in pairs(priceData.l) do
    if tonumber(day) <= cutoffDay then
      priceData.l[day] = nil
    end
  end

  if priceData.a ~= nil then
    for day, _ in pairs(priceData.a) do
      if tonumber(day) <= cutoffDay then
        priceData.a[day] = nil
      end
    end
  end
end

-- -------------------------------------------------------------------------
-- Enhanced current-market snapshot
--
-- The stock database historically reduces a scan to the minimum price and
-- total quantity. The scan already contains every listing, so we can retain a
-- compact structural snapshot without issuing any additional AH queries.
--
-- Stored compactly in entry.x:
--   [1] timestamp
--   [2] 10%-depth market price (unit-weighted)
--   [3] listing count
--   [4] total quantity
--   [5] quantity at the exact floor price
--   [6] quantity within 5% of floor
--   [7] quantity within 10% of floor
--   [8] quantity within 20% of floor
--   [9] known seller count
--   [10] top seller share, basis points
--   [11] seller-data coverage, basis points
--   [12] median stack size
--
-- The 10%-depth price is intentionally not called a sale price. It is a more
-- robust current-market reference than a one-unit undercut while remaining
-- directly grounded in listings that are actually available to buy.
-- -------------------------------------------------------------------------

local function BuildCurrentMarketSnapshot(info, minimumPrice, totalQuantity)
  local listingCount = 0
  local priceQuantities = {}
  local stackSizes = {}
  local sellerQuantities = {}
  local knownSellerQuantity = 0

  for _, listing in ipairs(info or {}) do
    local price = tonumber(listing.price) or 0
    local quantity = tonumber(listing.available) or 0

    if price > 0 and quantity > 0 then
      listingCount = listingCount + 1
      priceQuantities[price] = (priceQuantities[price] or 0) + quantity
      table.insert(stackSizes, quantity)

      local owner = listing.owner
      if type(owner) == "string" and owner ~= "" then
        sellerQuantities[owner] = (sellerQuantities[owner] or 0) + quantity
        knownSellerQuantity = knownSellerQuantity + quantity
      end
    end
  end

  if listingCount == 0 or not minimumPrice or minimumPrice <= 0 then
    return nil
  end

  totalQuantity = math.max(0, tonumber(totalQuantity) or 0)

  local floorQuantity = 0
  local depth5 = 0
  local depth10 = 0
  local depth20 = 0
  local prices = {}

  for price, quantity in pairs(priceQuantities) do
    table.insert(prices, price)

    if price == minimumPrice then
      floorQuantity = floorQuantity + quantity
    end
    if price <= minimumPrice * 1.05 then
      depth5 = depth5 + quantity
    end
    if price <= minimumPrice * 1.10 then
      depth10 = depth10 + quantity
    end
    if price <= minimumPrice * 1.20 then
      depth20 = depth20 + quantity
    end
  end

  table.sort(prices)

  local targetQuantity = math.max(1, math.ceil(totalQuantity * 0.10))
  local cumulative = 0
  local marketPrice = minimumPrice

  for _, price in ipairs(prices) do
    cumulative = cumulative + (priceQuantities[price] or 0)
    marketPrice = price
    if cumulative >= targetQuantity then
      break
    end
  end

  table.sort(stackSizes)
  local medianStack = 0
  if #stackSizes > 0 then
    local middle = math.floor((#stackSizes + 1) / 2)
    if #stackSizes % 2 == 1 then
      medianStack = stackSizes[middle]
    else
      medianStack = math.floor((stackSizes[middle] + stackSizes[middle + 1]) / 2 + 0.5)
    end
  end

  local sellerCount = 0
  local topSellerQuantity = 0
  for _, quantity in pairs(sellerQuantities) do
    sellerCount = sellerCount + 1
    if quantity > topSellerQuantity then
      topSellerQuantity = quantity
    end
  end

  local topSellerShare = 0
  local sellerCoverage = 0
  if totalQuantity > 0 then
    topSellerShare = topSellerQuantity / totalQuantity
    sellerCoverage = knownSellerQuantity / totalQuantity
  end

  return {
    timestamp = time(),
    minimumPrice = minimumPrice,
    marketPrice = marketPrice,
    listingCount = listingCount,
    totalQuantity = totalQuantity,
    floorQuantity = floorQuantity,
    depth5 = depth5,
    depth10 = depth10,
    depth20 = depth20,
    sellerCount = sellerCount,
    topSellerShare = Clamp01(topSellerShare),
    sellerCoverage = Clamp01(sellerCoverage),
    medianStack = medianStack,
  }
end

function Logistician.DatabaseMixin:SetMarketSnapshot(dbKey, snapshot)
  local entry = self.db[dbKey]
  if not entry or not snapshot then
    return
  end

  entry.x = {
    snapshot.timestamp or time(),
    snapshot.marketPrice or entry.m or 0,
    snapshot.listingCount or 0,
    snapshot.totalQuantity or 0,
    snapshot.floorQuantity or 0,
    snapshot.depth5 or 0,
    snapshot.depth10 or 0,
    snapshot.depth20 or 0,
    snapshot.sellerCount or 0,
    math.floor((snapshot.topSellerShare or 0) * 10000 + 0.5),
    math.floor((snapshot.sellerCoverage or 0) * 10000 + 0.5),
    snapshot.medianStack or 0,
  }
end

function Logistician.DatabaseMixin:GetMarketSnapshot(dbKey)
  local entry = self.db[dbKey]
  local snapshot = entry and entry.x

  if type(snapshot) ~= "table" then
    return nil
  end

  return {
    timestamp = tonumber(snapshot[1]) or 0,
    minimumPrice = entry.m,
    marketPrice = tonumber(snapshot[2]) or entry.m,
    listingCount = tonumber(snapshot[3]) or 0,
    totalQuantity = tonumber(snapshot[4]) or 0,
    floorQuantity = tonumber(snapshot[5]) or 0,
    depth5 = tonumber(snapshot[6]) or 0,
    depth10 = tonumber(snapshot[7]) or 0,
    depth20 = tonumber(snapshot[8]) or 0,
    sellerCount = tonumber(snapshot[9]) or 0,
    topSellerShare = (tonumber(snapshot[10]) or 0) / 10000,
    sellerCoverage = (tonumber(snapshot[11]) or 0) / 10000,
    medianStack = tonumber(snapshot[12]) or 0,
  }
end

function Logistician.DatabaseMixin:WatchSaleExposure(dbKey)
  local entry = self.db[dbKey]
  if not entry then
    return
  end

  entry.w = time()
end

function Logistician.DatabaseMixin:RecordMarketObservation(
  dbKey,
  minimumPrice,
  available,
  timeBands,
  marketSnapshot
)
  local entry = self.db[dbKey]

  if not entry or type(timeBands) ~= "table" then
    return
  end

  local now = time()

  -- Detailed data is opt-in per item: opening its tooltip/API marks it watched.
  -- Existing retained history keeps an item eligible only until both the watch
  -- window and the observation-retention window have elapsed.
  entry.o = PruneExposureObservations(entry.o or {}, now)
  local watchedRecently =
    entry.w and now - entry.w <= SALE_EXPOSURE_WATCH_SECONDS

  if not watchedRecently then
    if #entry.o == 0 then
      entry.o = nil
      entry.w = nil
    end
    return
  end

  local bandTotal = 0
  for bandIndex = 1, 4 do
    bandTotal =
      bandTotal + math.max(0, tonumber(timeBands[bandIndex]) or 0)
  end

  -- No time-left information means this scan cannot teach the expiry model.
  if bandTotal <= 0 then
    return
  end

  local observation =
    BuildExposureObservation(
      now,
      available,
      minimumPrice,
      timeBands,
      marketSnapshot
    )

  local last = entry.o[#entry.o]
  local lastTime = ObservationTimestamp(last)

  if lastTime and now - lastTime <= SALE_EXPOSURE_REPLACE_SECONDS then
    -- Multiple searches in a few minutes often reflect the same market state.
    -- Replace rather than overweighting it.
    entry.o[#entry.o] = observation
  else
    table.insert(entry.o, observation)
  end

  entry.o = PruneExposureObservations(entry.o, now)
end

-- A sufficiently complete full scan can distinguish a watched item that is
-- truly absent from one merely omitted by a partial search. Record zero supply
-- only from that trusted context so complete depletion becomes learnable.
function Logistician.DatabaseMixin:RecordAbsentWatchedItems(seenKeys, quality)
  quality = tonumber(quality) or 0
  if quality < 0.98 then
    return 0
  end

  seenKeys = seenKeys or {}
  local now = time()
  local recorded = 0

  for dbKey, entry in pairs(self.db) do
    if type(entry) == "table" and not seenKeys[dbKey] then
      entry.o = PruneExposureObservations(entry.o or {}, now)
      local watchedRecently =
        entry.w and now - entry.w <= SALE_EXPOSURE_WATCH_SECONDS

      if watchedRecently then
        local previous = entry.o[#entry.o]
        local previousQuantity = ObservationQuantity(previous) or 0

        -- A zero observation needs no time-band exposure of its own; the
        -- interval model censors from the previous observation's bands.
        if previousQuantity > 0 then
          local observation = BuildExposureObservation(
            now,
            0,
            0,
            { 0, 0, 0, 0 },
            nil
          )
          local lastTime = ObservationTimestamp(previous)
          if lastTime and now - lastTime <= SALE_EXPOSURE_REPLACE_SECONDS then
            entry.o[#entry.o] = observation
          else
            table.insert(entry.o, observation)
          end
          entry.o = PruneExposureObservations(entry.o, now)
          recorded = recorded + 1
        end
      else
        if #entry.o == 0 then
          entry.o = nil
          entry.w = nil
        end
      end
    end
  end

  return recorded
end

function Logistician.DatabaseMixin:GetSaleExposureHistory(dbKey)
  local entry = self.db[dbKey]
  if not entry or type(entry.o) ~= "table" then
    return {}
  end

  return entry.o
end

function Logistician.DatabaseMixin:GetPrice(dbKey)
  if self.db[dbKey] ~= nil then
    return self.db[dbKey].m
  else
    return nil
  end
end

function Logistician.DatabaseMixin:GetFirstPrice(dbKeys)
  for _, dbKey in ipairs(dbKeys) do
    local price = self:GetPrice(dbKey)
    if price then
      return price
    end
  end
  return nil
end

local DATABASE_FRAME_BUDGET_MS = 3.0
local DATABASE_MIN_ITEMS = 20
local DATABASE_MAX_ITEMS = 500

-- Takes all the items with a list of their prices, determines the minimum
-- price, and records a compact current-market structure snapshot. The work is
-- frame-budgeted so faster clients finish sooner without producing long UI
-- stalls on slower clients.
function Logistician.DatabaseMixin:ProcessScan(itemIndexes, callback, progressCallback)
  -- Serialize jobs instead of letting a normal search cancel an in-progress
  -- full-scan commit and strand its completion callback.
  if self.processScanActive then
    self.processScanQueue = self.processScanQueue or {}
    table.insert(self.processScanQueue, {
      itemIndexes = itemIndexes,
      callback = callback,
      progressCallback = progressCallback,
    })
    return
  end

  self.processScanActive = true

  Logistician.Debug.Message("Logistician.DatabaseMixin.ProcessScan")
  local startTime = debugprofilestop()

  local count = 0
  local keys = GetKeysArray(itemIndexes)
  local index = 1
  local totalKeys = #keys

  local function ProcessDatabaseBatch()
    local frameStart = debugprofilestop()
    local processed = 0

    while index <= totalKeys and processed < DATABASE_MAX_ITEMS do
      if processed >= DATABASE_MIN_ITEMS
          and debugprofilestop() - frameStart >= DATABASE_FRAME_BUDGET_MS then
        break
      end

      local dbKey = keys[index]
      local info = itemIndexes[dbKey]
      count = count + 1

      if info and #info > 0 then
        local minPrice = tonumber(info[1].price) or 0
        local available = 0
        local timeBands = { 0, 0, 0, 0 }
        local hasTimeLeftData = false

        for j = 1, #info do
          local quantity = tonumber(info[j].available) or 0
          local price = tonumber(info[j].price) or 0

          if quantity > 0 and price > 0 then
            available = available + quantity
            if minPrice <= 0 or price < minPrice then
              minPrice = price
            end
          end

          local timeLeft = tonumber(info[j].timeLeft)
          if quantity > 0 and timeLeft
              and timeLeft >= 0
              and timeLeft <= 3 then
            local bandIndex = math.floor(timeLeft) + 1
            timeBands[bandIndex] = timeBands[bandIndex] + quantity
            hasTimeLeftData = true
          end
        end

        if minPrice > 0 and available > 0 then
          self:SetPrice(dbKey, minPrice, available)

          local marketSnapshot = nil
          if Logistician.Constants.IsLegacyAH then
            marketSnapshot =
              BuildCurrentMarketSnapshot(info, minPrice, available)

            if marketSnapshot then
              self:SetMarketSnapshot(dbKey, marketSnapshot)
            end
          end

          if hasTimeLeftData then
            self:RecordMarketObservation(
              dbKey,
              minPrice,
              available,
              timeBands,
              marketSnapshot
            )
          end
        end
      end

      index = index + 1
      processed = processed + 1
    end

    if progressCallback then
      if totalKeys == 0 then
        progressCallback(1)
      else
        progressCallback(math.min(1, (index - 1) / totalKeys))
      end
    end

    if index > totalKeys then
      if callback then
        callback(count)
      end
      Logistician.Debug.Message(
        "Logistician.DatabaseMixin: Processing time: "
          .. tostring(debugprofilestop() - startTime)
      )
      self.processScanActive = nil
      local nextJob = self.processScanQueue and table.remove(self.processScanQueue, 1)
      if nextJob then
        C_Timer.After(0, function()
          self:ProcessScan(
            nextJob.itemIndexes,
            nextJob.callback,
            nextJob.progressCallback
          )
        end)
      end
    else
      C_Timer.After(0, ProcessDatabaseBatch)
    end
  end

  ProcessDatabaseBatch()
end

function Logistician.DatabaseMixin:GetItemCount()
  local count = 0
  for _, _ in pairs(self.db) do
    count = count + 1
  end

  return count
end

function Logistician.DatabaseMixin:GetPriceHistory(dbKey)
  if self.db[dbKey] == nil then
    return {}
  end

  local itemData = self.db[dbKey]

  local results = {}

  local sortedDays = Logistician.Utilities.TableKeys(itemData.h)
  table.sort(sortedDays, function(a, b) return b < a end)

  for _, day in ipairs(sortedDays) do
    table.insert(results, {
     date = Logistician.Utilities.PrettyDate(
        tonumber(day) * 86400 + Logistician.Constants.SCAN_DAY_0
     ),
     rawDay = day,
     minSeen = itemData.l[day] or itemData.h[day],
     maxSeen = itemData.h[day],
     -- Compatibility for when the a[vailable] field is unavailable
     available = itemData.a and itemData.a[day],
   })
 end

 return results
end

function Logistician.DatabaseMixin:GetPriceAge(dbKey)
  local itemData = self.db[dbKey] and self.db[dbKey]

  if itemData == nil then
    return
  end

  local days = Logistician.Utilities.TableKeys(itemData.h)

  if #days == 0 then
    return nil
  end

  for index, day in ipairs(days) do
    days[index] = tonumber(day)
  end

  table.sort(days)

  return GetScanDay()-days[#days]
end

function Logistician.DatabaseMixin:GetMeanPrice(dbKey, days)
  local entry = self.db[dbKey] and self.db[dbKey]

  if entry == nil or days < 0 then
    return nil
  end

  local today = GetScanDay()
  local total = 0
  local count = days

  for i = GetScanDay() - days + 1, today do
    if entry.l[tostring(i)] then
      total = total + entry.l[tostring(i)]
    elseif entry.h[i] then
      total = total + entry.h[tostring(i)]
    else
      count = count - 1
    end
  end

  if count ~= 0 then
    return math.floor(total / count)
  else
    return nil
  end
end


function Logistician.DatabaseMixin:GetRobustAveragePrice(dbKey, days)
  local entry = self.db[dbKey]

  days = math.max(1, math.floor(tonumber(days) or 21))

  if entry == nil then
    return nil, 0, 0
  end

  local samples = BuildRobustPriceSamples(entry, days)

  if #samples == 0 then
    return nil, 0, 0
  end

  -- With one observation there is nothing to robustly estimate.
  if #samples == 1 then
    return math.floor(math.exp(samples[1].logPrice) + 0.5), 1, 0
  end

  -- Two points cannot identify an outlier reliably; use the exponentially
  -- weighted log-price average.
  if #samples == 2 then
    local center = CombinedLocation(samples, function()
      return 1
    end)

    return math.floor(math.exp(center) + 0.5), 2, 0
  end

  local center = WeightedMedian(samples, function(sample)
    return sample.logPrice
  end)

  center = HuberWarmStart(samples, center)
  local rejected
  center, rejected = TukeyRefinement(samples, center)

  return math.floor(math.exp(center) + 0.5), #samples, rejected
end


function Logistician.DatabaseMixin:GetSaleLikelihood(dbKey, days)
  local entry = self.db[dbKey]

  days = math.max(3, math.floor(tonumber(days) or 21))

  if entry == nil then
    return nil
  end

  -- Requesting this score opts the item into compact high-resolution exposure
  -- tracking for future AH scans.
  self:WatchSaleExposure(dbKey)

  local samples = BuildSellabilitySamples(entry, days)

  if #samples == 0 then
    return nil
  end

  local robustAverage =
    self:GetRobustAveragePrice(dbKey, days)

  local currentPrice = entry.m
  local marketSnapshot = self:GetMarketSnapshot(dbKey)
  local currentMarketPrice =
    marketSnapshot and marketSnapshot.marketPrice or currentPrice

  -- Blend the exact floor with the 10%-depth price in log space. This keeps a
  -- genuinely cheap market attractive while preventing a single one-unit
  -- undercut from making the whole item's sale score look unrealistically
  -- strong.
  local representativeCurrentPrice = currentPrice
  if currentPrice and currentPrice > 0
      and currentMarketPrice and currentMarketPrice > 0 then
    representativeCurrentPrice = math.exp(
      (math.log(currentPrice) + math.log(currentMarketPrice)) / 2
    )
  end

  local priceScore =
    PriceAttractiveness(representativeCurrentPrice, robustAverage)

  local medianAvailable, availableSampleCount =
    AvailabilityMedian(samples)

  local latestAvailable =
    LatestAvailability(samples)

  local supplyScore =
    RelativeSupplyScore(latestAvailable, medianAvailable)

  local stabilityScore, priceMAD =
    PriceStability(samples)

  -- Old daily stock changes remain useful as a weak fallback, but are now
  -- deliberately de-emphasized because they cannot separate sales from expiry.
  local dailyDepletionScore, dailyMovementEvidence,
    dailyInformativeIntervals =
      StockDepletionPosterior(samples)

  local expiryTurnoverScore, expiryEvidence,
    expiryIntervals, expiryCensoredFraction,
    exposureObservationCount =
      GetExpiryAwareTurnover(entry, days)

  local expiryReliability =
    1 - math.exp(-expiryEvidence / 2)

  local depletionScore

  if expiryIntervals > 0 then
    -- Expiry-aware observations dominate as evidence accumulates.
    -- Remaining ambiguity (notably seller cancellations) keeps the daily
    -- fallback only as a small supporting signal.
    depletionScore =
      0.5
      + expiryReliability * (expiryTurnoverScore - 0.5)
      + (1 - expiryReliability)
        * 0.20
        * (dailyDepletionScore - 0.5)
  else
    -- Before the item has enough watched scans, do not pretend daily stock
    -- changes are a reliable sale-through measurement.
    depletionScore =
      0.5 + 0.20 * (dailyDepletionScore - 0.5)
  end

  depletionScore = Clamp01(depletionScore)

  local latestAge = samples[#samples] and samples[#samples].age or nil
  local recencyScore = RecencyScore(latestAge)

  -- Expiry-aware turnover and price competitiveness are the strongest
  -- components. Supply/stability/recency refine the marketability estimate.
  local rawScore =
      0.30 * depletionScore
    + 0.30 * priceScore
    + 0.15 * supplyScore
    + 0.10 * stabilityScore
    + 0.15 * recencyScore

  local priceEvidence = math.min(1, #samples / 10)
  local availabilityEvidence = math.min(1, availableSampleCount / 8)
  local expiryEvidenceScore =
    1 - math.exp(-expiryEvidence / 2.5)

  -- Confidence now depends strongly on actual expiration-aware exposure data.
  -- Old daily history alone can no longer generate "High confidence".
  local confidence =
      0.25 * priceEvidence
    + 0.15 * availabilityEvidence
    + 0.45 * expiryEvidenceScore
    + 0.15 * recencyScore

  confidence = Clamp01(
    confidence * (0.60 + 0.40 * recencyScore)
  )

  if expiryIntervals == 0 then
    confidence = math.min(confidence, 0.35)
  elseif expiryIntervals < 3 then
    confidence = math.min(confidence, 0.55)
  end

  -- Conservative evidence shrinkage toward neutral.
  local shrunkScore = 0.5 + confidence * (rawScore - 0.5)
  local score = math.floor(Clamp01(shrunkScore) * 100 + 0.5)

  return score,
    SellabilityLabel(score),
    SellabilityConfidenceLabel(confidence),
    {
      confidence = confidence,
      days = days,
      priceSamples = #samples,
      availabilitySamples = availableSampleCount,

      -- Legacy daily evidence (fallback only)
      informativeIntervals = dailyInformativeIntervals,
      movementEvidence = dailyMovementEvidence,
      dailyDepletionScore = dailyDepletionScore,

      -- New expiration-aware evidence
      expiryAware = true,
      expiryTurnoverScore = expiryTurnoverScore,
      expiryEvidence = expiryEvidence,
      expiryIntervals = expiryIntervals,
      expiryCensoredFraction = expiryCensoredFraction,
      exposureObservationCount = exposureObservationCount,

      currentPrice = currentPrice,
      currentMarketPrice = currentMarketPrice,
      representativeCurrentPrice = representativeCurrentPrice,
      marketSnapshot = marketSnapshot,
      robustAverage = robustAverage,
      latestAvailable = latestAvailable,
      medianAvailable = medianAvailable,
      depletionScore = depletionScore,
      priceScore = priceScore,
      supplyScore = supplyScore,
      stabilityScore = stabilityScore,
      recencyScore = recencyScore,
      priceMAD = priceMAD,
    }
end
