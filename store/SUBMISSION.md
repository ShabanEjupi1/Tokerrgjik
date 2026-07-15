# Publishing Tokërrgjik to the app stores

State as of 2026-07-15. The app builds and, in CI, now produces a **release-signed** Android
App Bundle (AAB) ready to upload. Everything below the "What only you can do" line needs a
person with a card and an identity to sign in — it cannot be automated.

---

## The signing key — read this first

The Android upload key lives in `tokerrgjik_mobile/android/app/release.jks` (gitignored) and its
passwords in `tokerrgjik_mobile/android/key.properties` (also gitignored, and stored in
`credentials.local.txt`). The same key, base64-encoded, is a GitHub Actions secret
(`ANDROID_KEYSTORE_BASE64`) so CI can sign.

**If this key is ever lost, the app can never be updated on Google Play again** — a new key means
a new app listing. Back up `release.jks` + its passwords somewhere safe and offline. (Google Play
App Signing, enabled by default on first upload, protects the *distribution* key but you still need
this *upload* key for every future release.)

---

## Android — ready now, pending only the account

1. **Get the signed AAB.** Every push to `main` runs the *Build Android APK/AAB* job. Download the
   `android-aab-<sha>` artifact from the run — that `app-release.aab` is signed with the upload key.
   (Or tag a release: `git tag v1.0.0 && git push --tags` attaches the AAB + APKs to a GitHub Release.)
   Verify the signature locally if you like:
   `jarsigner -verify -verbose -certs app-release.aab` → should say "jar verified".
2. **Create a Google Play Developer account** — https://play.google.com/console — **$25 one-time**,
   needs a Google account + card + identity verification (can take a day or two to verify).
3. **Create the app** in the console: name *Tokërrgjik*, default language Albanian, free, Game › Board.
4. **Fill the listing** from `store/store-listing.md`. Upload the icon, feature graphic, screenshots
   (see the asset checklist there).
5. **Data safety form** — answer from the table in `store/store-listing.md`. Privacy Policy URL:
   `https://tokerrgjik.shabanejupi.tech/privacy-policy.html` (host it — see "Hosting the privacy
   policy" below).
6. **Content rating** questionnaire → will land at PEGI 3 / Everyone (declare ads + in-app purchases).
7. **Upload the AAB** to the Production (or Closed testing first) track, roll out, submit for review.

## iOS — blocked until you enrol

iOS cannot be finished yet, for a concrete reason: an App Store build must be **signed with an
Apple-issued distribution certificate + provisioning profile**, and those only exist once you pay
for the **Apple Developer Program ($99/year)**. CI has a macOS job, but today it builds
`--no-codesign` (an unsigned `.ipa` that the App Store rejects).

When you enrol, the path is:
1. Enrol at https://developer.apple.com/programme/ ($99/yr, identity verification).
2. In App Store Connect create the app with bundle id `com.ejupishaban.tokerrgjik`.
3. Provide signing to CI. Easiest is **fastlane match** (stores certs in a private git repo) or
   upload the `.p12` cert + `.mobileprovision` as GitHub secrets. Then the macOS job archives with
   `flutter build ipa --export-options-plist=...` and uploads with `xcrun altool`/`notarytool`.
   → Once you have the account, ping me and I'll wire the macOS job to sign with your certs.

No Mac is required if CI does the signing — but the **paid Apple account is a hard prerequisite**;
there is no free path to the App Store.

---

## Hosting the privacy policy

Both stores require a public privacy URL. `store/privacy-policy.html` is self-contained. Serve it at
`https://tokerrgjik.shabanejupi.tech/privacy-policy.html` — see `deploy/` (the nginx web container).
It can be dropped into the served web root the same way `deploy/downloads/` is mounted.

---

## What only you can do (the blockers)

| Blocker | Cost | Why it can't be automated |
|---|---|---|
| Google Play Developer account | $25 once | Identity + payment, Google login |
| Apple Developer Program | $99 / year | Identity + payment, Apple login; required before iOS can be signed at all |
| Store screenshots + feature graphic | — | Design assets; capture from the app |
| Final "Submit for review" | — | Legal declarations made under your account |

Everything else — a green build, a correctly signed AAB, listing text, privacy policy, data-safety
answers — is done or in this folder.
