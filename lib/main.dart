import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

import 'app_controller.dart';
import 'sync_service.dart';
import 'ui/home_shell.dart';
import 'pixel_icons.dart';
import 'ui_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1280, 840),
      minimumSize: Size(980, 700),
      center: true,
      backgroundColor: Color(0xFFF7FAF7),
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  try {
    await WorkScheduler.initialize();
  } catch (e) {
    debugPrint('WorkManager init failed: $e');
  }
  final controller = AppController();
  try {
    await controller.initialize();
  } catch (e, st) {
    debugPrint('AppController init failed: $e\n$st');
  }
  runApp(HsuApp(controller: controller));
}

class HsuApp extends StatelessWidget {
  final AppController controller;
  const HsuApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightDynamic, darkDynamic) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          AppIconStyle.pixel = controller.settings.iconStyle == 'pixel';
          final mode = switch (controller.settings.theme) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          };
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: '课程表',
            theme: HsuTheme.build(HsuTheme.lightScheme(lightDynamic, controller.settings.palette), fontStyle: controller.settings.fontStyle),
            darkTheme: HsuTheme.build(HsuTheme.darkScheme(darkDynamic, controller.settings.palette), fontStyle: controller.settings.fontStyle),
            themeMode: mode,
            locale: const Locale('zh', 'CN'),
            supportedLocales: [Locale('zh', 'CN'), Locale('en', 'US')],
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(textScaler: TextScaler.linear(1.15)),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: HomeShell(controller: controller),
          );
        },
      );
    });
  }
}
