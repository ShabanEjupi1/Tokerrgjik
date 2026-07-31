# Tokërrgjiku — Data safety te Play Console (përgjigjet, fjalë për fjalë)

Paketa `com.ejupishaban.tokerrgjik` · shkruar më 30 korrik 2026.

Etiketat e fushave janë lënë **në anglisht**, sepse ashtu duken te Console-i.
Përgjigjet janë nxjerrë nga kodi, jo nga kujtesa: endpoint-et që thërret
`tokerrgjik_mobile/lib/` (`/api/hyr`, `/api/emri`, `/api/dhoma`, `/api/rradha`,
`/api/loja/…`, `/api/tabela`, `/api/une`), `lib/app/ads.dart` (AdMob), dhe
`web/privatesia.html` (çfarë premton politika).

> 🚨 Rregulli që i mban të dyja të lidhura: **Play e krahason politikën e
> privatësisë me këtë deklaratë.** Nëse ndryshon njërën, ndrysho tjetrën në të
> njëjtën seancë. Kundërshtia mes tyre është nga shkaqet më të shpeshta të
> pezullimit.

---

## URL-ja e fshirjes — një e vetme, për të dyja

**https://tokerrgjik.shabanejupi.tech/fshi-te-dhenat.html**

Play **nuk** ka dy fusha të ndara për «fshirje llogarie» dhe «fshirje të
dhënash». Ka një fushë të vetme, `Delete data URL`, dhe faqja pas saj duhet të
lejojë **të dyja**: të kërkosh fshirjen e llogarisë *dhe* të shohësh çfarë
fshihet. Faqja e mësipërme i bën të dyja (rrugë brenda aplikacionit, email, plus
tabela «çfarë fshihet / çfarë mbetet»).

Politika kërkon veç kësaj një rrugë **brenda aplikacionit** — ajo është
`Luaj online → ⚙ → Fshi llogarinë`. Faqja vetëm nuk mjafton.

⚠️ Butoni brenda aplikacionit ekziston te kodi por ende **nuk ka hyrë në një
AAB të ngarkuar**. Derisa të ngarkohet një lëshim i ri, politika mbulohet vetëm
nga faqja.

---

## Hapi 2 — Data collection and security

| Pyetja | Përgjigjja |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** — çdo thirrje shkon me HTTPS/TLS; AdMob-i po ashtu (TLS) |
| Do you provide a way for users to request that their data is deleted? | **Yes** → `https://tokerrgjik.shabanejupi.tech/fshi-te-dhenat.html` |

### Account creation (po aty)

| Pyetja | Përgjigjja |
|---|---|
| Does your app allow users to create an account? | **Other** |
| Can users log in with accounts created outside the app? | **No** |
| Additional badges (independent security review, etj.) | **asnjëra** |

**Pse «Other» dhe jo «My app does not allow users to create an account»:**
`POST /api/hyr` kthen një token `Bearer`, kredencial i përhershëm i lidhur me një
emër lojtari. Pra ka llogari. Por nuk ka fjalëkalim dhe asnjë nga faktorët që
Play i rendit (2FA, OTP, biometrikë, SSO) — identiteti është një token që e mban
vetë pajisja. «Other» është e vetmja përgjigje e vërtetë.

---

## Hapi 3 — Data types (çfarë zgjidhet, dhe çfarë JO)

Pesë tipa gjithsej. Çdo gjë tjetër lihet bosh.

| Kategoria | Zgjidh |
|---|---|
| Location | ⛔ **asgjë** |
| Personal info | ✅ **Name** · ✅ **User IDs** |
| Financial info | ⛔ asgjë |
| Health and fitness | ⛔ asgjë |
| Messages | ⛔ asgjë |
| Photos and videos | ⛔ asgjë |
| Audio files | ⛔ asgjë |
| Files and docs | ⛔ asgjë |
| Calendar | ⛔ asgjë |
| Contacts | ⛔ asgjë |
| App activity | ✅ **App interactions** |
| Web browsing | ⛔ asgjë |
| App info and performance | ✅ **Diagnostics** |
| Device or other IDs | ✅ **Device or other IDs** |

### Pse pikërisht këto

- **Name** — emri i shfaqur që e shkruan vetë lojtari dhe i shkon serverit te
  `POST /api/hyr` / `/api/emri`. Play-i e quan «Name» edhe një nofkë të zgjedhur
  vetë.
- **User IDs** — tokeni `Bearer`. Është identifikues llogarie, ndaj hyn këtu edhe
  pse është i rastësishëm dhe nuk lidhet me asnjë të dhënë personale.
- **App interactions** — lëvizjet, rezultatet dhe pikët që ruhen te serveri, DHE
  «user product interactions» që i mbledh vetë SDK-ja e AdMob-it.
- **Diagnostics** — «diagnostic information» e AdMob-it. Aplikacioni nuk ka
  Crashlytics, ndaj **Crash logs NUK zgjidhet**.
- **Device or other IDs** — Advertising ID. `google_mobile_ads` e shton vetë
  lejen `AD_ID` te manifesti, pra Play-i e di gjithsesi.

### Pse NUK zgjidhen këto

- **Location → Approximate location.** AdMob-i lexon adresën IP, po. Por Play-i
  nuk e kërkon deklarimin e vendndodhjes kur IP-ja nuk përdoret nga ne për të
  nxjerrë vendndodhje, dhe aplikacioni nuk kërkon asnjë leje vendndodhjeje.
  Deklarimi i saj do të binte ndesh me fjalinë «Serveri ynë nuk merr
  vendndodhjen…» te politika.
- **Messages.** Tokërrgjiku nuk ka fare bisedë, as te aplikacioni, as te faqja.
- **App activity → Other user-generated content.** E vetmja gjë që shkruan
  lojtari është emri, dhe ai numërohet te **Name** — Play-i do tipin më të
  përcaktuar, jo të përgjithshmin.
- **Web browsing.** Nuk ka WebView.
- ⚠️ Çfarë ruhet **vetëm në telefon** (niveli i kompjuterit, tingujt, fitoret
  kundër kompjuterit, loja e papërfunduar) **nuk deklarohet fare**: Play-i pyet
  për të dhëna që dalin nga pajisja. Këto nuk dalin.

---

## Hapi 4 — Data usage and handling (tip pas tipi)

Për çdo tip, Play-i bën të njëjtat katër pyetje. Këtu janë përgjigjet.

### 1. Name

| | |
|---|---|
| Collected / Shared | **Collected** · jo shared |
| Processed ephemerally | **No** (ruhet te serveri) |
| Required or optional | **Users can choose whether this data is collected** |
| Why collected | **App functionality**, **Account management** |

*Optional* sepse loja kundër kompjuterit dhe loja me shok në të njëjtin telefon
punojnë pa dërguar asgjë. Emri i shkon serverit vetëm kur lojtari zgjedh «Luaj
online».

### 2. User IDs

| | |
|---|---|
| Collected / Shared | **Collected** · jo shared |
| Processed ephemerally | **No** |
| Required or optional | **Users can choose whether this data is collected** |
| Why collected | **App functionality**, **Account management** |

### 3. App interactions

| | |
|---|---|
| Collected / Shared | **Collected DHE Shared** |
| Processed ephemerally | **No** |
| Required or optional | **Data collection is required** |
| Why collected | **App functionality**, **Analytics**, **Advertising or marketing**, **Fraud prevention, security, and compliance** |
| Why shared | **Analytics**, **Advertising or marketing**, **Fraud prevention, security, and compliance** |

*Required* sepse gjysma e këtij tipi vjen nga AdMob-i, dhe reklamat nuk çkyçen
dot nga lojtari (jashtë BE/MB, ku vlen pëlqimi UMP). Kur një tip është pjesërisht
i detyrueshëm, Play-i do **Required**.

### 4. Diagnostics

| | |
|---|---|
| Collected / Shared | **Collected DHE Shared** |
| Processed ephemerally | **No** |
| Required or optional | **Data collection is required** |
| Why collected | **Analytics**, **Advertising or marketing**, **Fraud prevention, security, and compliance** |
| Why shared | **Analytics**, **Advertising or marketing**, **Fraud prevention, security, and compliance** |

### 5. Device or other IDs

| | |
|---|---|
| Collected / Shared | **Collected DHE Shared** |
| Processed ephemerally | **No** |
| Required or optional | **Data collection is required** |
| Why collected | **Advertising or marketing**, **Analytics**, **Fraud prevention, security, and compliance** |
| Why shared | **Advertising or marketing**, **Analytics**, **Fraud prevention, security, and compliance** |

---

## Hapi 5 — Preview (si duhet të dalë)

Nëse faqja e parapamjes lexohet ndryshe nga kjo, diçka u klikua gabim:

**Data shared with third parties**
- App activity — App interactions
- App info and performance — Diagnostics
- Device or other IDs

**Data collected**
- Personal info — Name, User IDs
- App activity — App interactions
- App info and performance — Diagnostics
- Device or other IDs

**Security practices**
- Data is encrypted in transit ✅
- You can request that data be deleted ✅

---

## Jashtë Data safety — tri deklarime që duhen po ashtu

1. **App content → Ads: Yes, my app contains ads.** SDK-ja duket qartë te
   analiza e paketës; mohimi kapet automatikisht.
2. **App content → Advertising ID: Yes.** Qëllimet: Advertising or marketing,
   Analytics, Fraud prevention. Duhet të përputhet me «Device or other IDs» më
   sipër.
3. **Target audience: 13+.** Nën 13 hyjnë rregullat e «Families» (pa ID
   reklamash, vetëm rrjete të certifikuara); kodi dërgon
   `tagForChildDirectedTreatment: unspecified`, që i përgjigjet 13+.

---

## Raportimi i lojtarëve (31-07-2026) — nuk shton asnjë tip të ri

`POST /api/raporto` ruan: kush raportoi, kë raportoi, emrat e të dyve në atë
çast, dhe arsyen nga një listë e mbyllur. Të gjitha bien brenda tipave që
tashmë deklarohen — **User IDs** dhe **App interactions** — ndaj formulari i
Data safety nuk ndryshon.

🔑 Nuk mblidhet asnjë tekst i lirë: arsyet janë katër vlera të ngurta. Një kuti
me tekst do të ishte përmbajtje e re e krijuar nga përdoruesi, dhe do të
kërkonte edhe deklarimin e saj edhe një filtër të vetin.
