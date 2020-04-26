import 'package:dalk/presentation/conversations_route.dart';
import 'package:dalk/presentation/dialogs.dart';
import 'package:dalk/stores/talk_store.dart';
import 'package:dalk_sdk/sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:sleek_spacing/sleek_spacing.dart';

class UserSearchDelegate extends SearchDelegate<User> {
  final TalkStore talkStore;

  UserSearchDelegate(this.talkStore);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.of(context)?.pop();
      },
      icon: Icon(Icons.close),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _UserSearchResult(query, talkStore);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(child: _UserSearchResult(query, talkStore)),
        Text('Use long press to create a group conversation', style: TextStyle(fontStyle: FontStyle.italic)),
        SleekPadding.small(),
      ],
    );
  }
}

class _UserSearchResult extends StatelessWidget with AvatarBuilder {
  final TalkStore talkStore;
  final String query;

  _UserSearchResult(this.query, this.talkStore);

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final users = talkStore.users.where((user) => user.id != talkStore.me.id && user.name.toLowerCase().startsWith(query.toLowerCase())).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Observer(
                    builder: (context) => ListTile(
                      onTap: () {
                        Navigator.of(context)?.pop(user);
                      },
                      onLongPress: () {
                        HapticFeedback.selectionClick();
                        talkStore.selectUserForGroup(user);
                      },
                      leading: getAvatar(user),
                      title: Text(user.name),
                      trailing: talkStore.selectedUsersForGroup.contains(user)
                          ? Icon(
                              Icons.check_circle_outline,
                              color: Theme.of(context).primaryColor,
                            )
                          : null,
                    ),
                  );
                },
                itemCount: users.length,
                separatorBuilder: (BuildContext context, int index) => Divider(height: 1),
              ),
            ),
            if (talkStore.selectedUsersForGroup.length > 1)
              SleekPadding(
                padding: SleekInsets.normal(),
                child: RaisedButton(
                  color: Theme.of(context).primaryColor,
                  onPressed: () {
                    showWaitingDialog(context, () => talkStore.createGroupConversation(), onSuccess: () {
                      Navigator.of(context)?.pop();
                    });
                  },
                  child: Text('Create group conversation'.toUpperCase(), style: TextStyle(color: Colors.white)),
                ),
              ),
          ],
        );
      },
    );
  }
}
