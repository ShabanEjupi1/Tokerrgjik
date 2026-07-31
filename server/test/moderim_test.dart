// Prova e filtrit të emrave.
//
// 🔑 Gjysma e rëndësishme e këtij testi është e DYTA: lista e emrave të vërtetë
// shqip që NUK duhen refuzuar. Një filtër fjalësh është i lehtë të bëhet i
// ashpër, dhe një lojtar që quhet «Ëndërr» ose «Nazime» dhe nuk hyn dot te loja
// nuk ankohet — thjesht largohet. Prandaj çdo fjalë e re te listat kalon këtej.
//
// 🚨 I njëjti test ekziston në JavaScript te shahu
// (`linux-install/spacechess/test-moderim.mjs`). Kur ndryshon njëra listë,
// ndryshojnë të dyja dhe ekzekutohen të dy testet.

import 'package:test/test.dart';
import 'package:tokerrgjik_server/moderim.dart';

void main() {
  group('normalizo', () {
    test('leet', () => expect(normalizo('K0rv4'), 'korva'));
    test('theksat', () => expect(normalizo('Ëndërr'), 'enderr'));
    test('dyfishet e gjata', () => expect(normalizo('fuuuuck'), 'fuck'));
    test('gjerësia e plotë', () => expect(normalizo('Ｆｕｃｋ'), 'fuck'));
    test('vetëm shkronjat', () => expect(normalizo('a.b-c_d 1'), 'abcdi'));
  });

  group('refuzohen', () {
    const List<String> keq = <String>[
      'kurva', 'KURVA', 'k u r v a', 'k.u.r.v.a', 'kurv4', 'xXkurvaXx', 'Kürvä',
      'pidhi', 'qifsha', 'byth', 'fuck', 'FUCK YOU', 'fuuuck', 'f u c k', 'fck',
      'bitch', 'Motherfucker', 'nigger', 'n1gg3r', 'faggot', 'Hitler', 'retard',
      'jebem', 'pizda', 'kurac', 'mut', 'Derri', 'nazi', 'anal', 'sex', 'rape',
      'admin', 'Administrator', 'Google Play', 'moderatori', 'SpaceCode',
      '', '   ', 'a', '🙂',
    ];
    for (final String emri in keq) {
      test('«$emri»', () => expect(kontrolloEmrin(emri).ok, isFalse));
    }
  });

  group('pranohen', () {
    // Fjalë dhe emra të vërtetë shqip që përmbajnë vargjet e listës brenda
    // tyre: «Ëndërr» ka «derr», «Nazime» ka «nazi», «Karrige» ka «kar»,
    // «Shitësi» ka «shit», «Analiza» ka «anal», «Kastriot» ka «as».
    const List<String> mire = <String>[
      'Shaban', 'Arbër', 'Ëndërr', 'Endrit', 'Nazime', 'Nazmi', 'Karrige',
      'Kastriot', 'Shitësi', 'Analiza', 'Muhamet', 'Mutafi', 'Fatlum',
      'Butrint', 'Bleona', 'Leart', 'Diell', 'Kushtrim', 'Anila', 'Besart',
      'Lulzim', 'Shqipe', 'Përparim', 'Çelik', 'Gëzim', 'Dukagjini',
      'Shkumbin', 'Assia', 'Nigar', 'Alessandro', 'Cocker', 'Ana Maria',
      'lojtar 7', 'Pusi i Thellë', 'Fuqia', 'Fukara', 'Sikur', 'Lesnina',
    ];
    for (final String emri in mire) {
      test('«$emri»', () => expect(kontrolloEmrin(emri).ok, isTrue,
          reason: kontrolloEmrin(emri).arsyeja));
    }
  });

  group('pastrimi', () {
    test('hapësirat', () => expect(kontrolloEmrin('  Ana   Maria  ').emri, 'Ana Maria'));
    test('gjatësia', () => expect(kontrolloEmrin('Arber' * 12).emri!.length, 20));
    test('karakteret e padukshme',
        () => expect(kontrolloEmrin('An\u202Ea\u200B').emri, 'Ana'));
  });
}
