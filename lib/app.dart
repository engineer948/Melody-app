import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody/core/config/app_config.dart';
import 'package:melody/core/router/app_router.dart';
import 'package:melody/core/settings/locale_controller.dart';
import 'package:melody/core/settings/theme_controller.dart';
import 'package:melody/core/theme/app_theme.dart';
import 'package:melody/core/theme/system_colors.dart';
import 'package:melody/features/social/social_controller.dart';
import 'package:melody/features/social/social_home.dart';
import 'package:melody/features/tailnet/tailnet_controller.dart';
import 'package:melody/l10n/l10n.dart';

/// Root widget: wires routing, theming and localization together.
class MelodyApp extends ConsumerStatefulWidget {
  /// Creates the app.
  const MelodyApp({super.key});

  @override
  ConsumerState<MelodyApp> createState() => _MelodyAppState();
}

class _MelodyAppState extends ConsumerState<MelodyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The engine outlives the Android activity (background playback). When
  /// the system recreates the activity, it no longer knows that Flutter wants
  /// the back gesture, and back would leave the app instead of going back.
  /// Telling it again on resume fixes that.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Back in the app: reconnect Tailscale if it dropped meanwhile.
    unawaited(ref.read(tailnetControllerProvider.notifier).ensureConnected());
    final canPop = ref.read(appRouterProvider).canPop();
    unawaited(SystemNavigator.setFrameworkHandlesBack(canPop));
  }

  @override
  Widget build(BuildContext context) {
    final own = ref.watch(themeControllerProvider);
    // A color someone chose for this user (only if they allowed it).
    final accent = socialAccent(ref.watch(socialControllerProvider));
    final settings = accent == null
        ? own
        : own.copyWith(accent: accent, useSystemColors: false);
    final systemSeed = ref.watch(systemSeedColorProvider).value;
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(appRouterProvider),
      theme: AppTheme.light(settings, systemSeed: systemSeed),
      darkTheme: AppTheme.dark(settings, systemSeed: systemSeed),
      themeMode: settings.themeMode,
      locale: ref.watch(localeControllerProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
