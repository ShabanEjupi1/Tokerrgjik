# Tokërrgjik — teksti për Google Play

Gati për t'u ngjitur te Play Console. Shqipja është gjuha e parazgjedhur,
anglishtja e dyta.

- **Emri i aplikacionit:** Tokërrgjik
- **Paketa:** `com.ejupishaban.tokerrgjik`
- **Kategoria:** Lojëra › Bord
- **Klasifikimi i synuar:** Për të gjithë / 3+
- **Çmimi:** Falas. **Me reklama (AdMob). Pa blerje brenda aplikacionit.**
- **Politika e privatësisë:** https://tokerrgjik.shabanejupi.tech/privatesia.html

---

## Shqip (parazgjedhje)

**Titulli** (maks. 30):
```
Tokërrgjik — loja shqiptare
```

**Përshkrimi i shkurtër** (maks. 80):
```
Loja tradicionale shqiptare e strategjisë. Kundër kompjuterit, shokut ose online.
```

**Përshkrimi i plotë** (maks. 4000):
```
Tokërrgjiku është loja që brezat e kanë luajtur me guralecë mbi tokë, me një
tabelë të vizatuar me shkop. Tani e ke në telefon — të njëjtat rregulla, i
njëjti mendim.

Vendos nëntë gurët e tu. Mbyll një dang — tre gurë në një vijë — dhe merri një
gur kundërshtarit. Kur të mbeten tre gurë, ata fluturojnë kudo në tabelë. Humb ai
që mbetet me dy, ose ai që nuk ka më ku të lëvizë.

E thjeshtë për t'u mësuar. E vështirë për t'u zotëruar.

SI LUHET
• Kundër kompjuterit, në gjashtë nivele — nga fillestari deri te mjeshtri
• Dy lojtarë në të njëjtin telefon
• Online kundër një kundërshtari të rastësishëm, me pikë dhe renditje
• Online kundër një shoku, me një kod dhome katërshkronjësh

ÇFARË NUK KA
• Pa blerje brenda aplikacionit
• Pa regjistrim, pa email, pa fjalëkalim
• Pa leje të panevojshme — vetëm interneti, dhe vetëm kur luan online

REKLAMAT
Aplikacioni shfaq reklama, dhe ato janë të filtruara për familje: pa bixhoz, pa
alkool, pa takime dhe pa kredi me kamatë. Reklamat nuk ndërhyjnë kurrë brenda një
loje — vetëm në menu dhe pasi loja të ketë mbaruar.

Loja kundër kompjuterit dhe ajo me dy lojtarë punojnë PLOTËSISHT PA INTERNET.

Krejtësisht në shqip.
```

**Fjalët kyçe / etiketat:** tokërrgjik, lojë shqiptare, strategji, bord, dang,
guralecë, lojë tradicionale, offline

---

## English

**Title** (max 30):
```
Tokërrgjik — Albanian Mills
```

**Short description** (max 80):
```
The traditional Albanian strategy game. Play the computer, a friend, or online.
```

**Full description** (max 4000):
```
Tokërrgjik is the game Albanian generations played with pebbles on the ground and
a board scratched with a stick. Same rules, same thinking, now on your phone.
It is the game known elsewhere as Nine Men's Morris.

Place your nine stones. Close a mill — three in a line — and take one of your
opponent's stones off the board. Down to three stones, yours fly anywhere. You
lose when two are left, or when you have nowhere to move.

Easy to learn. Hard to master.

HOW YOU PLAY
• Against the computer, at six levels — from beginner to master
• Two players on the same phone
• Online against a random opponent, with ratings and a leaderboard
• Online against a friend, with a four-letter room code

WHAT IT DOES NOT HAVE
• No in-app purchases
• No sign-up, no email, no password
• No unnecessary permissions — internet only, and only when playing online

ADS
The app shows ads, filtered for families: no gambling, no alcohol, no dating, no
interest-bearing loans. Ads never interrupt a game in progress — only the menu and
the screen after a game ends.

Playing the computer and two-player mode work COMPLETELY OFFLINE.

The app is in Albanian.
```

---

## Formulari «Siguria e të dhënave» (Data safety)

Përgjigjet e sakta për aplikacionin siç është sot. Mos i ndrysho pa e ndryshuar
kodin.

| Pyetja | Përgjigjja |
|---|---|
| A mblidhen apo ndahen të dhëna? | **Po, mblidhen** (vetëm te loja online) |
| A ndahen me palë të treta? | **Jo** |
| A janë të koduara në transit? | **Po** (HTTPS) |
| A mund të kërkojë përdoruesi fshirjen? | **Po** — me email, shih politikën |
| Lloji: Emri (Personal info › Name) | Mblidhet · opsionale · për funksionimin e aplikacionit |
| Lloji: ID-të (Device or other IDs) | **PO** — identifikuesi i reklamave (shih poshtë). Kodi ynë i identifikimit gjenerohet nga serveri dhe nuk lidhet me pajisjen. |
| Vendndodhja, kontaktet, fotot, financat, shëndeti | **Jo** |
| Reklamat / ID e reklamave | **PO** — AdMob (që nga versioni 2.1.0) |
| Analitika | **Jo** |

⚠️ «Emri» është i detyrueshëm si deklarim edhe pse e shkruan vetë përdoruesi:
Play e quan të dhënë personale çdo emër që del nga pajisja, edhe një pseudonim.

🚨 **Që nga 2.1.0 aplikacioni ka reklama, dhe kjo ndryshon TRI deklarime te
Console-i.** Ngarkimi kalon edhe pa to; ajo që bie më vonë është aplikacioni,
kur Play-i e krahason deklarimin me atë që sheh vetë te paketa:

1. **Store presence → Ads: «Po, ka reklama».** SDK-ja e AdMob-it duket qartë te
   analiza e paketës; një «jo» këtu është deklarim i rremë, jo harresë.
2. **Data safety → Device or other IDs: mblidhen DHE ndahen, për «Advertising or
   marketing».** SDK-ja shton vetë lejen `AD_ID` te manifesti — pra Play-i e di,
   pavarësisht se çfarë shkruajmë ne.
3. **Publiku i synuar: 13 vjeç e lart.** Nëse zgjidhet një grupmoshë nën 13,
   hyjnë në fuqi rregullat e «Familjeve»: pa identifikues reklamash dhe vetëm
   rrjete të certifikuara. Kodi sot dërgon
   `tagForChildDirectedTreatment: unspecified`, që i përgjigjet 13+.

🕌 **Filtrimi është në dy vende dhe të dyja duhen.** Kodi cakton
`MaxAdContentRating.g` (klasifikimi). Konsola e AdMob-it → Blocking controls →
Sensitive categories duhet të bllokojë **bixhozin, alkoolin, takimet dhe kreditë
me kamatë** (tema). Një reklamë bixhozi mund të jetë fare mirë e klasifikuar «G»,
ndaj vetëm kodi nuk mjafton.

## Klasifikimi i përmbajtjes (IARC)

- Dhunë: jo · Seks: jo · Gjuhë e papërshtatshme: jo · Drogë: jo
- Bixhoz: **jo** (loja nuk ka as monedha as vënie bastesh)
- Ndërveprim mes përdoruesve: **PO** — ka lojë online. Nuk ka bisedë me shkrim;
  e vetmja gjë që shkëmbejnë dy lojtarë janë lëvizjet dhe emrat.
- Ndarja e vendndodhjes: jo · Blerje digjitale: jo
