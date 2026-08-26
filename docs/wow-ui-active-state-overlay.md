> **Portable reference** for any AI agent, LLM, or developer working on a
> WoW addon UI (this file is self-contained - no need to read the rest of
> this repo's history to use it). It documents a hard-won technique for
> giving a plain `UIPanelButtonTemplate` Button a persistent "active/enabled"
> visual state, in a client where the usual native approaches silently fail.

## Problem

You have a toggle-style `Button` (created via `CreateFrame("Button", ..., "UIPanelButtonTemplate")`,
or similar) and want it to visually look different when some boolean state is
"on" (e.g. `Enable Debug` / `Disable Debug`), beyond just changing its text.

The "obvious" approaches all fail on some clients/skins (confirmed on a
WoW Anniversary/Classic-era client, but the lesson generalizes - **always
verify visually in-game before trusting these APIs**):

| Approach tried | Result |
|---|---|
| `button:GetNormalTexture():SetVertexColor(...)` | `GetNormalTexture()` returned `nil` -> crash ("attempt to index a nil value") |
| `button:GetHighlightTexture():SetVertexColor(...)` | Also returned `nil` on this template |
| `button:GetPushedTexture()` (clone its shape/atlas into a new texture) | Also returned `nil` |
| `button:SetButtonState("PUSHED", true)` (lock the native pushed render) | No crash, but **no visible difference at all** - this skin renders Normal/Highlight/Pushed identically |
| Tinting the button's own named sub-regions (e.g. `button.Left` / `button.Middle` / `button.Right`, which some Classic-era `UIPanelButtonTemplate` skins expose instead of `NormalTexture`) | Only tinted the outer frame/border, not the interior fill (because the "fill" turned out to be a separate darker layer/gradient underneath, not part of those regions) |

**Root cause:** this particular button skin/template does not expose the
texture regions the standard `Button` widget API assumes exist, and its
Normal/Highlight/Pushed states are visually identical. There is nothing
native to hook into - the only thing that reliably renders anything is a
texture *you* create and fully control.

## Solution: draw your own overlay texture

Create your own `Texture` object as a child of the button, sized with a
**small positive inward inset** (never a negative/outward one), and just
show/hide it based on your state. Do not try to clone/anchor to any native
texture region (`GetHighlightTexture()`, `GetPushedTexture()`, etc.) - those
regions can be sized to deliberately bleed *outside* the button's own
bounds (e.g. highlight glow effects), which causes ugly overflow past the
button's rounded corners if you copy their anchors.

```lua
local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
button:SetSize(220, 32)
-- ... anchor, OnClick, etc ...

-- Manually-drawn "active" overlay. Inset a few px so it can never poke out
-- past the button's own (often slightly rounded) corners - a rectangle
-- anchored purely with positive inward offsets mathematically cannot
-- exceed the parent's bounds, unlike cloning an external region's anchors.
local activeFill = button:CreateTexture(nil, "ARTWORK")
activeFill:SetTexture("Interface\\Buttons\\WHITE8x8") -- flat white 8x8 pixel, a
                                                       -- standard, always-
                                                       -- available texture
                                                       -- used throughout WoW
                                                       -- addons for solid-
                                                       -- color fills
activeFill:SetPoint("TOPLEFT", 4, -4)
activeFill:SetPoint("BOTTOMRIGHT", -4, 4)
activeFill:SetVertexColor(0, 0, 0) -- black; combined with alpha below this
                                    -- reads as a "pressed in"/darkened look
                                    -- instead of an odd/unrelated color
activeFill:SetAlpha(0.45)
activeFill:Hide()

local function RefreshButtonState()
  local isOn = GetYourBooleanStateSomehow()
  button:SetText(isOn and "Disable X" or "Enable X")
  activeFill:SetShown(isOn)
end
RefreshButtonState()
```

### Why these specific numbers

- **4px inset**: small enough to still look like it's covering "the whole
  button", large enough to clear this skin's corner rounding without any
  native color peeking through at the corners. If your button has a
  noticeably larger corner radius, increase the inset a little - just keep
  it a small positive number, never 0 (0 reintroduces the corner-overflow
  problem) and never so large it looks like a shrunken box floating inside
  the button.
- **Black at ~0.35-0.5 alpha**: reads as "this button is pressed/active"
  on almost any button color scheme, since it's just a darkening wash
  rather than a specific hue. If you want a colored tint instead (e.g.
  green for "on"), swap `SetVertexColor(0, 0, 0)` for your color and adjust
  alpha - but be aware brightly-colored overlays can look "off"/mismatched
  against the button's own art style (this was tried - green, then blue -
  and rejected as looking bad before settling on a plain darkening wash).
- **`Interface\Buttons\WHITE8x8`**: a genuinely flat, pure-white 1-color
  texture. Do NOT reuse a native button texture region for the fill color
  source (e.g. `GetNormalTexture():GetTexture()`) - on some skins that
  texture has its own baked-in gradient/lighting, which combined with your
  tint can look like an ugly uneven "blob" instead of a flat wash.

## Generalizing this into a reusable helper

If you need this in more than one place, wrap it:

```lua
-- Attaches a persistent darkened "active" overlay to `button`, shown/hidden
-- via SetActiveOverlayShown(bool). Safe to call once per button.
local function AddActiveOverlay(button, inset, r, g, b, alpha)
  inset = inset or 4
  local overlay = button:CreateTexture(nil, "ARTWORK")
  overlay:SetTexture("Interface\\Buttons\\WHITE8x8")
  overlay:SetPoint("TOPLEFT", inset, -inset)
  overlay:SetPoint("BOTTOMRIGHT", -inset, inset)
  overlay:SetVertexColor(r or 0, g or 0, b or 0)
  overlay:SetAlpha(alpha or 0.45)
  overlay:Hide()
  return overlay
end

-- Usage:
local activeFill = AddActiveOverlay(myButton)
myButton.SetActiveOverlayShown = function(self, shown) activeFill:SetShown(shown) end
```

## Debugging checklist if you hit this again

1. Does `button:GetNormalTexture()` / `GetHighlightTexture()` / `GetPushedTexture()`
   return non-`nil`? Print it. If `nil`, don't bother trying to tint/clone it.
2. If non-`nil`, try tinting it (`:SetVertexColor(...)`) and LOOK IN-GAME. Don't
   assume it worked just because there was no error - a wrong assumption
   about which region is "the fill" vs "the frame" can make a tint appear to
   do nothing, or only affect part of the button.
3. Try `button:SetButtonState("PUSHED", true)` and LOOK IN-GAME before
   building anything around it - some skins render every button state
   identically.
4. If nothing native produces a visible difference, stop guessing and use
   the manually-drawn overlay approach above - it is guaranteed to render
   something, since you fully control the texture, its anchors, and its
   color.
