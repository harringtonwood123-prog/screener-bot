# Monetization

Two revenue channels are scaffolded. **Neither is active.** As shipped the app
makes no ad calls, has no tracking SDK, collects no identifiers and triggers no
App Tracking Transparency prompt. This document is what you'd do to turn each on.

---

## 1. Affiliate product suggestions (the better one)

**Where:** the *Add to Closet* tab, and the card under each outfit.

**Why it should work:** the suggestions aren't a product feed. `WardrobeGaps.analyse`
runs the real recommender against the user's real wardrobe and finds what's
actually missing:

- an occasion the wardrobe can't dress for at all
- an occasion it *can* dress for, but only just — and which slot is dragging it down
- no water-resistant layer, in a climate that has rain
- no warm layer
- a wardrobe of nothing but loud colours, which is hard to combine

Each gap arrives with a plain-English reason, and that reason is displayed next
to the product. "You've got no bottoms that work for formal" is a much better
reason to buy trousers than a banner.

### Turning it on

1. **Join a network.** Rakuten Advertising, Awin, Skimlinks, or Amazon Associates.
   Apparel brands are well covered by all four.
2. **Replace `PartnerCatalog.sample`** in `Closet/Monetization/PartnerCatalog.swift`
   with a real feed. The current entries use real brand names but invented
   products, prices and plain homepage URLs with no tracking — nothing there
   earns anything.
3. **Keep `products(for:)`.** The kind-then-slot matching is what makes a
   placement relevant. That relevance is the whole value.
4. **Keep the `isSponsored` disclosure.** It's already rendered as a "Sponsored"
   badge. This is not optional — see Compliance below.

### Worth doing before you scale it

Cache the feed rather than fetching per view, and rank by whether the product's
colour actually works with what the user owns — you already have `ColorTheory`
for that. "This jacket goes with six things you own" is a strong line.

---

## 2. Banner ads (the easier one)

**Where:** `AdSlotView`, currently an inert labelled box, shown under an outfit
result and at the bottom of Add to Closet.

The slot already reserves the standard 320×50 so nothing shifts when a real
banner drops in. Replace the body of `AdSlotView` with your ad view (Google
AdMob via `GoogleMobileAds`, or AppLovin) and you're done.

### Before you do

- **Adding an ad SDK changes your privacy posture.** You'll need to fill in
  Privacy Nutrition Labels, add a `PrivacyInfo.xcprivacy` manifest, and show
  an App Tracking Transparency prompt if the SDK tracks across apps. None of
  that applies today, which is worth keeping in mind.
- **Two placements is the ceiling.** The app's pitch is that it saves you time.
  Ads in the decision flow undercut that.
- **Consider paid-remove-ads instead.** A one-off StoreKit purchase that hides
  `AdSlotView` is cleaner than a subscription and easier to justify.

---

## Which to lead with

Affiliate. Banner ads on a small user base earn very little and cost you the
clean privacy story. The gap analysis is genuinely useful to the user and pays
much better per user. Get the affiliate feed working first and treat ads as a
later, optional layer.

---

## Compliance

Don't skip this:

- **Disclose paid placement.** The FTC requires it and App Store review looks
  for it. `isSponsored` already drives a visible badge — keep it.
- **Privacy Nutrition Labels** must match reality. Today the app collects
  nothing and sends nothing anywhere except the Open-Meteo request; if that
  changes, the labels must change with it.
- **Kids category:** don't, if you run ads. The rules are much stricter.
- **Location** is used only to fetch weather and is never stored or transmitted
  anywhere else. If that changes, update the usage description string, which is
  set in the target's build settings.
