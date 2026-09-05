import 'dart:io';
import 'package:dio/dio.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String? apkUrl;
  final String? releaseNotes;
  final bool isForceUpdate;
  const UpdateInfo({required this.currentVersion, required this.latestVersion, this.apkUrl, this.releaseNotes, this.isForceUpdate = false});
  bool get hasUpdate => _compare(latestVersion, currentVersion) > 0;
  static int _compare(String a, String b) {
    List<int> pa = a.replaceAll(RegExp(r'[^0-9.]'), '').split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> pb = b.replaceAll(RegExp(r'[^0-9.]'), '').split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      int av = i < pa.length ? pa[i] : 0;
      int bv = i < pb.length ? pb[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }
}

class UpdateService {
  static const String githubRepo = 'YOUR_GITHUB_USERNAME/campussetu';
  static const String githubApi = 'https://api.github.com/repos/YOUR_GITHUB_USERNAME/campussetu/releases/latest';
  static const String fallbackVersionUrl = 'https://campussetu-backend.onrender.com/health';

  static final Dio _dio = Dio();

  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final current = await getCurrentVersion();
      final currentShort = current.split('+').first;

      // 1. Try Play Store InAppUpdate
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          return UpdateInfo(currentVersion: currentShort, latestVersion: 'PlayStore', apkUrl: null, releaseNotes: 'Update available on Play Store');
        }
      } catch (_) {}

      // 2. Try GitHub releases
      try {
        final res = await _dio.get(githubApi, options: Options(headers: {'Accept': 'application/vnd.github.v3+json'}));
        if (res.statusCode == 200 && res.data is Map) {
          final tag = (res.data['tag_name'] ?? '').toString().replaceAll('v', '');
          final notes = (res.data['body'] ?? '').toString();
          String? apkUrl;
          final assets = res.data['assets'] as List?;
          if (assets != null) {
            for (final a in assets) {
              final name = (a['name'] ?? '').toString();
              if (name.endsWith('.apk')) { apkUrl = a['browser_download_url']?.toString(); break; }
            }
            apkUrl ??= assets.isNotEmpty ? assets.first['browser_download_url']?.toString() : null;
          }
          apkUrl ??= 'https://github.com/$githubRepo/releases/latest/download/app-release.apk';
          final info = UpdateInfo(currentVersion: currentShort, latestVersion: tag.isEmpty ? currentShort : tag, apkUrl: apkUrl, releaseNotes: notes);
          if (info.hasUpdate) return info;
        }
      } catch (e) { if (kDebugMode) debugPrint('GH check failed $e'); }

      // 3. Fallback: backend health version
      try {
        final res = await _dio.get(fallbackVersionUrl);
        if (res.statusCode == 200 && res.data is Map && res.data['version'] != null) {
          final tag = res.data['version'].toString();
          final apk = res.data['apkUrl']?.toString();
          final info = UpdateInfo(currentVersion: currentShort, latestVersion: tag, apkUrl: apk, releaseNotes: res.data['notes']?.toString());
          if (info.hasUpdate) return info;
        }
      } catch (_) {}

      return null;
    } catch (_) { return null; }
  }

  static Future<bool> performPlayStoreUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
          return true;
        } else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
          return true;
        }
      }
    } catch (e) { if (kDebugMode) debugPrint('Play update failed $e'); }
    return false;
  }

  static Future<String> downloadApk(String apkUrl, {void Function(int received, int total)? onProgress}) async {
    if (Platform.isIOS) throw Exception('iOS sideload not supported');
    if (await Permission.requestInstallPackages.isDenied) {
      await Permission.requestInstallPackages.request();
    }
    final dir = await getTemporaryDirectory();
    final savePath = '${dir.path}/campussetu_update.apk';
    await _dio.download(apkUrl, savePath, onReceiveProgress: onProgress, options: Options(followRedirects: true));
    return savePath;
  }

  static Future<void> installApk(String path) async {
    final result = await OpenFilex.open(path);
    if (kDebugMode) debugPrint('OpenFile result $result');
    if (result.type != ResultType.done) throw Exception('Install failed: ${result.message}');
  }

  static Future<bool> updateViaGithub(UpdateInfo info, {void Function(int, int)? onProgress}) async {
    if (info.apkUrl == null) throw Exception('No APK url');
    final path = await downloadApk(info.apkUrl!, onProgress: onProgress);
    await installApk(path);
    return true;
  }
}
