# Closet

An iOS app that tells you what to wear.

You add your clothes once. After that you open the app, tap what you're doing —
**Casual**, **Business Casual**, **Formal**, **Gym**, **Running**, **Date Night** —
and it picks an outfit that suits the weather where you are and actually goes
together, and tells you *why*.

Native iOS. SwiftUI. No third-party dependencies, no backend, no account.

---

## Getting it running

You need a Mac with **Xcode 16 or later**.

```bash
git clone https://github.com/harringtonwood123-prog/screener-bot.git
cd screener-bot
open Closet.xcodeproj
```

Then pick a simulator (or your iPhone) and hit **Run**.

### First run

The app opens onto a four-step onboarding: welcome, sign-up, location
permission, then a choice of starting closet. **Sign-up is required** — name and
email, before anything else, as specified.

Worth knowing before you submit to review: App Store guideline 5.1.1(v) says an
app may not require an account for features that don't need one, and everything
here runs on-device with no server. A hard sign-up wall is a plausible rejection.
To make the step skippable, add a button to `SignUpStep` that calls
`store.signUp(name: "", email: "")`. To make it a *real* account you'd need a
backend — at which point Sign in with Apple becomes mandatory alongside any other
social login, and the privacy labels change, because today nothing leaves the
device.

Two things to know on first launch:

- **Weather needs location.** Allow it when asked. If you deny it, the app still
  works — it falls back to mild conditions and says so.
- **On the Simulator there's no camera.** The Scan button is hidden automatically;
  use **Choose** to pick a photo instead. Simulator location is also fixed unless
  you set one via *Features → Location → Custom Location*.

The app offers a sample closet on first launch so you can see it working
before photographing anything.

> If the project file ever gives you trouble, there's an [XcodeGen](https://github.com/yonaskolb/XcodeGen)
> definition as a fallback: `brew install xcodegen && xcodegen generate`.

## Look

`Closet/Design/Theme.swift` holds the whole visual language: a warm off-white
canvas in light and a deep indigo-black in dark, an indigo-to-violet brand
gradient echoing the icon, SF Rounded throughout, and semantic colour tokens
rather than raw system greys. Light and dark are declared as explicit pairs in
one file, so changing the palette means editing one place.

The mark — three overlapping discs — is the app's actual subject: how colours
sit against each other. It exists twice, as the 1024px icon and as `LogoMark`,
a drawn SwiftUI version that stays crisp at any size.

One thing the palette work caught: the Formal tile was a near-black slate, which
vanished against the dark-mode card. Every occasion tint is now contrast-checked
against both card backgrounds.

## How it decides

The recommendation isn't a lookup table. Every garment carries four numbers —
**warmth**, **formality**, **breathability**, and whether it sheds water — and
the engine scores combinations against the occasion and the forecast.

**1. Filter by occasion.** Each occasion has a formality band. A blazer scores 5,
a hoodie 1. Business casual wants 3–5, the gym wants 0–1. Gym and running
additionally require kit you'd actually train in, so a denim jacket never shows
up for a 5k.

**2. Score against the weather.** Your location goes to
[Open-Meteo](https://open-meteo.com) — no API key, no account, no billing. The
*feels-like* temperature drops into a band (freezing → hot), each band has a
target warmth, and outfits are penalised for missing it. Sport targets a lower
number than the thermometer suggests, because you generate your own heat:
dressing for a 12°C run means dressing like it's 20°C.

Rain above 40% pushes water-resistant pieces up and sandals down. Wind above
25 km/h rewards a layer that blocks it. Above a 35°C feels-like — an Austin
afternoon — it also says so, because no outfit makes that safe.

**Units.** Everything is stored and reasoned about in metric; `Units` converts
at the display layer only, so switching between °C and °F never changes a
recommendation. It follows your region by default (Fahrenheit and mph in the
US) and can be forced either way in Settings. An Austin user sees *"100° in
Austin · feels like 106°"*; the engine sees 37.8°C and 41.1°C.

**3. Score the colours.** Colours convert to hue/saturation/brightness, and each
pair is classified: two neutrals, a neutral anchoring a colour, analogous,
complementary, or discord. Navy, denim, khaki and olive count as neutrals,
because in practice that's how they behave.

One detail worth flagging: the classic "opposites" — red/green, blue/orange —
sit about 120–145° apart in HSB, *not* the 180° an artist's colour wheel
implies. The bands are set accordingly, so red and green read as deliberate
contrast rather than a near-miss.

**4. Explain it.** Every deduction carries a sentence, and those sentences are
the "Why this works" card. Not "87% match" — *"Navy is a neutral, which lets
the rust carry the outfit"* and *"70% chance of rain, and this outfit can take
it."*

It also tracks what you've worn, so the same shirt doesn't come up every day.

## Layout

```
Closet/
├── Models/        Garment, GarmentKind (the 40-item table), Occasion, Outfit, Weather
├── Core/          HSBColor, ColorTheory, OutfitEngine, WardrobeGaps
├── Services/      WeatherService (Open-Meteo), LocationProvider, GarmentScanner (Vision)
├── Store/         WardrobeStore (JSON persistence), ImageStore, SampleData
├── Design/        Theme (palette, metrics, type, surfaces)
├── Monetization/  PartnerCatalog
└── Views/         TodayView, OutfitResultView, ClosetView, AddGarmentView, ShopView
    └── Onboarding/  Welcome, SignUp, Location, starting wardrobe
```

`GarmentKind.swift` holds the domain knowledge: 40 garment types, each with its
warmth, formality, breathability and behaviour. Adding a garment type means
adding a case and filling in its numbers — the engine picks it up automatically.

## Scanning

Point the camera at an item and the app tries to work out what it is:

- **Background removal** via Vision's `VNGenerateForegroundInstanceMaskRequest`,
  so the colour sample isn't polluted by your carpet.
- **Colour extraction** by quantising into coarse HSB buckets and taking the
  most populated, skipping blown-out highlights and shadow.
- **Type classification** via `VNClassifyImageRequest`, mapped onto garment kinds.

All on-device. All best-effort — if Vision isn't confident it says nothing and
you pick from a list. Nothing in the flow blocks on a correct guess, and the
photo itself is optional.

## Making money from it

Two channels are scaffolded, both inert as shipped. See **[MONETIZATION.md](MONETIZATION.md)**.

The interesting one is the Add to Closet tab. It doesn't show a generic product
feed — it runs the recommender against your actual wardrobe, finds the gaps
("nothing you own sheds water", "your best business casual outfit is a stretch"),
and shows products against those. A relevant suggestion converts better than a
random one, and it's honest: the reason is shown next to the product.

## State of the code

Written in a Linux container with no Swift toolchain, so **none of it has been
compiled.** Expect to fix some compile errors on first build in Xcode — they'll
be syntax, not design.

The decision logic *was* tested, by porting it to Python and running it over a
realistic wardrobe. That caught six real bugs that would otherwise have shipped:

- `neutralAnchor` scored 1.00, the maximum, so any neutral-plus-colour pair beat
  every carefully composed outfit
- all-black, and a white tee with white sneakers, scored *worst* of everything
  tested — flagged as "flat" when both are classic looks
- red with green classified as `triadic` rather than complementary, because the
  HSB hue bands were set for an artist's wheel
- a denim jacket was recommended for a 5k run
- gym and running returned identical outfits despite one being indoors
- every hot-weather sport outfit warned "too warm", because the target warmth
  was below anything physically achievable

Those checks now live in the repo as a real test suite rather than as throwaway
Python. `ClosetTests/` has 58 tests, and each bug above has one named after it,
so none of them can come back quietly. Run them with Cmd-U, or:

```bash
xcodebuild test -scheme Closet -destination 'platform=iOS Simulator,name=iPhone 16'
```

The suite covers colour naming and harmony, the recommender across six
occasions and six temperature bands, unit conversion, gap analysis, sign-up
validation and the onboarding gate, and round-tripping the wardrobe to disk. It needs no network and no location: all
weather is constructed in-process.

Worth knowing: the tests were written without ever being run, same as the rest.
Their *assertions* were checked against a Python model of the engine, so the
expected values are right, but expect to fix compile errors in the test target
too. If it gets in your way, the `ClosetTests` target can be deleted from the
project without touching the app.

Not yet built: iCloud sync, outfit history, multi-day planning.
