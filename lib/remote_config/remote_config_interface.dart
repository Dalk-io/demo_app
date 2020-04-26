import 'dart:async';

import 'package:dalk/remote_config/io/types/remote_config_value.dart';
import 'package:dalk/remote_config/remote_config.dart';

abstract class FirebaseRemoteConfigPlatformInterface {
  static FirebaseRemoteConfigPlatformInterface _instance;
  static FutureOr<FirebaseRemoteConfigPlatformInterface> getInstance() async {
    if (_instance == null)
      _instance = await getRemoteConfig();
    return _instance;
  }

  bool getBool(String key);

  double getDouble(String key);

  int getInt(String key);

  String getString(String key);

  PlatformRemoteConfigValue getValue(String key);

  Map<String, PlatformRemoteConfigValue> getAll();

  Future<bool> activateFetched();

  Future<void> fetch({Duration expiration: const Duration(hours: 12)});

  DateTime get lastFetchTime;

  LastFetchStatus get lastFetchStatus;
}
