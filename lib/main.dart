import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/diagnosis_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/garden_provider.dart';
import 'providers/shop_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/legal/legal_screen.dart';
import 'services/notification_service.dart';

void main() async {
  // Wrap in runZonedGuarded to catch all unhandled exceptions in production
  await runZonedGuarded<Future<void>>(
    () async {
      // Ensure Flutter engine is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Set preferred device orientations to portrait-only for clean camera scaling
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Transparent system chrome for edge-to-edge layout
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      runApp(const PlantCareApp());

      // Request notification permissions after the first frame & configure tap handler
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationService().requestPermissions();
        NotificationService.onNotificationTap = (plantId, type) {
          debugPrint('🔔 Notification tapped in app shell: plantId=$plantId, type=$type');
        };
      });
    },
    (error, stackTrace) {
      // Global error handler — logs uncaught errors in debug; in production,
      // replace this block with a crash reporting SDK (e.g. Firebase Crashlytics):
      // FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
      if (kDebugMode) {
        debugPrint('🔴 [FATAL] Unhandled exception: $error');
        debugPrint(stackTrace.toString());
      }
    },
  );
}

class PlantCareApp extends StatelessWidget {
  const PlantCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DiagnosisProvider>(
          create: (_) => DiagnosisProvider(),
        ),
        ChangeNotifierProvider<GardenProvider>(
          create: (_) => GardenProvider(),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(),
        ),
        ChangeNotifierProvider<ShopProvider>(
          create: (_) => ShopProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'PlantCare AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final clampedScaler = mediaQuery.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.15);
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: clampedScaler),
            child: child!,
          );
        },
        home: const SplashScreen(),
        routes: {
          '/privacy-policy': (ctx) => const LegalScreen(isPrivacyPolicy: true),
          '/terms-of-service': (ctx) => const LegalScreen(isPrivacyPolicy: false),
        },
      ),
    );
  }
}
