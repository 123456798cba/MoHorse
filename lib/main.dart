import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'database/database.dart';
import 'providers/app_data_provider.dart';
import 'screens/splash_screen.dart';
import 'services/password_service.dart';
import 'services/voice_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化中文日期格式
  await initializeDateFormatting('zh_CN', null);

  // 初始化默认密码
  await PasswordService.initDefaultPassword();

  // 预初始化语音服务，减少首次使用延迟
  await VoiceService().preInit();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final database = AppDatabase();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppDataProvider(database),
      child: const MoHorseApp(),
    ),
  );
}

class MoHorseApp extends StatelessWidget {
  const MoHorseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoHorse清单',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C63FF),
        brightness: Brightness.light,
        fontFamily: 'PingFang SC',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C63FF),
        brightness: Brightness.dark,
        fontFamily: 'PingFang SC',
      ),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
      home: const SplashScreen(),
    );
  }
}
