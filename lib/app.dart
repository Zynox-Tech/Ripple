import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/theme.dart';
import 'config/app_config.dart';
import 'config/routes.dart';
import 'config/l10n/app_localizations.dart';

class RippleApp extends ConsumerWidget {
  const RippleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch App states (Locale, ThemeMode)
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Ripple',
      debugShowCheckedModeBanner: false,
      
      // Routing Configurations
      routerConfig: appRouter,
      
      // Theme settings
      themeMode: themeMode,
      theme: RippleTheme.themeData(context, false),
      darkTheme: RippleTheme.themeData(context, true),
      
      // Localization settings
      locale: locale,
      supportedLocales: const [
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
