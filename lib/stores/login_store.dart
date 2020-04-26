import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobx/mobx.dart';

part 'login_store.g.dart';

class LoginStore = _LoginStore with _$LoginStore;

abstract class _LoginStore with Store {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseUser firebaseUser;

  @action
  Future<void> login({silently = false}) async {
    var logged = await _googleSignIn.signInSilently();
    GoogleSignInAuthentication googleAuth = await logged?.authentication;

    if (logged == null) {
      if (silently) {
        throw Exception('Not logged');
      }
      final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Login canceled');
      }
      googleAuth = await googleUser.authentication;
    }

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    firebaseUser = (await _auth.signInWithCredential(credential)).user;
    print("signed in " + firebaseUser.displayName + " " + firebaseUser.uid);
    await Firestore.instance.collection('users').document(firebaseUser.uid).setData({
      'id': firebaseUser.uid,
      'name': firebaseUser.displayName ?? 'User${firebaseUser.uid}',
      'avatar': firebaseUser.photoUrl,
    });
  }

  @action
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
