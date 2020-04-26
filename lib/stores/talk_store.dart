import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:dalk/remote_config/remote_config_interface.dart';
import 'package:dalk_sdk/sdk.dart';
import 'package:mobx/mobx.dart';

part 'talk_store.g.dart';

class TalkStore = _TalkStore with _$TalkStore;

abstract class _TalkStore with Store {
  DalkSdk _talkSdk;
  @observable
  User me;
  @observable
  ObservableList<User> users = ObservableList.of([]);
  @observable
  ObservableList<User> selectedUsersForGroup = ObservableList.of([]);
  @observable
  ObservableList<Conversation> conversations;
  @observable
  Conversation currentConversation;
  StreamSubscription _firestoreSubscription;

  @action
  void selectUserForGroup(User user) {
    if (selectedUsersForGroup.contains(user)) {
      selectedUsersForGroup.remove(user);
    } else {
      selectedUsersForGroup.add(user);
    }
  }

  @action
  Future<void> createGroupConversation() async {
    currentConversation = await _talkSdk.createGroupConversation(selectedUsersForGroup);
    selectedUsersForGroup.clear();
  }

  @action
  Future<void> setConversationOptions(Conversation conversation, String subject) async {
    await conversation.setOptions(subject: subject);
  }

  @action
  Future<void> setMessageAsSeen(String messageId) async {
    await currentConversation.setMessageAsSeen(messageId);
  }

  @action
  Future<void> setup(String id, String name, String avatar) async {
    me = User(id: id, name: name ?? 'User$id', avatar: avatar);
    await _talkSdk?.disconnect();

    final remoteConfig = await FirebaseRemoteConfigPlatformInterface.getInstance();
    if (remoteConfig != null) {
      await remoteConfig.fetch(expiration: Duration(seconds: 10));
      await remoteConfig.activateFetched();

      final secret = remoteConfig.getString('projectSecret');
      final _signature = sha512.convert(utf8.encode('$id$secret')).toString();

      if (secret == null) {
        throw Exception('remote config not setup');
      }

      _talkSdk = DalkSdk(remoteConfig.getString('projectId'), me, signature: _signature);

      users.add(me);
      _talkSdk.newConversation.listen((conversation) {
        if (conversations == null) {
          conversations = ObservableList.of([conversation]);
        } else if (conversations.firstWhere((conv) => conv.id == conversation.id, orElse: () => null) == null) {
          conversations.add(conversation);
        }
      });
      _firestoreSubscription = Firestore.instance.collection('users').snapshots().listen(
        (data) {
          users.clear();
          users.addAll(data.documents.map((user) {
            return User(id: user['id'], name: user['name'], avatar: user['avatar']);
          }));
        },
        onError: print
      );
      await _talkSdk.connect();
    }
  }

  @action
  Future<void> logout() async {
    await _talkSdk.disconnect();
    me = null;
    conversations.clear();
    currentConversation = null;
  }

  @action
  Future<void> loadConversations() async {
    conversations = ObservableList.of(await _talkSdk?.getConversations() ?? []);
  }

  @action
  Future<void> createConversation(User user) async {
    currentConversation = await _talkSdk.createOneToOneConversation(user);
    conversations.add(currentConversation);
  }

  @action
  Future<void> loadConversation(String convId) async {
    final conv = await _talkSdk.getConversation(convId);
    await conv?.loadMessages(); //currentConversation may be null if it doesn't exist backend side
    currentConversation = conv;
  }

  void dispose() {
    _firestoreSubscription.cancel();
  }
}
