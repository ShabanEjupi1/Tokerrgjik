import 'dart:io';

import 'package:tokerrgjik_server/server.dart';
import 'package:tokerrgjik_server/store.dart';

Future<void> main(List<String> args) async {
  final int port =
      int.tryParse(Platform.environment['PORT'] ?? '') ?? 8205;
  final String dataPath = Platform.environment['TOKERRGJIK_DATA'] ??
      '/data/tokerrgjik.json';

  final Store store = Store(dataPath);
  final TokerrgjikServer server = TokerrgjikServer(store);

  // Ruajtja në disk është e shtyrë me dy sekonda; pa këtë, një `docker compose
  // up` do të hidhte poshtë çdo lëvizje të dy sekondave të fundit.
  ProcessSignal.sigterm.watch().listen((_) async {
    await server.stop();
    exit(0);
  });
  ProcessSignal.sigint.watch().listen((_) async {
    await server.stop();
    exit(0);
  });

  await server.start(port);
}
