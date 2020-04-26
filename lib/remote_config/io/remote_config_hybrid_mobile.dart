
import 'package:dalk/remote_config/io/types/remote_config_value.dart';
import 'package:dalk/remote_config/remote_config_interface.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart' as core;

Future<FirebaseRemoteConfigPlatformInterface> getRemoteConfig() async {
  return FirebaseRemoteConfigMobile._(await core.RemoteConfig.instance);
}

class FirebaseRemoteConfigMobile extends FirebaseRemoteConfigPlatformInterface {
  FirebaseRemoteConfigMobile._(core.RemoteConfig platformInstance)
      : _instance = platformInstance;
  core.RemoteConfig _instance;

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
    return _instance?.getBool(key);
  }

  @override
  double getDouble(String key) {
    return _instance?.getDouble(key);
  }

  @override
  int getInt(String key) {
    return _instance?.getInt(key);
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
    return await _instance?.activateFetched();
  }

  @override
  Future<void> fetch({Duration expiration: const Duration(hours: 12)}) async {
    await _instance?.fetch(expiration: expiration);
  }

  @override
  DateTime get lastFetchTime => _instance?.lastFetchTime;

  @override
  LastFetchStatus get lastFetchStatus =>
      _statusFromCore(_instance?.lastFetchStatus);

  PlatformRemoteConfigValue _coreConfigValueToPlugin(
      core.RemoteConfigValue coreValue) {
    return coreValue == null
        ? null
        : PlatformRemoteConfigValue(
            asBool: coreValue.asBool,
            asDouble: coreValue.asDouble,
            asInt: coreValue.asInt,
            asString: coreValue.asString,
            getSource: () => _valueSourceFromCore(coreValue.source),
          );
  }

  LastFetchStatus _statusFromCore(core.LastFetchStatus status) {
    switch (status) {
      case core.LastFetchStatus.failure:
        return LastFetchStatus.failure;
      case core.LastFetchStatus.noFetchYet:
        return LastFetchStatus.noFetchYet;
      case core.LastFetchStatus.success:
        return LastFetchStatus.success;
      case core.LastFetchStatus.throttled:
        return LastFetchStatus.throttled;
      default:
        return null;
    }
  }

  ValueSource _valueSourceFromCore(core.ValueSource source) {
    switch (source) {
      case core.ValueSource.valueDefault:
        return ValueSource.valueDefault;
      case core.ValueSource.valueRemote:
        return ValueSource.valueRemote;
      case core.ValueSource.valueStatic:
        return ValueSource.valueStatic;
      default:
        return null;
    }
  }
}
