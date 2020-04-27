# demo_app

This is a demo application of [dalk.io](https://dalk.io) SDK use under a Flutter application, it will show you how to build a real time chat application.

To run this demo, you'll need to set up firebase as we're using it to :

- manage our project credentials on firebase remote config to not have secret hard coded in the app
- manage user session with firebase auth and google sign in
- manage user database with cloud firestore 

To set up firebase please follow their [documentation](https://pub.dev/packages/firebase_auth).

You'll need to set up Android, iOS and Web platforms. 
Meaning a `ios/GoogleService-Info.plist`, `android/app/google-services.json` and info on `web/index.html` are mandatory in order to run.  

To know more about Dalk.io SDK, don't hesitate to check our [online documentation](https://dalk.io/doc/api/).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
