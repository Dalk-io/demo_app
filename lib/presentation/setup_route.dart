import 'package:dalk/presentation/conversations_route.dart';
import 'package:dalk/presentation/dialogs.dart';
import 'package:dalk/presentation/google_button.dart';
import 'package:dalk/stores/login_store.dart';
import 'package:dalk/stores/talk_store.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:proxy_layout/proxy_layout.dart';
import 'package:sleek_spacing/sleek_spacing.dart';

class SetupScreen extends HookWidget {
  static const route = '/';

  @override
  Widget build(BuildContext context) {
    final talkStore = Provider.of<TalkStore>(context, listen: false);
    final loginStore = Provider.of<LoginStore>(context);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showWaitingDialog(context, () async {
          await loginStore.login(silently: true);
          await talkStore.setup(
            loginStore.firebaseUser.uid,
            loginStore.firebaseUser.displayName,
            loginStore.firebaseUser.photoUrl,
          );
        }, onSuccess: () {
          Navigator.of(context)?.pushReplacementNamed(ConversationsScreen.route);
        }, onFailure: (ex, stack) {
          print('not logged');
          print(ex);
          print(stack);
        });
      });
      return null;
    }, const []);

    return DeviceProxy(
      mobileBuilder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Dalk'),
          ),
          body: SleekPadding(
            padding: SleekInsets.big(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _Form(),
                Expanded(
                  child: Center(
                    child: FlareActor(
                      "assets/robot.flr",
                      animation: "headphones",
                    ),
                  ),
                ),
                _getDisclaimer(),
              ],
            ),
          ),
        );
      },
      tabletBuilder: (context) {
        return Container(
          color: Colors.lightGreen,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Card(
                  child: SleekPadding(
                    padding: SleekInsets.big(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _Form(),
                        SizedBox(
                          width: 190,
                          height: 190,
                          child: Center(
                            child: FlareActor(
                              "assets/robot.flr",
                              animation: "headphones",
                            ),
                          ),
                        ),
                        _getDisclaimer(),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _getDisclaimer() {
    return Text(
      'As a demo project, data will be reset every week',
      textAlign: TextAlign.center,
      style: TextStyle(fontStyle: FontStyle.italic),
    );
  }
}

class _Form extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loginStore = Provider.of<LoginStore>(context);
    final talkStore = Provider.of<TalkStore>(context, listen: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Login or register using your Google account',
          style: Theme.of(context).textTheme.subtitle1.copyWith(fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
        SleekPadding.normal(),
        GoogleLoginButton(
          onPressed: () {
            showWaitingDialog(context, () async {
              await loginStore.login();
              await talkStore.setup(
                loginStore.firebaseUser.uid,
                loginStore.firebaseUser.displayName,
                loginStore.firebaseUser.photoUrl,
              );
            }, onSuccess: () {
              Navigator.of(context)?.pushReplacementNamed(ConversationsScreen.route);
            });
          },
        ),
      ],
    );
  }
}
