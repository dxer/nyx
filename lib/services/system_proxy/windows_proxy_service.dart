import 'dart:io';

class WindowsProxyService {
  static const String _regKey = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings';

  /// Enables Windows system-wide proxy pointing to local mixed inbound (127.0.0.1:2080)
  static Future<bool> enableSystemProxy({String host = '127.0.0.1', int port = 2080}) async {
    if (!Platform.isWindows) return true;

    try {
      final proxyServer = '$host:$port';
      // 1. Enable proxy
      await Process.run('reg', [
        'add',
        _regKey,
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '1',
        '/f',
      ]);

      // 2. Set proxy address
      await Process.run('reg', [
        'add',
        _regKey,
        '/v',
        'ProxyServer',
        '/t',
        'REG_SZ',
        '/d',
        proxyServer,
        '/f',
      ]);

      // 3. Bypass local intranet addresses
      await Process.run('reg', [
        'add',
        _regKey,
        '/v',
        'ProxyOverride',
        '/t',
        'REG_SZ',
        '/d',
        '<local>;localhost;127.*;10.*;172.16.*;192.168.*',
        '/f',
      ]);

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Disables Windows system-wide proxy
  static Future<bool> disableSystemProxy() async {
    if (!Platform.isWindows) return true;

    try {
      await Process.run('reg', [
        'add',
        _regKey,
        '/v',
        'ProxyEnable',
        '/t',
        'REG_DWORD',
        '/d',
        '0',
        '/f',
      ]);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sets or removes Windows startup registry entry
  static Future<bool> setLaunchOnStartup(bool enable) async {
    if (!Platform.isWindows) return true;

    try {
      const runKey = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
      final exePath = Platform.resolvedExecutable;

      if (enable) {
        await Process.run('reg', [
          'add',
          runKey,
          '/v',
          'Nyx',
          '/t',
          'REG_SZ',
          '/d',
          '"$exePath"',
          '/f',
        ]);
      } else {
        await Process.run('reg', [
          'delete',
          runKey,
          '/v',
          'Nyx',
          '/f',
        ]);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
