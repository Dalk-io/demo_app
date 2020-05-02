import 'package:dalk/presentation/chat_route.dart';
import 'package:dalk/presentation/conversations_route.dart';
import 'package:dalk/presentation/setup_route.dart';
import 'package:dalk/stores/login_store.dart';
import 'package:dalk/stores/dalk_store.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:sleek_spacing/sleek_spacing.dart';

enum Env {
  prod, staging,
}

class Flavor {
  static Flavor current;
  final Env env;

  Flavor(this.env);
}

void launch() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.message}');
    if (record.error != null) {
      print(record.error);
      print(record.stackTrace);
    }
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SleekSpacing(
      data: SleekSpacingData(
        extraSmall: 2.0,
        small: 6.0,
        normal: 12.0,
        medium: 24.0,
        big: 48.0,
        extraBig: 96.0,
      ),
      child: MultiProvider(
        providers: [
          Provider<LoginStore>(create: (BuildContext context) => LoginStore()),
          Provider<DalkStore>(
            create: (_) => DalkStore(),
            dispose: (context, store) => store.dispose(),
          ),
        ],
        child: MaterialApp(
          title: 'Dalk.io demo',
          theme: ThemeData(
            primarySwatch: Colors.green,
          ),
          routes: {
            SetupScreen.route: (context) => SetupScreen(),
            ChatScreen.route: (context) => ChatScreen(),
            ConversationsScreen.route: (context) => ConversationsScreen(),
          },
          initialRoute: SetupScreen.route,
        ),
      ),
    );
  }
}
