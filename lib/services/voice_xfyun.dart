import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:permission_handler/permission_handler.dart';

/// 讯飞语音识别服务（Web API 版本）
///
/// 使用讯飞 WebAPI 接口，无需集成原生 SDK。
///
/// 配置步骤：
/// 1. 注册讯飞开放平台账号: https://www.xfyun.cn/
/// 2. 创建应用，选择"语音听写（流式版）"服务
/// 3. 获取 APPID、APISecret、APIKey 填入下方
///
/// 免费额度：新用户 50000 次/天
class XfyunVoiceService {
  // ===================== 在这里填入你的讯飞配置 =====================
  // 注册地址: https://www.xfyun.cn/
  // 创建应用后获取以下三个值
  static const String _appId = 'xxx';
  static const String _apiKey = 'xxx';
  static const String _apiSecret = 'xxx';
  // ================================================================

  static final XfyunVoiceService _instance = XfyunVoiceService._();
  factory XfyunVoiceService() => _instance;
  XfyunVoiceService._();

  bool _isAvailable = false;
  bool _isListening = false;
  bool _permissionGranted = false;
  bool _isConfigured = false;

  bool get isAvailable => _isAvailable && _isConfigured;
  bool get isListening => _isListening;
  bool get permissionGranted => _permissionGranted;

  /// 检查是否已配置
  bool get _hasConfig =>
      _appId != 'xxx' && _apiKey != 'xxx' && _apiSecret != 'xxx';

  /// 初始化
  Future<bool> preInit() async {
    debugPrint('🎤 讯飞语音初始化...');

    _isConfigured = _hasConfig;
    if (!_isConfigured) {
      debugPrint('⚠️ 讯飞语音未配置，请在 voice_xfyun.dart 中填写 APPID/APIKey/APISecret');
      _isAvailable = false;
      return false;
    }

    _permissionGranted = await _checkPermission();
    if (!_permissionGranted) {
      debugPrint('🎤 麦克风权限未授予');
    }

    _isAvailable = true;
    debugPrint(
        '🎤 讯飞语音初始化完成, available=$_isAvailable, permission=$_permissionGranted');
    return _isAvailable;
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

  /// 开始录音并识别
  Future<void> startListening({
    required Function(String) onResult,
    VoidCallback? onListeningStateChanged,
  }) async {
    if (!_isConfigured) {
      debugPrint('⚠️ 讯飞未配置');
      return;
    }
    if (!_permissionGranted) {
      final granted = await requestMicrophonePermission();
      if (!granted) return;
    }
    if (_isListening) return;

    _isListening = true;
    debugPrint('🎤 开始讯飞语音识别...');

    try {
      // 录音并识别
      final result = await _recordAndRecognize(onResult);
      debugPrint('🎤 识别完成: $result');
    } catch (e) {
      debugPrint('🎤 识别异常: $e');
    } finally {
      _isListening = false;
      onListeningStateChanged?.call();
    }
  }

  /// 录音并调用讯飞 API 识别
  Future<String> _recordAndRecognize(Function(String) onResult) async {
    // 讯飞 WebAPI 需要 WebSocket 连接
    // 这里使用简化版本：录音 -> 上传 -> 获取结果

    final wsUrl = _buildWsUrl();
    debugPrint('🎤 WebSocket URL: $wsUrl');

    final socket = await WebSocket.connect(wsUrl);
    final buffer = <int>[];
    String finalResult = '';

    socket.listen((message) {
      final data = jsonDecode(message);
      final code = data['code'];

      if (code == 0) {
        final status = data['status']; // 0: 继续, 1: 结束, 2: 错误
        final result = data['data']?['result']?['ws'] as List?;

        if (result != null) {
          String text = '';
          for (final ws in result) {
            for (final cw in (ws['cw'] as List)) {
              text += cw['w'] as String;
            }
          }
          finalResult = text;
          onResult(text);
        }

        if (status == 2) {
          socket.close();
        }
      } else {
        debugPrint('🎤 讯飞返回错误: $code - ${data['message']}');
        socket.close();
      }
    });

    // 发送开始帧
    final startFrame = jsonEncode({
      'common': {'app_id': _appId},
      'business': {
        'language': 'zh_cn',
        'domain': 'iat',
        'accent': 'mandarin',
        'vad_eos': 2000, // 静音检测时长 ms
        'dwa': 'wpgs', // 动态修正
      },
      'data': {
        'status': 0, // 0: 首帧, 1: 中间帧, 2: 尾帧
        'format': 'audio/L16;rate=16000',
        'encoding': 'raw',
        'audio': '',
      },
    });
    socket.add(startFrame);

    // TODO: 这里需要实际录音并发送音频数据
    // 由于 Flutter 录音需要额外插件，这里先返回空
    // 完整实现需要配合 flutter_sound 或 record 插件

    await Future.delayed(const Duration(seconds: 5)); // 模拟等待
    socket.close();

    return finalResult;
  }

  /// 构建讯飞 WebSocket URL
  String _buildWsUrl() {
    final host = 'iat-api.xfyun.cn';
    final path = '/v2/iat';
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final signatureOrigin = 'host: $host\npath: $path\nmethod: GET\n';
    final signature = Hmac(sha256, utf8.encode(_apiSecret))
        .convert(utf8.encode(signatureOrigin))
        .toString();

    final authorizationOrigin =
        'api_key="$_apiKey", algorithm="hmac-sha256", headers="host date request-line", '
        'signature="$signature"';
    final authorization = base64.encode(utf8.encode(authorizationOrigin));

    final params = 'authorization=$authorization&date=$now&host=$host';
    final url = 'wss://$host$path?$params';

    return url;
  }

  Future<void> stopListening() async {
    _isListening = false;
  }

  Future<void> cancelListening() async {
    _isListening = false;
  }
}
