Wider Professions Enhanced — TBC Anniversary 2.5.6

This is a self-contained build using:
- Wider Professions 1.11.4 (user-provided files)
- WiderProfessionsPlus 0.1.3
- Interface 20506
- Auctionator pricing API (optional)

IMPORTANT INSTALL
1. Fully exit WoW.
2. Delete BOTH old folders:
     Interface\AddOns\WiderProfessions
     Interface\AddOns\WiderProfessionsPlus
3. Extract this ZIP into Interface\AddOns\
4. You should have ONE folder only:
     Interface\AddOns\WiderProfessions\
5. Start WoW.

Do not update Wider Professions through CurseForge while testing this self-contained
build, because an updater may overwrite the embedded WiderProfessionsPlus.lua.

Diagnostic:
  /wpp status

Expected after login:
  self-contained build loaded: true; frame: true; ...

After opening a profession, profession UI should also be true.


WPP 0.1.4 UI refinement
-----------------------
- Moves the WPP launcher to the top-right of the recipe pane.
- Adds a classic framed square-button treatment to the launcher.
- Shopping rows now use separate Qty and Cost columns.
- Removes estimated total queue time.
- Adds a live Blizzard-style crafting progress bar driven by actual spellcast
  timing/events while processing a queued recipe.


WPP 0.1.5 cross-profession reagent navigation
----------------------------------------------
- Left-clicking a reagent still jumps directly to a recipe in the current
  profession when possible.
- WPP now caches output-item -> profession associations whenever you open a
  profession, and remembers them per character.
- If a clicked reagent belongs to another cached profession, WPP opens that
  profession and selects the reagent's recipe automatically.
- Common Mining/Smelting bars are pre-seeded, so Engineering reagents such as
  Iron Bar can jump straight to Mining/Smelting without requiring a prior
  cache pass.
- Shift-click/chat-link behavior remains unchanged.

WPP 0.1.6 visual integration
-----------------------------
- Requires value is now one line below the "Requires:" label.
- Shopping Qty/Cost headers and values use matching fixed columns.
- Item name column is narrowed to prevent overlap.
- Batch progress uses Blizzard Classic UI-CastingBar-Border,
  UI-CastingBar-Spark, and UI-StatusBar artwork.
- Cross-profession reagent navigation remains unchanged.


WPP 0.1.7 recipe-pane control rail
----------------------------------
- Creates a dedicated right-side control rail:
      WPP
      Favorite
      Info
- Recipe descriptions reserve that rail and wrap before the buttons.
- Requirement text reserves the same rail.
- Favorite button is slightly smaller (24px) to match the compact vanilla
  utility-button treatment.
- No queue, shopping, pricing, navigation, or progress behavior changed.


WPP 0.1.8 compact recipe pricing footer
----------------------------------------
- Fixes Auctionator's native two-line "To Craft / Profit" frame overlapping
  the third reagent row on recipes with many materials.
- Hides that large Auctionator frame and renders the same pricing as one compact
  line:
      Cost: ...  •  Profit: ...
- Positive profit is green; negative profit is red.
- Footer is hidden on recipes with more than 6 reagents rather than ever
  covering a fourth reagent row.
- Auctionator remains the pricing source.
- All WPP 0.1.7 layout/navigation/queue/shopping behavior is preserved.


WPP 0.1.9 recipe-pane cleanup
------------------------------
- Fixes the 0.1.8 Cost/Profit footer overlap completely:
  Cost/Profit now renders right-aligned on the same line as "Reagents:".
- The price line no longer depends on reagent count and cannot cover recipe
  materials or Create controls.
- Removes the visible Information button.
- WPP and Favorite now sit side-by-side in the top-right.
- Restores nearly the full vanilla description width.
- Requirement text also regains nearly the full width.
- Slightly narrows only the recipe-name field to protect the two top-right
  utility buttons.
- Queue, Shopping, Auctionator pricing, cross-profession reagent navigation,
  and Classic-style progress bar are unchanged.


WPP 0.1.10 Craft All
--------------------
- Adds a separate Craft All button beside Craft Next.
- Craft Next still processes only the first queued recipe batch.
- Craft All processes the queue strictly from top to bottom.
- After one recipe finishes, the next queued recipe starts automatically.
- Craft All stops at the first recipe that cannot currently be crafted, leaving
  that recipe and all later entries intact.
- During Craft All, the Classic-style progress bar represents the whole queue
  rather than resetting for each recipe.
- Queue editing / clearing / Add Selected are disabled while queue processing
  is active so the progress total cannot become inconsistent.
- A short 0.15s handoff delay is used between recipes so newly crafted
  intermediate reagents have time to appear in bags before the next recipe is
  evaluated.

WPP 0.1.11 shared cross-profession queue + drag reorder
--------------------------------------------------------
- Replaces profession-specific queues with one shared per-character queue.
- Existing 0.1.10 profession queues are migrated into the shared queue once.
- Every queue row stores and displays its owning profession.
- Mining/Smelting is normalized and shown as Mining.
- Click a queue row from another profession to open that profession and select
  the recipe.
- Craft All processes the shared queue strictly top-to-bottom.
- At a profession boundary Craft All PAUSES and its button becomes:
      Open Mining / Open Engineering / ...
  Opening a profession is a protected WoW action and requires that user click.
  Once the correct profession is open, the button becomes "Continue All".
- Whole-queue progress is preserved across profession boundaries.
- Every visible queue row can be dragged onto another visible row to reorder.
- Queue editing is disabled while Craft All / Craft Next is processing.
- Shopping now reads recipe snapshots cached from every opened profession and
  simulates queue output in order, so materials produced by an earlier Mining
  row can be consumed by a later Engineering row.

WPP 0.1.12 Add Selected integration
------------------------------------
- Removes Add Selected from the WPP Queue/Shopping window.
- Adds a native-style Add Selected button beside Blizzard's Create All / Create
  controls in the profession window.
- The button uses the current Blizzard quantity input, exactly like previous
  queue-add behavior.
- Clicking Add Selected:
      1. adds the current recipe + quantity to the shared queue;
      2. opens Wider Professions+ if closed;
      3. switches directly to the Queue tab.
- The button is disabled while Craft Next / Craft All is actively processing.
- Queue and Shopping tabs now have a little more room in the WPP panel.

WPP 0.1.13 Add Selected replaces Create All
--------------------------------------------
- Removes/hides Blizzard's native Create All button.
- Add Selected now occupies Create All's exact original position and size.
- Bottom crafting controls are therefore:
      Add Selected | quantity | Create
- Add Selected still uses the current quantity, adds to the shared queue,
  opens Wider Professions+, and switches to the Queue tab.
- Blizzard/Wider Professions attempts to re-show Create All are suppressed.
- Shared cross-profession queue, Craft All queue processing, drag/drop
  reordering, Shopping, and Auctionator pricing are unchanged.

WPP 0.1.14 Add Selected hotfix
-------------------------------
- Fixes Lua error when Add Selected opens the Queue:
    RefreshPanel -> attempt to call nil value
  Cause: UpdateQueueAddButton was declared after RefreshPanel without a Lua
  forward declaration, so the earlier function resolved it as a nil global.
- Adds an explicit local forward declaration and assigns the helper into that
  local scope.
- Widens Add Selected to 118px.
- Keeps the exact native Create All RIGHT edge, so the larger button grows
  leftward and does not shift/overlap the quantity controls.
- All shared-queue, Craft All, cross-profession, Shopping, drag/drop, and
  Auctionator behavior remains unchanged.

WPP 0.1.15 button label cleanup
--------------------------------
- Renames native crafting button from "Add Selected" to simply "Add".
- Keeps identical behavior: current recipe + quantity are added to the shared
  queue and the Queue panel opens automatically.
- Narrows the button to 82px while preserving the same right edge/spacing.

WPP 0.1.16 profession-switch hotfix
------------------------------------
- Fixes "Could not open Engineering" after a Mining batch.
- Root cause: WPP checked IsSpellKnown() against Engineering's original/base
  profession spell ID. Higher profession ranks may not report that old rank ID
  as known even though Engineering is present and usable in the spellbook.
- Profession opening no longer relies on a base-rank spell ID.
- WPP searches the live player spellbook for the opener by localized name and
  casts that actual slot.
- Falls back to CastSpellByName from the user's button click.
- Failure messages now include the resolved opener name for easier debugging.
- Shared queue, cross-profession Craft All progress, drag/drop, Shopping,
  Auctionator pricing, and Add button behavior are unchanged.

WPP 0.1.17 queue footer cleanup
--------------------------------
- Removes the visible Craft Next button.
- Craft All is now the only queue-processing button.
- Craft All expands to 150px.
- Clear sits directly to its left and expands to 70px.
- Profession-boundary behavior is unchanged:
      Open <Profession>
      Continue All
- Whole-queue progress, shared cross-profession queue, drag/drop ordering,
  Shopping, Auctionator pricing, and native Add button are unchanged.

WPP 0.1.18 net Shopping planner
--------------------------------
- Shopping now shows only the NET materials still needed.
- Subtracts items currently owned before adding anything to Shopping.
- Uses GetItemCount(itemID, true), so known bank inventory is included where
  the Classic client exposes it.
- Recursively expands craftable intermediate items through recipes cached from
  any profession WPP has opened on the character.
- Owned materials are subtracted inside those cross-profession sub-crafts too.
- Earlier shared-queue outputs are available to later queue entries.
- Multi-output sub-craft surplus is retained in virtual stock and reused later.
- Only the final unresolved acquisition shortage appears in Shopping.

WPP 0.1.19 automatic prerequisite queue expansion
--------------------------------------------------
- Clicking Add now inserts necessary craftable prerequisite recipes BEFORE the
  selected final recipe.
- Expansion is recursive across every profession WPP has cached.
- Example:
      Smelt Copper
      Smelt Tin
      Smelt Bronze
      Whirring Bronze Gizmo
      Final Engineering recipe
- Prerequisite quantities account for:
      * items already owned (including known bank stock);
      * unused output projected from existing earlier queue rows;
      * recipe output yields;
      * surplus from multi-output prerequisite crafts.
- Raw materials / recipes the character does not know are not inserted as
  fake crafts; they remain acquisition needs in Shopping.
- Automatically inserted rows remain normal shared-queue rows and can still be
  dragged/reordered by the user.
- Shared Craft All, profession-boundary switching, Shopping net-material
  calculation, Auctionator pricing, and Add button behavior are preserved.

WPP 0.1.20 Auctionator integration baseline + ! folder
-------------------------------------------------------
- Custom addon folder is now:
      Interface\AddOns\!WiderProfessions\
- The matching TOC is now:
      !WiderProfessions.toc
- Addon title also begins with ! so it sorts at/near the top of the AddOns UI.
- ADDON_LOADED handling is dynamic, so the leading ! folder name is supported
  without breaking Wider Professions initialization.
- Auctionator v334 (the user's supplied build, TBC Anniversary 20506 compatible)
  is included alongside WPP in this combined development package as the normal:
      Interface\AddOns\Auctionator\
- Auctionator itself is not renamed because its assets use the Auctionator
  folder path.
- Adds AuctionatorBridge.lua, a central compatibility layer based on
  Auctionator.API.v1.
- Existing Cost/Profit pricing now reads through the bridge.
- Bridge foundations are available for future WPP features:
      * auction price by item ID/link;
      * price age;
      * exact-price status;
      * vendor value;
      * disenchant value;
      * create/read Auctionator Shopping Lists;
      * convert WPP Shopping rows to Auctionator advanced search terms;
      * launch Auctionator MultiSearchAdvanced while the AH is open.
- No Auctionator UI behavior has been changed yet; 0.1.20 establishes the
  shared integration foundation for later interactive features.

WPP 0.1.21 !Auctionator folder integration
-------------------------------------------
- Auctionator folder is now:
      Interface\AddOns\!Auctionator\
- Matching TOC is:
      !Auctionator.toc
- Auctionator title also starts with !.
- Patched Auctionator's ADDON_LOADED name check for !Auctionator.
- Patched Auctionator version metadata lookups for !Auctionator.
- Patched all hardcoded Interface\AddOns\Auctionator\ asset paths to
  Interface\AddOns\!Auctionator\ so icons/textures still load.
- WPP OptionalDeps now targets !Auctionator.
- WPP AuctionatorBridge version lookup now targets !Auctionator.
- Auctionator public globals/API remain Auctionator / Auctionator.API.v1;
  future WPP integration code should continue using those public API globals.

WPP 0.1.22 / !Auctionator robust historical average
-----------------------------------------------------
- Auctionator tooltip keeps:
      Auction    = latest stored scan price
- Adds:
      Avg 21d    = robust historical market average
- The new average uses Auctionator's own stored daily scan history.
- Model:
      * daily low/high minimum-price observations are combined as a
        geometric midpoint in log-price space;
      * newer days receive exponentially decaying weights;
      * Huber M-estimation provides a bounded-influence adaptive warm start;
      * Tukey biweight refinement gives severe isolated outliers zero final
        influence;
      * weighted MAD supplies the robust scale.
- The existing 21-day Auctionator history window/config is reused.
- Adds Auctionator.API.v1.GetAuctionAverageByItemID / ByItemLink.
- WPP's AuctionatorBridge exposes the new robust average API for future
  crafting-cost, shopping, buying, and pricing features.
- Existing WPP Cost/Profit still uses the latest Auctionator price for now;
  this release only adds the historical average and API foundation.

WPP 0.1.23 / !Auctionator Sale Likelihood model
------------------------------------------------
- Item tooltips now add:
      Sale likelihood   High · 71/100
      Model confidence  Medium · 12d history
- The score uses ONLY data already stored by Auctionator.
- It is intentionally a 0-100 marketability score, NOT a claimed calibrated
  probability of completed sale, because Auctionator does not observe verified
  outcomes for every listing.
- Signals:
      * Bayesian Beta-shrunk directional stock depletion from daily quantity;
      * latest price versus robust historical average;
      * latest supply versus the item's own historical median supply;
      * robust weighted-MAD price stability in log-price space;
      * scan recency.
- Static daily stock is treated as uninformative instead of automatically
  meaning "no demand".
- Sparse history shrinks the result toward neutral 50.
- Adds public Auctionator API:
      GetSaleLikelihoodByItemID
      GetSaleLikelihoodByItemLink
- WPP AuctionatorBridge exposes the same methods for future crafting,
  shopping, profitability, and deal-selection features.

WPP 0.1.24 / !Auctionator expiration-aware Sale Likelihood
------------------------------------------------------------
- Fixes the largest limitation in 0.1.23: market inventory disappearance is
  no longer automatically treated as sale-like without accounting for auction
  expiration.
- TBC legacy AH time-left bands are captured on Auctionator scans:
      <30m
      30m-2h
      2h-12h
      12h-48h
- Sellers may choose 12 / 24 / 48 hour auctions. The Blizzard scan API does
  not expose another seller's original duration, but current remaining-time
  bands let the model estimate whether natural expiration was possible before
  the next observation.
- Expected natural expiration is treated as CENSORED exposure rather than a
  completed sale or a failure to sell.
- Disappearance from inventory expected to still be alive becomes conservative
  "sale-like depletion". Cancellation remains an unavoidable ambiguity.
- New/relisted supply reduces interval reliability rather than being counted as
  proof of poor demand.
- Large price regime shifts also reduce the comparability of adjacent scans.
- Uses a Beta(2,2)-shrunk interval turnover estimator, bounded per-interval
  evidence, exponential recency weighting and exposure saturation.
- Detailed exposure observations are stored ONLY for recently inspected items,
  preventing a full AH scan from creating an enormous SavedVariables file.
- Exposure history is adaptively thinned:
      recent 24h: high resolution
      1-3 days: ~2h spacing
      3-14 days: ~6h spacing
- Sale Likelihood confidence now depends strongly on expiration-aware exposure.
  Before enough new scans are collected, the tooltip explicitly says:
      "learning expiry data"
- Old daily quantity changes remain only a weak fallback.
- Adds API/bridge access to compact sale-exposure history for future features.
