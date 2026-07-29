import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/ads.dart';
import 'app/prefs.dart';
import 'app/theme.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Loja mban gjithmonë të njëjtin drejtim: një tabelë katrore që rrotullohet
  // në mes të një radhe e humb lojtarin, dhe asgjë këtu nuk fiton nga gjerësia.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Android 15 e detyron pamjen nga buzë më buzë për aplikacionet që synojnë
  // API 35: shiritat e sistemit bëhen të tejdukshëm dhe përmbajtja shkon poshtë
  // tyre. Çdo ekran këtu është brenda një SafeArea, ndaj kjo është e sigurt —
  // dhe pa këtë deklarim shiritat do të dilnin me ngjyrë të huaj mbi tabelë.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final Prefs prefs = await Prefs.open();

  // Reklamat nisen PARALELISHT me ekranin e parë, jo para tij. Pëlqimi i BE-së
  // dhe nisja e SDK-së kërkojnë rrjet; e pritur këtu, një lidhje e ngadaltë do
  // të mbante ekranin e nisjes disa sekonda para se të shihej tabela.
  unawaited(Ads.start().then((_) => Ads.preloadInterstitial()));

  runApp(TokerrgjikApp(prefs: prefs));
}

class TokerrgjikApp extends StatelessWidget {
  const TokerrgjikApp({super.key, required this.prefs});

  final Prefs prefs;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tokërrgjik',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomePage(prefs: prefs),
    );
  }
}
