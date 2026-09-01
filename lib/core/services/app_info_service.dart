import 'package:package_info_plus/package_info_plus.dart';

/// Version information for the installed application, read from the platform
/// (installed app) metadata rather than parsed from `pubspec.yaml` at runtime.
class AppInfo {
  const AppInfo({
    required this.appName,
    required this.packageName,
    required this.versionName,
    required this.buildNumber,
  });

  final String appName;
  final String packageName;

  /// Display version, e.g. `1.4.0`.
  final String versionName;

  /// Build number, e.g. `27`.
  final String buildNumber;

  /// A human-friendly combined label, e.g. `1.4.0 (Build 27)`.
  String get displayVersion => buildNumber.isEmpty
      ? versionName
      : '$versionName (Build $buildNumber)';
}

class AppInfoService {
  const AppInfoService();

  /// Reads the installed application's version metadata.
  Future<AppInfo> read() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    return AppInfo(
      appName: info.appName,
      packageName: info.packageName,
      versionName: info.version,
      buildNumber: info.buildNumber,
    );
  }
}
