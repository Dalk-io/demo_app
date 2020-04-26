import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

Future<void> showErrorDialog(BuildContext context, String message, {String title}) {
  return showDialog(
    context: context,
    builder: (context) => ErrorDialog(
      title: title,
      message: message,
    ),
  );
}

Future<String> showPromptDialog(
  BuildContext context,
  String title, {
  String label,
  String currentValue,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return HookBuilder(
        builder: (context) {
          final controller = useTextEditingController();
          useEffect(() {
            controller.text = currentValue ?? '';
            return null;
          }, const []);
          return AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(labelText: label),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop(controller.text);
                },
                child: Text('Submit'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<bool> showConfirmDialog(BuildContext context, String title, String message) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text('No'),
        ),
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text('Yes'),
        ),
      ],
    ),
  );
}

Future<void> showWaitingDialog(
  BuildContext context,
  Future Function() until, {
  String title,
  String message,
  VoidCallback onSuccess,
  void Function(dynamic error, StackTrace stack) onFailure,
}) {
  return showDialog(
    context: context,
    builder: (context) => HookBuilder(
      builder: (context) {
        useEffect(() {
          until().then((_) {
            Navigator.of(context)?.pop();
            if (onSuccess != null) {
              onSuccess();
            }
          }).catchError((ex, stack) {
            Navigator.of(context)?.pop();
            if (onFailure == null) {
              print(ex);
              print(stack);
              showErrorDialog(context, ex.toString());
            } else {
              onFailure(ex, stack);
            }
          });
          return null;
        }, const []);
        return WaitingDialog(
          title: title,
          message: message,
        );
      },
    ),
  );
}

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;

  const ErrorDialog({Key key, this.title, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? 'Ooops'),
      content: Text(message, style: TextStyle(color: Theme.of(context).errorColor)),
    );
  }
}

class WaitingDialog extends StatelessWidget {
  final String title;
  final String message;

  const WaitingDialog({Key key, this.title, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(title ?? 'Loading'),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(message ?? 'Please wait')),
            Center(child: CircularProgressIndicator()),
          ],
        )
      ],
    );
  }
}
