/// Sfida e ditës: një lojë e vetme, e njëjtë për këdo, që ndërrohet çdo ditë.
///
/// 🔑 Asgjë këtu nuk vjen nga rrjeti. Data e vetë pajisjes e prodhon farën,
/// dhe fara përcakton nivelin dhe ngjyrën — ndaj dy telefona në të njëjtën
/// ditë marrin saktësisht të njëjtën sfidë pa folur kurrë me njëri-tjetrin.
/// I njëjti arsyetim si te sfida e Girih-it, dhe qëllimisht i njëjti kod fare.
library;

import 'package:tokerrgjik_engine/tokerrgjik_engine.dart';

class Sfida {
  const Sfida(this.niveli, this.ngjyra);

  /// Niveli i vështirësisë, 3..6.
  final int niveli;

  /// Ngjyra me të cilën luan njeriu.
  final int ngjyra;

  static String dataESotme([DateTime? tani]) =>
      (tani ?? DateTime.now()).toIso8601String().substring(0, 10);

  static String dje(String data) => DateTime.parse(data)
      .subtract(const Duration(days: 1))
      .toIso8601String()
      .substring(0, 10);

  /// Sfida e ditës [data] (`2026-08-01`).
  ///
  /// Niveli nis te 3: nën atë, çdo ditë do të fitohej pa u menduar dhe seria
  /// nuk do të thoshte asgjë. Ngjyra ndërrohet gjithashtu, sepse i bardhi luan
  /// i pari dhe ajo epërsi nuk duhet të jetë përherë e lojtarit.
  static Sfida eDites(String data) {
    final int fara =
        data.codeUnits.fold<int>(7, (int a, int c) => (a * 131 + c) & 0x7fffffff);
    return Sfida(3 + fara % 4, (fara ~/ 4).isEven ? white : black);
  }
}
