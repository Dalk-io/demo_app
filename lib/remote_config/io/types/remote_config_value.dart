
enum ValueSource { valueStatic, valueDefault, valueRemote }

enum LastFetchStatus { success, failure, throttled, noFetchYet }

class PlatformRemoteConfigValue {
  final String Function() asString;
  final int Function() asInt;
  final double Function() asDouble;
  final bool Function() asBool;
  final ValueSource Function() getSource;
  PlatformRemoteConfigValue({
    this.asBool,
    this.asDouble,
    this.asInt,
    this.asString,
    this.getSource,
  });
}
