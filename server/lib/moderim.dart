/// Filtrimi i emrave të lojtarëve.
///
/// Emri që shkruan një lojtar u shfaqet TË TJERËVE — te tabela e renditjes, te
/// dhoma dhe mbi tabelën e lojës. Pra është përmbajtje e krijuar nga përdoruesi,
/// dhe politika e Google Play-t për UGC-në kërkon dy gjëra: **filtrim** dhe
/// **një rrugë raportimi**. Kjo është e para; e dyta është `POST /api/raporto`.
///
/// 🔑 Filtri rri te SERVERI, jo te aplikacioni. Aplikacioni mund të jetë i
/// vjetër, i modifikuar ose fare mungues — emri hyn me një `curl` të vetëm.
///
/// 🚨 Ky skedar ka një binjak në JavaScript te shahu
/// (`linux-install/spacechess/moderim.mjs`): e njëjta listë, e njëjta logjikë.
/// Ndrysho njërën, ndrysho tjetrën — përndryshe i njëjti emër ndalohet te njëra
/// lojë dhe pranohet te tjetra.
library;

const int gjatesiaMax = 20;

/// Karakteret e padukshme: kontrollet, hapësirat me gjerësi zero, dhe shenjat e
/// kthimit të drejtimit (U+202E), me të cilat një emër shkruhet mbrapsht dhe i
/// prish rreshtat e tabelës së renditjes.
bool _ePadukshme(int c) =>
    c <= 0x1F ||
    c == 0x7F ||
    c == 0xAD ||
    c == 0x061C ||
    (c >= 0x200B && c <= 0x200F) ||
    (c >= 0x202A && c <= 0x202E) ||
    (c >= 0x2066 && c <= 0x2069) ||
    c == 0xFEFF;

/// Shkronjat e huaja dhe hilet e zakonshme.
///
/// 🚨 Dart-i nuk ka normalizim Unicode te biblioteka standarde (JS ka
/// `normalize('NFKD')`). Prandaj tabela këtu është e shkruar me dorë dhe duhet
/// të mbulojë atë që binjaku e merr falas: theksat, gjerësinë e plotë dhe leet-in.
const Map<String, String> _zevendesimet = <String, String>{
  'ë': 'e', 'ç': 'c', 'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'å': 'a', 'ã': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ó': 'o',
  'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ñ': 'n', 'ý': 'y', 'ÿ': 'y', 'ß': 's', 'š': 's', 'ž': 'z', 'č': 'c', 'ć': 'c',
  'đ': 'd', 'ğ': 'g', 'ı': 'i', 'ş': 's', 'ø': 'o', 'æ': 'a', 'œ': 'o', 'ź': 'z',
  'ż': 'z', 'ł': 'l', 'ń': 'n', 'ś': 's', 'ě': 'e', 'ř': 'r', 'ů': 'u', 'ț': 't',
  'ș': 's', 'ă': 'a',
  // Numrat dhe simbolet që zëvendësojnë shkronja (leet).
  '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '6': 'g', '7': 't', '8': 'b',
  '9': 'g', '@': 'a', r'$': 's', '!': 'i', '|': 'i', '+': 't', '£': 'l', '€': 'e',
};

/// Sjell tekstin te një varg i vetëm shkronjash `a-z`, që krahasimi të mos varet
/// nga shkrimi.
///
/// 🚨 Ky varg përdoret VETËM për krahasim, kurrë për shfaqje. Emri që ruhet e
/// mban shkrimin e vet.
String normalizo(String? hyrja) {
  final StringBuffer b = StringBuffer();
  for (final int c in (hyrja ?? '').toLowerCase().runes) {
    // Gjerësia e plotë (Ｆｕｃｋ) është vetëm ASCII-ja e zhvendosur me 0xFEE0.
    final int cc = (c >= 0xFF01 && c <= 0xFF5E) ? c - 0xFEE0 : c;
    final String ch = String.fromCharCode(cc);
    final String z = _zevendesimet[ch] ?? ch;
    if (z.length == 1 && z.codeUnitAt(0) >= 0x61 && z.codeUnitAt(0) <= 0x7A) {
      b.write(z);
    }
  }

  // Shtypen VETËM vargjet prej tri shkronjash e lart: «fuuuuck» → «fuck».
  //
  // 🚨 Shtypja e dyfisheve të vërteta do të hiqte pikërisht atë që i ndan
  // fjalët: «nigger» do të bëhej «niger» dhe do të ndalonte «Nigar».
  final String s = b.toString();
  final StringBuffer out = StringBuffer();
  int i = 0;
  while (i < s.length) {
    int j = i;
    while (j < s.length && s[j] == s[i]) {
      j++;
    }
    // Tri e lart → një; dyshja mbetet dyshe, njësoj si te binjaku në JS.
    out.write(j - i >= 3 ? s[i] : s.substring(i, j));
    i = j;
  }
  return out.toString();
}

/// Lista A — kërkohet si NËNVARG te i gjithë emri i bashkuar, pra kap edhe
/// «k.u.r.v.a», «kurva123» dhe «xXkurvaXx».
///
/// 🚨 Këtu hyjnë vetëm fjalë që nuk dalin brenda fjalësh të ndershme, dhe vetëm
/// pasi t'i kalojnë provës së `test/moderim_test.dart`: ai e ekzekuton filtrin
/// mbi një listë emrash e fjalësh të vërteta shqip dhe kërkon ZERO refuzime.
const List<String> _nenvargje = <String>[
  // shqip
  'pidh', 'kurv', 'qifsh', 'qirje', 'qihe', 'byth', 'pordh', 'shurr',
  // anglisht
  'fuck', 'fck', 'bullshit', 'shitty', 'bitch', 'cunt', 'whore', 'slut', 'wank',
  'dickhead', 'asshole', 'arsehole', 'bastard', 'motherf', 'pussy', 'porn',
  'blowjob', 'handjob', 'cumshot', 'dildo', 'penis', 'vagina', 'titties',
  'orgasm', 'masturb', 'pedophil', 'paedophil', 'pedofil',
  // urrejtje
  'nigger', 'nigga', 'faggot', 'tranny', 'retard', 'hitler', 'holocaust',
  'killyourself',
  // fyerje ndëretnike të rajonit
  'jebem', 'jebi', 'pizda', 'pizde', 'kurac',
];

/// Lista B — vetëm si FJALË E PLOTË, ose si i gjithë emri i bashkuar. Këtu rrinë
/// fjalët e shkurtra që si nënvargje do të ndalonin emra krejt të ndershëm:
/// «anal» te «analiza», «nazi» te «Nazimja», «derr» te «ëndërr», «kar» te
/// «karrige», «mut» te «Mutafi», «shit» te «shitje».
const List<String> _fjale = <String>[
  'mut', 'muti', 'mutin', 'derr', 'derri', 'kar', 'kari', 'karin', 'nazi',
  'anal', 'sex', 'seks', 'rape', 'shit', 'dick', 'cock', 'twat', 'fag', 'hoe',
  'ass', 'boobs', 'sik', 'sikim', 'amk', 'lesh', 'leshi',
];

/// Emra që duken zyrtarë. Një lojtar i quajtur «Admin» ose «Google Play» mund
/// t'u kërkojë të tjerëve çfarë të dojë dhe e ka gjysmën e punës të bërë.
const List<String> _teRezervuara = <String>[
  'admin', 'administrator', 'administratori', 'moderator', 'moderatori',
  'support', 'suport', 'mbeshtetje', 'staff', 'stafi', 'zyrtar', 'zyrtare',
  'sistem', 'system', 'root', 'google', 'googleplay', 'playstore', 'spacecode',
  'tokerrgjik', 'spacechess',
];

final List<String> _a =
    _nenvargje.map(normalizo).where((String s) => s.isNotEmpty).toList();
final Set<String> _b =
    _fjale.map(normalizo).where((String s) => s.isNotEmpty).toSet();
final Set<String> _r =
    _teRezervuara.map(normalizo).where((String s) => s.isNotEmpty).toSet();

const String _arsyejaFjale =
    'Ky emër përmban fjalë të papërshtatshme. Zgjidh një tjetër.';

/// Përgjigjja e filtrit: ose një emër i pastruar, ose një arsye për lojtarin.
class Emri {
  const Emri.ok(this.emri) : arsyeja = null;
  const Emri.jo(this.arsyeja) : emri = null;

  final String? emri;
  final String? arsyeja;

  bool get ok => emri != null;
}

/// Kontrollon dhe pastron një emër.
///
/// 🚨 Refuzimi është me qëllim më i mirë se zëvendësimi i heshtur me yjeza: një
/// emër i censuruar («k***a») prapë e tregon çfarë u shkrua, dhe lojtari e
/// provon sërish derisa t'ia kalojë filtrit.
Emri kontrolloEmrin(String? hyrja) {
  final String pastruar = String.fromCharCodes(
    (hyrja ?? '').runes.where((int c) => !_ePadukshme(c)),
  ).replaceAll(RegExp(r'\s+'), ' ').trim();

  if (pastruar.isEmpty) return const Emri.jo('Emri nuk mund të jetë bosh.');

  // Prerja bëhet me runes dhe jo me njësi UTF-16: një emër me emoji ose me «ë»
  // të prerë përgjysmë del i prishur te çdo pajisje tjetër.
  final List<int> runes = pastruar.runes.toList();
  final String s = runes.length <= gjatesiaMax
      ? pastruar
      : String.fromCharCodes(runes.take(gjatesiaMax));

  final String bashkuar = normalizo(s);
  if (bashkuar.length < 2) {
    return const Emri.jo('Emri duhet të ketë të paktën dy shkronja.');
  }

  for (final String term in _a) {
    if (bashkuar.contains(term)) return const Emri.jo(_arsyejaFjale);
  }

  final List<String> fjalet = s
      .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
      .map(normalizo)
      .where((String f) => f.isNotEmpty)
      .toList()
    ..add(bashkuar);

  for (final String f in fjalet) {
    if (_b.contains(f)) return const Emri.jo(_arsyejaFjale);
    if (_r.contains(f)) {
      return const Emri.jo('Ky emër është i rezervuar. Zgjidh një tjetër.');
    }
  }

  return Emri.ok(s);
}

/// Arsyet e raportimit. Listë e mbyllur me qëllim: një kuti me tekst të lirë do
/// të ishte vetë UGC — pikërisht problemi që po zgjidhet.
const List<String> arsyetERaportit = <String>[
  'emri',
  'sjellja',
  'mashtrim',
  'tjeter',
];
