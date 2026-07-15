# Tokërrgjik — Store Listing Copy

Ready-to-paste text for Google Play Console and Apple App Store Connect.
Two languages: **Albanian (sq-AL)** as the primary/default, **English (en-US)** as a secondary.

- **App name:** Tokërrgjik
- **Package / Bundle ID:** `com.ejupishaban.tokerrgjik`
- **Category:** Games › Board
- **Content rating target:** Everyone / 3+ (contains ads + optional in-app purchases)
- **Price:** Free (with ads + in-app purchases: "Tokërrgjik PRO" subscription and coin packs)

---

## Google Play

### Albanian (default)
- **Title** (max 30): `Tokërrgjik — Loja Tradicionale`
- **Short description** (max 80):
  `Loja klasike shqiptare e strategjisë me guralecë. Luaj kundër mikut ose kompjuterit.`
- **Full description** (max 4000):

```
Tokërrgjik është loja tradicionale shqiptare e strategjisë — e njëjta lojë që brezat e kanë
luajtur me guralecë mbi tokë, tani në telefonin tuaj.

Vendos gurët, formo rreshtin, dhe merr gurët e kundërshtarit. E thjeshtë për ta mësuar,
e vështirë për ta zotëruar.

VEÇORITË
• Luaj kundër kompjuterit në nivele të ndryshme vështirësie
• Lojë online me shokë — dhoma private ose ndeshje të rastësishme
• Lojë në të njëjtën pajisje (dy lojtarë, një telefon)
• Ndjek statistikat, fito arritje dhe mblidh monedha
• Personalizo pamjen e tabelës
• Në shqip, e ndërtuar për lojtarët shqiptarë

Shkarko falas dhe luaj menjëherë. Tokërrgjik PRO heq reklamat dhe shton veçori shtesë.
```

### English
- **Title** (max 30): `Tokërrgjik — Albanian Strategy`
- **Short description** (max 80):
  `The classic Albanian strategy game of stones. Play a friend or the computer.`
- **Full description** (max 4000):

```
Tokërrgjik is the traditional Albanian strategy game — the same game generations have played
with pebbles on the ground, now on your phone.

Place your pieces, form a line, and capture your opponent's stones. Easy to learn, hard to master.

FEATURES
• Play against the computer at several difficulty levels
• Online multiplayer with friends — private rooms or random matches
• Pass-and-play on one device (two players, one phone)
• Track your stats, earn achievements, and collect coins
• Customise the look of the board
• In Albanian, built for Albanian players

Download free and play right away. Tokërrgjik PRO removes ads and adds extra features.
```

---

## Apple App Store

- **Name** (max 30): `Tokërrgjik`
- **Subtitle** (max 30): `Loja tradicionale shqiptare`
- **Promotional text** (max 170):
  `Loja klasike shqiptare e strategjisë me guralecë — luaj online me shokë ose kundër kompjuterit. Falas.`
- **Description:** reuse the Play "Full description" above (Apple has no strict 80-char short field).
- **Keywords** (max 100, comma-separated):
  `tokerrgjik,loje,shqip,strategji,tabelë,guralecë,mill,morris,board,albanian,puzzle,klasike`
- **Support URL:** `https://tokerrgjik.shabanejupi.tech`
- **Marketing URL** (optional): `https://tokerrgjik.shabanejupi.tech`

---

## Privacy / Data Safety answers

Use these for the **Play Data Safety form** and the **App Store App Privacy** questionnaire.
They match `store/privacy-policy.html`.

| Question | Answer |
|---|---|
| Collects data? | Yes |
| Email address | Collected (account) — linked to identity, not shared, not for tracking |
| Name / username | Collected (account) — linked to identity |
| App activity (game stats) | Collected — app functionality |
| Device / advertising ID | Collected — **used for advertising** (AdMob) → mark "Used for tracking" on Apple |
| Crash logs / diagnostics | Collected (Sentry) — app functionality |
| Approximate location | Only what AdMob infers from IP; declare if AdMob is enabled |
| Payment info | **Not collected by the app** — handled by PayPal/store billing |
| Data encrypted in transit | Yes (HTTPS/WSS) |
| Users can request deletion | Yes → privacy@shabanejupi.tech |

**Privacy Policy URL (required by both stores):**
`https://tokerrgjik.shabanejupi.tech/privacy-policy.html`

---

## Asset checklist (you must produce these images)

Source icon: `tokerrgjik_mobile/assets/icon.png` is **1024×1024 RGBA** — a good master.

Google Play requires:
- App icon 512×512 PNG → downscale the master (`convert icon.png -resize 512x512 play-icon.png`)
- Feature graphic 1024×500 PNG
- At least 2 phone screenshots (16:9 or 9:16), up to 8

Apple requires:
- App icon 1024×1024 PNG **with no alpha channel** → flatten the master
  (`convert icon.png -background white -alpha remove -alpha off apple-icon.png`)
- Screenshots for 6.7" and 6.5" iPhone (and iPad if you enable iPad)

> Screenshots can be captured from the running app on a device/emulator, or from the web build
> at https://tokerrgjik.shabanejupi.tech framed in a phone mockup.
