
import 'dart:async';

import 'package:dalk/remote_config/io/types/remote_config_value.dart';
import 'package:dalk/remote_config/remote_config_interface.dart';
import 'package:firebase/firebase.dart' as core;

Future<FirebaseRemoteConfigPlatformInterface> getRemoteConfig() async {
  return FirebaseRemoteConfigWeb._(core.remoteConfig());
}

class FirebaseRemoteConfigWeb extends FirebaseRemoteConfigPlatformInterface {
  core.RemoteConfig _instance;
  FirebaseRemoteConfigWeb._(core.RemoteConfig instance) : _instance = instance;

  @override
  Map<String, PlatformRemoteConfigValue> getAll() {
    Map<String, core.RemoteConfigValue> coreResult = _instance?.getAll();
    if (coreResult == null) return null;
    Map<String, PlatformRemoteConfigValue> pluginResult = {};
    for (String key in coreResult.keys) {
      pluginResult[key] = _coreConfigValueToPlugin(coreResult[key]);
    }
    return pluginResult;
  }

  @override
  bool getBool(String key) {
    return _instance?.getBoolean(key);
  }

  @override
  double getDouble(String key) {
    return _instance?.getNumber(key)?.toDouble();
  }

  @override
  int getInt(String key) {
    return _instance?.getNumber(key)?.toInt();
  }

  @override
  String getString(String key) {
    return _instance?.getString(key);
  }

  @override
  PlatformRemoteConfigValue getValue(String key) {
    return _coreConfigValueToPlugin(_instance?.getValue(key));
  }

  @override
  Future<bool> activateFetched() async {
    return await _instance?.activate();
  }

  @override
  Future<void> fetch({Duration expiration: const Duration(hours: 12)}) async {
    _instance?.settings?.minimumFetchInterval = expiration;
    await _instance?.fetch();
  }

  @override
  DateTime get lastFetchTime => _instance?.fetchTime;

  @override
  LastFetchStatus get lastFetchStatus =>
      _statusFromCore(_instance?.lastFetchStatus);

  PlatformRemoteConfigValue _coreConfigValueToPlugin(
      core.RemoteConfigValue coreValue) {
    return coreValue == null
        ? null
        : PlatformRemoteConfigValue(
            asBool: coreValue.asBoolean,
            asDouble: () => coreValue.asNumber().toDouble(),
            asInt: () => coreValue.asNumber().toInt(),
            asString: coreValue.asString,
            getSource: () => _valueSourceFromCore(coreValue.getSource()),
          );
  }

  LastFetchStatus _statusFromCore(core.RemoteConfigFetchStatus status) {
    switch (status) {
      case core.RemoteConfigFetchStatus.failure:
        return LastFetchStatus.failure;
      case core.RemoteConfigFetchStatus.notFetchedYet:
        return LastFetchStatus.noFetchYet;
      case core.RemoteConfigFetchStatus.success:
        return LastFetchStatus.success;
      case core.RemoteConfigFetchStatus.throttle:
        return LastFetchStatus.throttled;
      default:
        return null;
    }
  }

  ValueSource _valueSourceFromCore(core.RemoteConfigValueSource source) {
    switch (source) {
      case core.RemoteConfigValueSource.defaults:
        return ValueSource.valueDefault;
      case core.RemoteConfigValueSource.remote:
        return ValueSource.valueRemote;
      case core.RemoteConfigValueSource.static:
        return ValueSource.valueStatic;
      default:
        return null;
    }
  }
}
