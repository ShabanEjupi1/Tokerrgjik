import 'package:flutter/material.dart';

import 'app/theme.dart';

/// Rregullat, shkurt.
///
/// Ekran i vetëm dhe pa figura të animuara: kush e hap këtë faqe do të fillojë
/// të luajë, jo të lexojë një mësim.
class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  static const List<(String, String)> _sections = <(String, String)>[
    (
      'Tabela',
      'Njëzet e katër pika, tre katrorë njëri brenda tjetrit, të lidhur me katër '
          'vija. Secili lojtar ka nëntë gurë.'
    ),
    (
      '1. Vendosja',
      'Me radhë, secili vendos një gur në cilëndo pikë bosh, derisa të mbarojnë '
          'të nëntë.'
    ),
    (
      '2. Lëvizja',
      'Pasi mbarojnë gurët, çdo radhë është një gur i zhvendosur në një pikë '
          'bosh ngjitur — përgjatë një vije, kurrë tërthorazi.'
    ),
    (
      'Dangu',
      'Tre gurë të tutë në një vijë janë një dang. Kush e mbyll një dang, i merr '
          'një gur kundërshtarit dhe e heq nga tabela.'
    ),
    (
      'Cilin gur mund të marrësh',
      'Gurët që ndodhen brenda një dangu janë të mbrojtur. Nëse kundërshtari i ka '
          'TË GJITHË gurët në dangje, atëherë merret cilido.'
    ),
    (
      'Dangu hapet dhe mbyllet',
      'Mund ta prishësh dangun tënd duke lëvizur një gur jashtë tij, dhe ta '
          'mbyllësh sërish më vonë. Çdo mbyllje merr një gur.'
    ),
    (
      '3. Fluturimi',
      'Kur të mbeten vetëm tre gurë, ata nuk lëvizin më vetëm te pikat ngjitur: '
          'shkojnë në cilëndo pikë bosh të tabelës.'
    ),
    (
      'Fundi',
      'Humb ai që mbetet me dy gurë, ose ai që nuk ka më asnjë lëvizje. Nëse i '
          'njëjti pozicion përsëritet tri herë, ose kalojnë 100 lëvizje pa u '
          'marrë asnjë gur, loja është barazim.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Si luhet')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (BuildContext context, int i) {
            final (String title, String body) s = _sections[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(s.$1,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Palette.accent)),
                const SizedBox(height: 6),
                Text(s.$2,
                    style: const TextStyle(
                        color: Palette.textDim, fontSize: 15, height: 1.5)),
              ],
            );
          },
        ),
      ),
    );
  }
}
