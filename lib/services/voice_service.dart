import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// 语音识别服务
///
/// 优先使用讯飞，未配置时回退到系统语音。
/// 
/// 讯飞配置（可选）：
/// 1. 注册 https://www.xfyun.cn/
/// 2. 创建应用，获取 APPID
/// 3. 下载讯飞语音 SDK 并集成（需要原生开发）
///
/// 当前版本：使用系统语音引擎
/// - 国内手机（小米/华为/OPPO等）通常自带中文语音引擎
/// - 如无法识别，请检查手机是否安装了语音输入法
class VoiceService {
  static final VoiceService _instance = VoiceService._();
  factory VoiceService() => _instance;
  VoiceService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  bool _isInitializing = false;
  bool _permissionGranted = false;
  String _localeId = 'zh_CN';

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  bool get permissionGranted => _permissionGranted;

  /// 初始化
  Future<bool> preInit() async {
    debugPrint('🎤 语音服务初始化...');

    _permissionGranted = await _checkPermission();

    if (_isAvailable) return true;
    if (_isInitializing) {
      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!_isInitializing) break;
      }
      return _isAvailable;
    }

    _isInitializing = true;
    try {
      _isAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('🎤 语音错误: ${error.errorMsg}');
          _isListening = false;
          if (error.permanent) _isAvailable = false;
        },
        onStatus: (status) {
          debugPrint('🎤 语音状态: $status');
          if (status == 'done' || status == 'notListening' || status == 'error') {
            _isListening = false;
          }
        },
      );
      debugPrint('🎤 初始化结果: $_isAvailable');

      if (_isAvailable) {
        final locales = await _speech.locales();
        debugPrint('🎤 可用语言: ${locales.map((l) => l.localeId).take(10).toList()}');

        // 选择最佳中文语言
        _localeId = _selectBestLocale(locales);
        debugPrint('🎤 使用语言: $_localeId');
      }
    } catch (e) {
      debugPrint('🎤 初始化异常: $e');
      _isAvailable = false;
    } finally {
      _isInitializing = false;
    }
    return _isAvailable;
  }

  /// 选择最佳语音语言
  String _selectBestLocale(List<stt.LocaleName> locales) {
    // 优先级: zh_CN > zh_TW > zh-* > 第一个
    if (locales.any((l) => l.localeId == 'zh_CN')) return 'zh_CN';
    if (locales.any((l) => l.localeId == 'zh_TW')) return 'zh_TW';
    
    final zhLocale = locales.where((l) => l.localeId.startsWith('zh_')).firstOrNull;
    if (zhLocale != null) return zhLocale.localeId;
    
    // 检查是否有中文相关的（有些手机用 cmn-Hans-CN 等格式）
    final cmnLocale = locales.where((l) => 
      l.localeId.contains('zh') || 
      l.localeId.contains('cmn') ||
      l.localeId.contains('hans')
    ).firstOrNull;
    if (cmnLocale != null) return cmnLocale.localeId;
    
    return locales.isNotEmpty ? locales.first.localeId : 'zh_CN';
  }

  Future<bool> init() async => await preInit();

  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      _permissionGranted = true;
      return true;
    }
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      _permissionGranted = result.isGranted;
      return result.isGranted;
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return false;
  }

  /// 开始监听
  Future<void> startListening({
    required Function(String) onResult,
    VoidCallback? onListeningStateChanged,
  }) async {
    if (!_permissionGranted || !_isAvailable) return;
    if (_isListening) return;

    _isListening = true;

    try {
      await _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          debugPrint('🎤 识别: "$text" (final=${result.finalResult})');
          
          if (result.finalResult) {
            _isListening = false;
            onListeningStateChanged?.call();
          }
          if (text.isNotEmpty) {
            onResult(text);
          }
        },
        localeId: _localeId,
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
      );
      debugPrint('🎤 开始监听 (locale=$_localeId)');
    } catch (e) {
      debugPrint('🎤 监听失败: $e');
      _isListening = false;
      onListeningStateChanged?.call();
    }
  }

  /// 停止监听
  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('🎤 停止失败: $e');
    } finally {
      _isListening = false;
    }
  }

  /// 取消监听
  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
    } catch (e) {
      debugPrint('🎤 取消失败: $e');
    } finally {
      _isListening = false;
    }
  }
}