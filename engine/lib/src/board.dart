/// Topologjia e tabelës së Tokërrgjikut. Vetëm të dhëna — asnjë gjendje loje.
///
/// Tabela ka tre katrorë koncentrikë ("unaza") me nga 8 pika, gjithsej 24.
/// Numërimi është `unaza * 8 + pozita`, ku pozita ecën në akrep të orës duke
/// nisur nga këndi lart-majtas:
///
/// ```
///   0----------1----------2        unaza 0 (e jashtme)   0..7
///   |          |          |        unaza 1 (e mesme)     8..15
///   |  8-------9------10  |        unaza 2 (e brendshme) 16..23
///   |  |       |       |  |
///   |  |  16--17--18   |  |        pozitat brenda nje unaze:
///   |  |  |        |   |  |          0 lart-majtas    1 lart
///   7-15-23       19-11--3          2 lart-djathtas  3 djathtas
///   |  |  |        |   |  |          4 posht-djathtas 5 poshte
///   |  |  22--21--20   |  |          6 posht-majtas   7 majtas
///   |  |       |       |  |
///   | 14------13------12  |
///   |          |          |
///   6----------5----------4
/// ```
///
/// Ky numërim u zgjodh me qëllim që unaza dhe pozita të nxirren me pjesëtim e
/// mbetje (`i ~/ 8`, `i % 8`): tabelat më poshtë ndërtohen prej tij, kështu që
/// nuk ka listë të shkruar me dorë ku një numër i gabuar do të kalonte pa u
/// vënë re. Testet e verifikojnë simetrinë dhe numrat.
library;

/// Numri i pikave në tabelë.
const int pointCount = 24;

/// Gurët që ka çdo lojtar në fillim.
const int piecesPerPlayer = 9;

/// Vlerat e një pike.
const int empty = 0;
const int white = 1;
const int black = 2;

/// Kundërshtari i një lojtari.
int opponentOf(int player) => player == white ? black : white;

/// Pozitat "të mesit të brinjës" — të vetmet që lidhin unazat mes tyre.
/// Këndet (0, 2, 4, 6) nuk kalojnë kurrë nga një unazë në tjetrën.
const List<int> spokePositions = <int>[1, 3, 5, 7];

List<List<int>> _buildAdjacency() {
  final List<List<int>> adj =
      List<List<int>>.generate(pointCount, (_) => <int>[], growable: false);

  void link(int a, int b) {
    if (!adj[a].contains(b)) adj[a].add(b);
    if (!adj[b].contains(a)) adj[b].add(a);
  }

  for (int ring = 0; ring < 3; ring++) {
    // Rrethi i unazës: 0-1-2-3-4-5-6-7-0.
    for (int pos = 0; pos < 8; pos++) {
      link(ring * 8 + pos, ring * 8 + (pos + 1) % 8);
    }
    // Shufrat drejt unazës së brendshme.
    if (ring < 2) {
      for (final int pos in spokePositions) {
        link(ring * 8 + pos, (ring + 1) * 8 + pos);
      }
    }
  }

  for (final List<int> a in adj) {
    a.sort();
  }
  return adj;
}

List<List<int>> _buildMills() {
  final List<List<int>> out = <List<int>>[];

  for (int ring = 0; ring < 3; ring++) {
    // Katër brinjët e një unaze. Secila nis nga një kënd dhe mbaron te tjetri.
    for (int corner = 0; corner < 8; corner += 2) {
      out.add(<int>[
        ring * 8 + corner,
        ring * 8 + corner + 1,
        ring * 8 + (corner + 2) % 8,
      ]);
    }
  }

  // Katër shufrat që kalojnë nëpër të tre unazat.
  for (final int pos in spokePositions) {
    out.add(<int>[pos, 8 + pos, 16 + pos]);
  }

  return out;
}

/// Pikat fqinje të secilës pikë. Lëvizja në fazën e dytë shkon vetëm këtu.
final List<List<int>> adjacency =
    List<List<int>>.unmodifiable(_buildAdjacency().map(List<int>.unmodifiable));

/// Të 16 "dangjet" (tre gurë në rresht) që ekzistojnë në tabelë.
final List<List<int>> mills =
    List<List<int>>.unmodifiable(_buildMills().map(List<int>.unmodifiable));

/// Për çdo pikë, indekset e dangjeve që e përmbajnë. Kjo është arsyeja që
/// kontrolli «a formova dang?» kushton dy-tre krahasime dhe jo një kalim mbi të
/// 16 dangjet: bëhet në çdo nyje të kërkimit të AI-së.
final List<List<int>> millsThrough = List<List<int>>.unmodifiable(
  List<List<int>>.generate(pointCount, (int point) {
    final List<int> out = <int>[];
    for (int m = 0; m < mills.length; m++) {
      if (mills[m].contains(point)) out.add(m);
    }
    return List<int>.unmodifiable(out);
  }),
);

/// Koordinata në katrorin njësi (0..1) për vizatim. Unaza e jashtme prek buzët,
/// secila e brendshme tërhiqet nga një e gjashta.
///
/// I mban motori dhe jo ndërfaqja sepse një tabelë e vizatuar ndryshe nga ajo
/// që llogaritet është gabimi më i vështirë për t'u parë: loja do të ishte e
/// saktë dhe pamja gënjeshtare.
final List<double> pointX = List<double>.unmodifiable(
  List<double>.generate(pointCount, (int i) => _coord(i)[0]),
);
final List<double> pointY = List<double>.unmodifiable(
  List<double>.generate(pointCount, (int i) => _coord(i)[1]),
);

List<double> _coord(int index) {
  final int ring = index ~/ 8;
  final int pos = index % 8;
  final double inset = ring / 6.0; // 0, 1/6, 2/6
  final double lo = inset;
  final double hi = 1.0 - inset;
  const double mid = 0.5;

  switch (pos) {
    case 0:
      return <double>[lo, lo];
    case 1:
      return <double>[mid, lo];
    case 2:
      return <double>[hi, lo];
    case 3:
      return <double>[hi, mid];
    case 4:
      return <double>[hi, hi];
    case 5:
      return <double>[mid, hi];
    case 6:
      return <double>[lo, hi];
    default:
      return <double>[lo, mid];
  }
}
