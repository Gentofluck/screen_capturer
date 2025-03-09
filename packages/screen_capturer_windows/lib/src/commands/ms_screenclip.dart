import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:screen_capturer_platform_interface/screen_capturer_platform_interface.dart';
import 'package:win32/win32.dart';

final Map<CaptureMode, String> _knownCaptureModeArgs = {
  CaptureMode.region: 'Rectangle',
  CaptureMode.screen: '',
  CaptureMode.window: 'Window',
};

bool _isScreenClipping() {
  final int hWnd = GetForegroundWindow();
  final lpdwProcessId = calloc<Uint32>();

  GetWindowThreadProcessId(hWnd, lpdwProcessId);
  // Get a handle to the process.
  final hProcess = OpenProcess(
    PROCESS_ACCESS_RIGHTS.PROCESS_QUERY_INFORMATION |
        PROCESS_ACCESS_RIGHTS.PROCESS_VM_READ,
    FALSE,
    lpdwProcessId.value,
  );

  if (hProcess == 0) {
    return false;
  }

  // Get a list of all the modules in this process.
  final hModules = calloc<HMODULE>(1024);
  final cbNeeded = calloc<DWORD>();

  try {
    int r = EnumProcessModules(
      hProcess,
      hModules,
      sizeOf<HMODULE>() * 1024,
      cbNeeded,
    );

    if (r == 1) {
      for (var i = 0; i < (cbNeeded.value ~/ sizeOf<HMODULE>()); i++) {
        final szModName = wsalloc(MAX_PATH);
        // Get the full path to the module's file.
        final hModule = (hModules + i).value;
        if (GetModuleFileNameEx(hProcess, hModule, szModName, MAX_PATH) != 0) {
          String moduleName = szModName.toDartString();
          if (moduleName.contains('ScreenClippingHost.exe') ||
              moduleName.contains('SnippingTool.exe')) {
            free(szModName);
            return true;
          }
        }
        free(szModName);
      }
    }
  } finally {
    free(hModules);
    free(cbNeeded);
    CloseHandle(hProcess);
  }

  return false;
}
class _MsScreenclip with SystemScreenCapturer {
  static const MethodChannel _channel = MethodChannel('dev.leanflutter.plugins/screen_capturer');

  @override
  Future<void> capture({
    required CaptureMode mode,
    String? imagePath,
    bool copyToClipboard = true,
    bool silent = true,
  }) async {
    
    await ScreenCapturerPlatform.instance.captureScreen(
      imagePath: imagePath,
    );

    /*
    String url = 'ms-screenclip://?';
    if (mode == CaptureMode.screen) {
      url += 'type=snapshot';
    } else {
      url += 'clippingMode=${_knownCaptureModeArgs[mode]}';
    }
    await Clipboard.setData(const ClipboardData(text: ''));
    ShellExecute(
      0,
      'open'.toNativeUtf16(),
      url.toNativeUtf16(),
      nullptr,
      nullptr,
      SHOW_WINDOW_CMD.SW_SHOWNORMAL,
    );*/
    await Future.delayed(const Duration(seconds: 1));

      // Вызов нативного метода через MethodChannel
      final result = await _channel.invokeMethod('captureScreen', args);

      // Обработка результата (если нужно)
      print('Capture result: $result');
    } on PlatformException catch (e) {
      print("Failed to capture screen: '${e.message}'.");
    }
  }
}

final msScreenclip = _MsScreenclip();
