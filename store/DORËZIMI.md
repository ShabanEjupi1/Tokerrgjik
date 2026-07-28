# Ngarkimi te Google Play — hapat, me radhë

Llogaria e zhvilluesit është aktive. Kjo është lista e plotë, dhe vetëm ajo që
mbetet për t'u bërë me dorë.

## 1. Merr AAB-në

CI-ja e ndërton dhe e nënshkruan vetë. Nga GitHub Actions:

- shko te *Actions* → **Ndërto dhe testo** → ekzekutimi i fundit i gjelbër,
- shkarko artefaktin **android**,
- brenda është `app-release.aab` (për Play) dhe `app-release.apk` (për ta provuar
  vetë në telefon).

Ose bëj një etiketë dhe artefaktet ngjiten te një GitHub Release:

```
git tag v2.0.0 && git push github v2.0.0
```

🚨 **Mos ngarko një AAB të ndërtuar me `flutter build` në një makinë pa
`key.properties`.** Ai nënshkruhet me çelësin e debug-ut, ngarkohet pa u ankuar
askush, dhe refuzohet vetëm nga Play Console pasi ke pritur. CI-ja e kontrollon
këtë veçmas (hapi «Kontrollo se AAB-ja NUK është nënshkruar me çelësin e
debug-ut»).

## 2. Krijo aplikacionin te Play Console

- Emri: **Tokërrgjik** · Gjuha e parazgjedhur: **shqip (sq-AL)**
- Lloji: **Lojë** · Falas
- Kategoria: **Bord**

## 3. Plotëso listimin

Kopjo tekstin nga [`LISTIMI.md`](LISTIMI.md).

Duhen edhe:
- **Ikona** 512×512 PNG
- **Grafika e veçorive** 1024×500 PNG
- **Së paku 2 pamje ekrani** telefoni (16:9 ose 9:16, min 320 px)

Pamjet merren nga vetë aplikacioni: hap `https://tokerrgjik.shabanejupi.tech` në
telefon, ose ndiz APK-në dhe fotografo ballinën, një lojë në mes dhe tabelën e
pikëve.

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
