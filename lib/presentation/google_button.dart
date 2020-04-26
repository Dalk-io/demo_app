
import 'package:flutter/material.dart';
import 'package:sleek_spacing/sleek_spacing.dart';

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GoogleLoginButton({Key key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      onPressed: onPressed,
      color: Theme.of(context).primaryColor,
      padding: EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(4),
            width: 35,
            height: 35,
            child: Image.asset('assets/google.png'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SleekSpacing.of(context).normal),
            child: Text(
              'Sign-in with Google'.toUpperCase(),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

}
