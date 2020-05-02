import 'package:dalk/presentation/conversations_route.dart';
import 'package:dalk/stores/dalk_store.dart';
import 'package:dalk_sdk/sdk.dart';
import 'package:dash_chat/dash_chat.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:sleek_spacing/sleek_spacing.dart';

final _timeFormat = DateFormat('HH:mm:ss');

class ChatScreen extends StatelessWidget with AvatarBuilder {
  static const route = '/chat';
  final bool headless;

  const ChatScreen({Key key, this.headless = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final talkStore = Provider.of<DalkStore>(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Observer(
          builder: (context) {
            final conv = talkStore.currentConversation;

            if (conv == null) {
              return Container();
            }

            return Scaffold(
              appBar: headless
                  ? null
                  : AppBar(
                      title: Text(conv == null
                          ? 'Loading'
                          : (conv.isOneToOne ? conv.partner.name : (conv.subject ?? conv.partners.map((user) => user.name).join(', ')))),
                    ),
              primary: !headless,
              body: StreamBuilder<void>(
                stream: conv.onMessagesEvent,
                builder: (context, snapshot) {
                  return DashChat(
                    inverted: false,
                    sendOnEnter: true,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    textInputAction: TextInputAction.send,
                    onSend: (text) => conv.sendMessage(message: text.text),
                    avatarBuilder: (chatUser) => getAvatar(User(id: chatUser.uid, name: chatUser.name, avatar: chatUser.avatar)),
                    user: ChatUser(uid: talkStore.me.id, name: talkStore.me.name),
                    messageTimeBuilder: (time, [message]) {
                      final chatMessage = message as DalkChatMessage;
                      return CustomChatMessage(message: chatMessage);
                    },
                    messages: conv.messages.map((message) {
                      final status = message.status;
                      return DalkChatMessage(
                        text: message.text,
                        createdAt: message.createdAt,
                        id: message.id,
                        formattedTime: _timeFormat.format(message.createdAt),
                        status: status,
                        user: _getChatUser(talkStore.users.firstWhere((user) => message.senderId == user.id)),
                      );
                    }).toList(growable: false),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  ChatUser _getChatUser(User user) {
    return ChatUser(uid: user.id, name: user.name, avatar: user.avatar);
  }
}

class CustomChatMessage extends HookWidget {
  final DalkChatMessage message;

  const CustomChatMessage({Key key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final talkStore = Provider.of<DalkStore>(context);
    useEffect(() {
      talkStore.setMessageAsSeen(message.id);
      return null;
    }, const []);

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(message.formattedTime, style: Theme.of(context).textTheme.caption),
          if (message.user.uid == talkStore.me.id) SleekPadding.extraSmall(),
          if (message.user.uid == talkStore.me.id)
            SizedBox(
              width: 10,
              height: 10,
              child: _getStatus(),
            )
        ],
      ),
    );
  }

  Widget _getStatus() {
    switch (message.status) {
      case MessageStatus.ongoing:
        return CircularProgressIndicator(backgroundColor: Colors.grey);
      case MessageStatus.sent:
        return Icon(Icons.done, color: Colors.black45, size: 15);
      case MessageStatus.received:
        return Icon(Icons.done_all, color: Colors.black45, size: 15);
      case MessageStatus.seen:
        return Icon(Icons.done_all, color: Colors.white, size: 15);
      case MessageStatus.error:
        return Icon(Icons.error_outline, color: Colors.redAccent, size: 15);
    }

    return Container();
  }
}

class DalkChatMessage extends ChatMessage {
  final MessageStatus status;
  final String formattedTime;

  DalkChatMessage({
    String id,
    @required String text,
    @required ChatUser user,
    String image,
    String video,
    DateTime createdAt,
    this.formattedTime,
    this.status,
  }) : super(
          id: id,
          text: text,
          user: user,
          image: image,
          video: video,
          createdAt: createdAt,
        );
}
