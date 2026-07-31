import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'api.dart';

/// Fleta e raportimit të një lojtari.
///
/// Politika e Google Play-t për përmbajtjen e krijuar nga përdoruesit kërkon dy
/// gjëra: filtrim (te serveri, `moderim.dart`) dhe një rrugë raportimi. Kjo është
/// e dyta, dhe rri pikërisht aty ku emri i huaj shihet: te tabela e pikëve dhe
/// mbi tabelën e lojës.
///
/// 🔑 Arsyet janë listë e mbyllur. Një kuti me tekst të lirë do të ishte vetë
/// përmbajtje e krijuar nga përdoruesi — pra do të kërkonte të njëjtin filtër
/// mbi vete, dhe do të hapte një kanal të ri ku dikush shan të tjerët.
const Map<String, String> arsyetERaportit = <String, String>{
  'emri': 'Emër i papërshtatshëm',
  'sjellja': 'Sjellje fyese',
  'mashtrim': 'Mashtrim',
  'tjeter': 'Diçka tjetër',
};

Future<void> showReportSheet({
  required BuildContext context,
  required Api api,
  required String targetId,
  required String targetName,
}) async {
  final String? reason = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Palette.surface,
    showDragHandle: true,
    builder: (BuildContext sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text('Raporto «$targetName»'),
            subtitle: const Text('Raporti shkon te administratori i lojës.'),
          ),
          const Divider(height: 1),
          ...arsyetERaportit.entries.map((MapEntry<String, String> e) => ListTile(
                title: Text(e.value),
                onTap: () => Navigator.of(sheet).pop(e.key),
              )),
        ],
      ),
    ),
  );
  if (reason == null || !context.mounted) return;

  String message = 'Faleminderit. Raporti u dërgua.';
  try {
    await api.report(targetId, reason);
  } on ApiError catch (e) {
    message = e.message;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}
