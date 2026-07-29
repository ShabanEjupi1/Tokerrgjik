# Ngarkimi te Google Play — hapat, me radhë

Llogaria e zhvilluesit është aktive. Kjo është lista e plotë, dhe vetëm ajo që
mbetet për t'u bërë me dorë.

## 0. Çfarë NUK e bën dot llogaria e shërbimit

Llogaria e shërbimit e lidhur me Play
(`account@gen-lang-client-0731929158.iam.gserviceaccount.com`) i automatizon
ngarkimet, por jo krijimin. Konkretisht:

| Veprim | API | Play Console |
|---|---|---|
| Krijimi i aplikacionit (emri, kategoria, deklaratat) | ⛔ | ✅ vetëm këtu |
| Ngarkimi i **parë** i një AAB-je | ⛔ | ✅ vetëm këtu |
| Teksti i listimit, grafikat, pamjet | ⛔ | ✅ vetëm këtu |
| Data safety + klasifikimi i përmbajtjes | ⛔ | ✅ vetëm këtu |
| Çdo ngarkim i mëpasëm, në çdo gjurmë | ✅ | — |
| Kalimi nga testimi te prodhimi | ✅ | ✅ |

Prandaj hapat 1–6 më poshtë bëhen **një herë, me dorë**. Pas tyre, çdo version i
ri është një etiketë:

```
git tag v2.0.1 && git push github v2.0.1
```

…dhe puna `play` te `.github/workflows/build-apps.yml` e ngarkon vetë AAB-në te
gjurma e brendshme.

### Çelësi i llogarisë së shërbimit

API-ja kërkon skedarin JSON të çelësit privat — jo emailin dhe jo «unique ID».
Nga Google Cloud Console → IAM → Service Accounts → ajo llogari → Keys →
**Add key → Create new key → JSON**.

Pastaj:

1. ruaje te `spacecode-brain/play-service-account.json` (depoja private është
   pikërisht për këtë);
2. provoje pa ngarkuar asgjë:

```
ssh ampere 'sudo docker run --rm --network host \
  -v /mnt/data/workspace:/w -w /w/Tokerrgjik/store/tools node:22-slim \
  node play.mjs /w/spacecode-brain/play-service-account.json \
      kontrollo com.ejupishaban.tokerrgjik'
```

   `401` = çelësi; `403` = llogaria s'është ftuar te Play Console (Users and
   permissions → Invite user → e drejta «Releases»); `404` = aplikacioni nuk
   ekziston ende atje.
3. vendose si sekret `PLAY_SERVICE_ACCOUNT_JSON` te të dyja depot e GitHub-it
   (Settings → Secrets and variables → Actions), me përmbajtjen e plotë të JSON-it.

## 1. Merr AAB-në

Është e ndërtuar dhe e nënshkruar tashmë:

```
Tokerrgjik/dist/tokerrgjik-2.0.0+20.aab      ← ky ngarkohet te Play
Tokerrgjik/dist/tokerrgjik-2.0.0+20.apk      ← ky instalohet në telefon për provë
```

Nënshkruar me `CN=Shaban Ejupi, OU=Tokerrgjik` — çelësi i vërtetë, i verifikuar.

🚨 **Mos ngarko një AAB të ndërtuar me `flutter build` në një makinë pa
`key.properties`.** Ai nënshkruhet me çelësin e debug-ut, ngarkohet pa u ankuar
askush, dhe refuzohet vetëm nga Play Console pasi ke pritur.

## 2. Krijo aplikacionin te Play Console

- Emri: **Tokërrgjik** · Gjuha e parazgjedhur: **shqip (sq-AL)**
- Lloji: **Lojë** · Falas
- Kategoria: **Bord**
- Paketa: **com.ejupishaban.tokerrgjik** (nuk ndryshohet më kurrë)

## 3. Plotëso listimin

Teksti: [`LISTIMI.md`](LISTIMI.md). Grafikat janë të gatshme te `assets/`:

| Skedari | Ç'është |
|---|---|
| `play-ikona-512.png` | ikona 512×512 |
| `play-grafika-1024x500.png` | grafika e veçorive |
| `pamje-1-ballina.png` | ballina |
| `pamje-2-loja.png` | një lojë në mes |
| `pamje-3-nivelet.png` | tetë nivelet |
| `pamje-4-online.png` | loja online |
| `pamje-5-rregullat.png` | rregullat |

Pamjet janë 1080×1920 dhe janë marrë nga vetë aplikacioni (ndërtimi i web-it, i
njëjti kod Flutter), jo të vizatuara me dorë. Rigjenerohen me
`store/tools/pamje.mjs`.

## 4. Politika e privatësisë

URL: **https://tokerrgjik.shabanejupi.tech/privatesia.html**

Burimi është `tokerrgjik_mobile/web/privatesia.html` dhe shkon në internet bashkë
me ndërtimin e web-it — pra nuk mund të mbetet prapa versionit të aplikacionit.

## 5. «Siguria e të dhënave» dhe klasifikimi

Tabelat e gatshme janë te [`LISTIMI.md`](LISTIMI.md). Të dyja janë deklarime me
peshë ligjore: mos u përgjigj «asgjë nuk mblidhet» sepse tingëllon më mirë —
aplikacioni e dërgon emrin te serveri kur luhet online.

## 6. Testimi i brendshëm i parë

Ngarko AAB-në te **Testim i brendshëm**, shtoje veten si testues, instaloje nga
lidhja dhe luaj një ndeshje online me dikë tjetër. Vetëm pas kësaj kalo te
prodhimi.

🚨 **Llogari personale = 12 testues për 14 ditë.** Nëse llogaria e Play-it është
personale (jo organizatë), Google kërkon një **testim të mbyllur me së paku 12
testues, të vazhdueshëm për 14 ditë** para se prodhimi të hapet fare. Kjo nuk
kapërcehet dot; është më mirë ta nisësh atë orë sot sesa të presësh.

---

## Reklamat (AdMob) — çfarë të duhet

Kjo është ajo që AdMob-i kërkon për «Add app»:

| Fusha | Vlera |
|---|---|
| Platforma | Android |
| Emri i aplikacionit | **Tokërrgjik** |
| Paketa | **com.ejupishaban.tokerrgjik** |
| URL-ja te Play (pas publikimit) | `https://play.google.com/store/apps/details?id=com.ejupishaban.tokerrgjik` |
| SpaceChess (paketa) | **tech.spacecode.chess** |

Nuk është nevoja të presësh publikimin: te AdMob zgjidh **«Is your app listed on
a supported app store?» → No**, merr `App ID`-në (`ca-app-pub-…~…`) dhe lidhe me
listimin më vonë, kur të jetë live.

🚨 **Versioni 2.0.0 që po ngarkohet NUK ka reklama.** Rishkrimi i 28 korrikut i
hoqi të 26 paketat e vjetra, përfshi AdMob-in. Për t'i futur duhet një version i
ri (2.1.0) me `google_mobile_ads`, dhe bashkë me të:

- deklarata «Contains ads» te Play Console,
- «Data safety» ndryshon: AdMob mbledh identifikuesin e reklamave,
- klasifikimi i përmbajtjes bëhet sërish.

Prandaj rendi i saktë është: **publiko 2.0.0 pa reklama → krijo aplikacionin te
AdMob → shto reklamat te 2.1.0.**

### 🕌 Filtrimi i reklamave

Rrjeti i AdMob-it shet edhe bixhoz, alkool, kredi me kamatë dhe takime — pra
një aplikacion i pastër mund të shfaqë përmbajtje që bie ndesh me atë që
mbrohet këtu. Filtrimi bëhet në dy vende, dhe të dyja duhen:

1. **Te kodi**, kur nisen reklamat:
   `MaxAdContentRating.g` — vetëm përmbajtje për të gjithë.
2. **Te AdMob Console → Blocking controls → Sensitive categories**: bllokoji
   *Gambling & betting*, *Alcohol*, *Dating*, *Get rich quick*, *Sexually
   suggestive*, *Religion* (reklamat fetare të tjera), *Politics*, dhe
   *Cosmetic procedures*. Bllokimi është për llogari dhe për aplikacion.

Asnjëra vetëm nuk mjafton: e para kufizon klasifikimin, e dyta kategorinë.

---

## Ç'nuk bëhet dot këtu

- **iOS.** Duhet një Mac me Xcode dhe një çertifikatë shpërndarjeje nga një
  llogari Apple Developer me pagesë (99 $/vit). Asnjë makinë Linux nuk e prodhon
  dot një `.ipa` të nënshkruar. Kur llogaria të ekzistojë, shtohet një punë
  `macos-latest` te workflow-i dhe `fastlane match` ose sekretet `.p12`.

## Çelësi i nënshkrimit — lexoje një herë

`android/app/release.jks` është i vetmi çelës me të cilin ky aplikacion mund të
përditësohet ndonjëherë. Nëse humbet:

- Play-i refuzon çdo AAB të nënshkruar ndryshe,
- aplikacioni duhet të rilistohet nga zeroja, me paketë tjetër,
- dhe të gjithë instalimet ekzistuese mbeten pa përditësime, përgjithmonë.

Ekziston në tri vende: te kjo makinë, te sekreti `ANDROID_KEYSTORE_BASE64` i
GitHub-it, dhe te `credentials.local.txt` (fjalëkalimet). **Bëj një kopje të
katërt jashtë linje.**
