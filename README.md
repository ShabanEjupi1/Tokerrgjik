# Tokërrgjik

Loja tradicionale shqiptare e strategjisë — ajo që bota e njeh si *Nine Men's
Morris*. Njëzet e katër pika, nëntë gurë për secilin, dhe një dang që të fal një
gur të kundërshtarit.

**Luaje:** https://tokerrgjik.shabanejupi.tech

## Si është ndarë

| Dosja | Ç'është |
|---|---|
| `engine/` | Rregullat dhe kompjuteri. **Dart i pastër, pa Flutter.** |
| `server/` | Loja online: ndeshje të renditura, dhoma private, SSE. Dart. |
| `tokerrgjik_mobile/` | Aplikacioni (Android, web). Flutter. |
| `store/` | Teksti dhe hapat për Google Play. |

### Rregullat ekzistojnë një herë të vetme

`engine/` është e vetmja kopje e rregullave. E përdor aplikacioni në telefon, e
përdor serveri për të vërtetuar çdo lëvizje që vjen nga rrjeti, dhe e përdor
kompjuteri kur mendon. Kjo është zgjedhja qendrore e këtij rishkrimi: versioni i
mëparshëm kishte rregullat brenda ekranit të lojës dhe një kopje të dytë te
funksionet e serverit, dhe të dyja nuk pajtoheshin.

Meqë motori nuk importon Flutter, testohet me `dart test` kudo — pa emulator, pa
telefon dhe pa Android SDK.

## Testet

```bash
cd engine && dart pub get && dart test     # rregullat, AI-ja, perft
cd server && dart pub get && dart test     # API-ja, mbi HTTP të vërtetë
cd tokerrgjik_mobile && flutter test       # përkthimi prekje → lëvizje
```

`engine/test/perft_test.dart` numëron gjethet e pemës së lëvizjeve. Deri te
thellësia 4 numrat verifikohen me laps (24·23·22·21); te thellësia 5 teprica mbi
to është saktësisht numri i vendosjeve që mbyllin dang, i llogaritur veçmas. Kjo
është rrjeta që kap gabimet që askush nuk mendon t'i shkruajë si test.

## Ndërtimi

Android dhe web ndërtohen nga GitHub Actions (`.github/workflows/build-apps.yml`).
AAB-ja del e nënshkruar me çelësin e vërtetë dhe CI-ja e refuzon shprehimisht një
AAB të nënshkruar me çelësin e debug-ut.

Hapat për te Play janë te [`store/DORËZIMI.md`](store/DORËZIMI.md).
