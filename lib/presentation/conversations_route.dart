import 'dart:math' as math;

import 'package:dalk/presentation/chat_route.dart';
import 'package:dalk/presentation/dialogs.dart';
import 'package:dalk/presentation/setup_route.dart';
import 'package:dalk/presentation/user_search.dart';
import 'package:dalk/stores/login_store.dart';
import 'package:dalk/stores/talk_store.dart';
import 'package:dalk_sdk/sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:proxy_layout/proxy_layout.dart';
import 'package:sleek_spacing/sleek_spacing.dart';

class ConversationsScreen extends HookWidget with AvatarBuilder {
  static const route = '/conversations';

  @override
  Widget build(BuildContext context) {
    final talkStore = Provider.of<TalkStore>(context);
    final floatButtonLocation = useMemoized(() => _StartFloatFloatingActionButtonLocation());

    final refreshData = () => talkStore.loadConversations().catchError((ex, stack) {
          print(ex);
          print(stack);
          showErrorDialog(context, ex.toString());
        });
    useEffect(() {
      refreshData();
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.power_settings_new),
          tooltip: 'Logout',
          onPressed: () async {
            final loginStore = Provider.of<LoginStore>(context, listen: false);

            final success = await showConfirmDialog(context, 'Logout', 'Do you really want to log out ?') ?? false;
            if (success) {
              showWaitingDialog(
                context,
                () async {
                  await loginStore.logout();
                  await talkStore.logout();
                },
                onSuccess: () => Navigator.of(context)?.pushReplacementNamed(SetupScreen.route),
              );
            }
          },
        ),
        actions: <Widget>[
          Observer(
            builder: (context) {
              if (talkStore.me?.avatar == null) {
                return Container();
              }

              return SleekPadding(
                padding: SleekInsets.small(),
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(talkStore.me.avatar),
                  backgroundColor: Colors.transparent,
                ),
              );
            },
          ),
        ],
        title: Observer(builder: (context) => Text(talkStore.me?.name ?? '')),
      ),
      floatingActionButtonLocation: DeviceProxy.isMobile(context) ? FloatingActionButtonLocation.endFloat : floatButtonLocation,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final user = await showSearch(context: context, delegate: UserSearchDelegate(talkStore));
          if (user != null) {
            showWaitingDialog(context, () => talkStore.createConversation(user), onSuccess: () async {
              if (DeviceProxy.isMobile(context)) {
                await Navigator.of(context).pushNamed(ChatScreen.route);
                refreshData();
              }
            });
          }
          talkStore.selectedUsersForGroup.clear();
        },
        child: Icon(Icons.add),
      ),
      body: DeviceProxy(
        mobileBuilder: (context) {
          return _ConversationList(
            onRefresh: refreshData,
            onTap: (conv) {
              showWaitingDialog(context, () => talkStore.loadConversation(conv.id), onSuccess: () async {
                await Navigator.of(context).pushNamed(ChatScreen.route);
                refreshData();
              });
            },
          );
        },
        tabletBuilder: (context) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                child: _ConversationList(
                  onRefresh: refreshData,
                  onTap: (conv) {
                    showWaitingDialog(context, () => talkStore.loadConversation(conv.id), onSuccess: () {});
                  },
                ),
              ),
              Container(width: 1, color: Colors.grey),
              Expanded(child: ChatScreen(headless: true), flex: 3),
            ],
          );
        },
      ),
    );
  }
}

class _ConversationList extends HookWidget with AvatarBuilder {
  final void Function(Conversation conv) onTap;
  final Future Function() onRefresh;

  _ConversationList({Key key, @required this.onRefresh, @required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final talkStore = Provider.of<TalkStore>(context);

    return Observer(
      builder: (context) {
        if (talkStore.conversations == null) {
          return Center(child: CircularProgressIndicator());
        }
        if (talkStore.conversations.isEmpty) {
          return SleekPadding(
            padding: SleekInsets.normal(),
            child: Center(
              child: Text('No conversation yet, create one!', textAlign: TextAlign.center),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () {
            return onRefresh();
          },
          child: ListView.builder(
            itemCount: talkStore.conversations.length,
            itemBuilder: (context, index) {
              final conv = talkStore.conversations[index];
              final others = <String>[];
              for (var user in conv.partners) {
                others.add(user.name);
              }
              return ListTile(
                selected: !DeviceProxy.isMobile(context) && talkStore.currentConversation?.id == conv.id,
                onTap: () {
                  onTap(conv);
                },
                onLongPress: conv.isGroup
                    ? () async {
                        HapticFeedback.selectionClick();
                        final subject = await showPromptDialog(
                          context,
                          'Subject of the conversation',
                          label: 'Subject',
                          currentValue: conv.subject,
                        );
                        if (subject != null) {
                          showWaitingDialog(context, () => talkStore.setConversationOptions(conv, subject), onSuccess: onRefresh);
                        }
                      }
                    : null,
                leading: _getLeading(conv),
                title: Text(conv.subject ?? others.join(', ')),
                subtitle: conv.messages.isEmpty
                    ? null
                    : StreamBuilder(
                        stream: conv.onMessagesEvent,
                        builder: (context, snapshot) {
                          final message = conv.messages.last;
                          return Text(
                            message.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight:
                                    (message.senderId != talkStore.me.id && message.status != MessageStatus.seen) ? FontWeight.bold : FontWeight.normal),
                          );
                        },
                      ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _getLeading(Conversation conv) {
    if (conv.isOneToOne) {
      final partner = conv.partner;
      return getAvatar(partner);
    } else {
      if (conv.avatar == null) {
        return CircleAvatar(child: Center(child: Icon(Icons.group)));
      } else {
        return CircleAvatar(
          backgroundImage: NetworkImage(conv.avatar),
          backgroundColor: Colors.transparent,
        );
      }
    }
  }
}

class _StartFloatFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const _StartFloatFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Compute the x-axis offset.
    final double fabX = _startOffset(scaffoldGeometry);

    // Compute the y-axis offset.
    final double contentBottom = scaffoldGeometry.contentBottom;
    final double bottomSheetHeight = scaffoldGeometry.bottomSheetSize.height;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final double snackBarHeight = scaffoldGeometry.snackBarSize.height;

    double fabY = contentBottom - fabHeight - kFloatingActionButtonMargin;
    if (snackBarHeight > 0.0) fabY = math.min(fabY, contentBottom - snackBarHeight - fabHeight - kFloatingActionButtonMargin);
    if (bottomSheetHeight > 0.0) fabY = math.min(fabY, contentBottom - bottomSheetHeight - fabHeight / 2.0);

    return Offset(fabX, fabY);
  }

  @override
  String toString() => 'FloatingActionButtonLocation.startFloat';
}

double _leftOffset(ScaffoldPrelayoutGeometry scaffoldGeometry, {double offset = 0.0}) {
  return kFloatingActionButtonMargin + scaffoldGeometry.minInsets.left - offset;
}

double _rightOffset(ScaffoldPrelayoutGeometry scaffoldGeometry, {double offset = 0.0}) {
  return scaffoldGeometry.scaffoldSize.width -
      kFloatingActionButtonMargin -
      scaffoldGeometry.minInsets.right -
      scaffoldGeometry.floatingActionButtonSize.width +
      offset;
}

double _startOffset(ScaffoldPrelayoutGeometry scaffoldGeometry, {double offset = 0.0}) {
  assert(scaffoldGeometry.textDirection != null);
  switch (scaffoldGeometry.textDirection) {
    case TextDirection.rtl:
      return _rightOffset(scaffoldGeometry, offset: offset);
    case TextDirection.ltr:
      return _leftOffset(scaffoldGeometry, offset: offset);
  }
  return null;
}

mixin AvatarBuilder {
  Widget getAvatar(User user) {
    if (user.avatar == null) {
      return CircleAvatar(
        child: Text(user.name[0].toUpperCase()),
      );
    } else {
      return CircleAvatar(
        backgroundImage: NetworkImage(user.avatar),
        backgroundColor: Colors.transparent,
      );
    }
  }
}
