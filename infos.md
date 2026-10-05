import 'dart:async';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scrole/modules/module_authentification/centre/services/auth_service.dart';
import 'package:scrole/app/service_global/theme_service.dart';
import 'package:scrole/modules/module_creation_de_compte/centre/services/user_service.dart';
import 'package:scrole/app/repository_global/location_repository.dart';
import 'package:scrole/app/repository_global/centre_interets_repository.dart';
import 'package:scrole/app/service_global/language_service.dart';
import 'package:scrole/app/service_global/notification_service.dart';
import 'package:scrole/app/service_global/app_config_service.dart';
import 'package:scrole/app/service_global/connectivity_service.dart';
import 'package:scrole/app/service_global/device_service.dart';
import 'package:scrole/app/service_global/media_service.dart';
import 'package:scrole/app/service_global/currency_service.dart';
import 'package:scrole/app/service_global/preferences_service.dart';
import 'package:scrole/app/service_global/privacy_service.dart';
import 'package:scrole/app/service_global/session_service.dart';
import 'package:scrole/app/service_global/supabse_service.dart';
import 'package:scrole/app/service_global/sync_service.dart';
import 'package:scrole/app/service_global/centre_interrets_service.dart';
import 'package:scrole/app_controller.dart';
import 'package:scrole/app/local_storage/fast/fast_cache_service.dart';
import 'package:scrole/app/local_storage/structured/app_cache_database.dart';
import 'package:scrole/app/routes/app_pages.dart';
import 'package:scrole/app/routes/app_routes.dart';
import 'package:scrole/app/theme/app_theme.dart';
import 'package:scrole/app/translation/scrole_translations.dart';
import 'modules/module_activite/centre/services/activity_service.dart';
import 'package:scrole/modules/module_appareils/interne/controllers/device_controller.dart';
import 'package:scrole/modules/module_authentification/interne/controllers/auth_controller.dart';
import 'package:scrole/modules/module_communautes/centre/services/community_service.dart';
import 'package:scrole/modules/module_communautes/externe/repositories/community_repository.dart';
import 'package:scrole/modules/module_notification/centre/services/notification_db_service.dart';
import 'package:scrole/modules/module_discussion_direct/centre/repositories/messaging_repository.dart';
import 'package:scrole/modules/module_discussion_direct/externe/services/supabase_messaging_service.dart';
import 'package:scrole/modules/module_discussion_direct/externe/services/fcm_notification_service.dart';
import 'package:scrole/modules/module_discussion_direct/centre/services/chat_service.dart';

void main() {
WidgetsFlutterBinding.ensureInitialized();
PlatformDispatcher.instance.onError = (error, stack) {
if (error.toString().contains('bad_code_verifier') ||
error.toString().contains('code challenge does not match')) {
if (kDebugMode) {
print('[SupabaseAuth] Code PKCE deeplink expiré ou invalide intercepté avec succès.');
}
return true;
}
return false;
};
if (kIsWeb) {
FlutterError.onError = (FlutterErrorDetails details) {
final error = details.exceptionAsString();
final errorsToIgnore = [
'_handledContextLostEvent',
'Noto fonts',
'widget has been unmounted',
'setBreakpoints',
'getWindowWidth',
'CanvasKit',
'context lost',
'FrameService',
];
if (errorsToIgnore.any((e) => error.contains(e))) return;
FlutterError.dumpErrorToConsole(details);
};
}
_initApp();
}

Future<void> _initApp() async {
try {
await Firebase.initializeApp();
await Supabase.initialize(
url: 'https://djvmxrwfchnqdtzayhwf.supabase.co',
anonKey: 'sb_publishable_gMk5EZPgW1eoEPN1kU0cKA_aXXGBUNJ',
realtimeClientOptions: const RealtimeClientOptions(
timeout: Duration(seconds: 20),
),
);
final supabaseService = SupabaseService();
await supabaseService.init();
Get.put(supabaseService);
Get.put(AppDatabase(), permanent: true);
await Get.putAsync<FastCacheService>(() => FastCacheService().init());
Get.put(CurrencyService(), permanent: true);
await Future.wait([
Get.putAsync<ConnectivityService>(() => ConnectivityService().init()),
Get.putAsync<AppConfigService>(() => AppConfigService().init()),
Get.putAsync<PreferencesService>(() => PreferencesService().init()),
Get.putAsync<PrivacyService>(() => PrivacyService().init()),
Get.putAsync<SyncService>(() => SyncService().init()),
]);
Get.put(DeviceService());
Get.put(MediaService());
await Future.wait([
Get.putAsync(() => ThemeService().init()),
Get.putAsync(() => LocaleService().init()),
]);
Get.put<LocationRepository>(
CachedLocationRepository(
SupabaseLocationRepository(Supabase.instance.client),
Get.find<FastCacheService>(),
),
);
Get.put(InterestRepository(Supabase.instance.client), permanent: true);
Get.put(InterestService(Get.find<InterestRepository>()), permanent: true);
Get.put(AuthService());
Get.put(UserService());
Get.put(SessionService());
Get.put(AppController(), permanent: true);
Get.put(AuthController(), permanent: true);
Get.put(DeviceController(), permanent: true);
Get.put(ActivityService());
final messagingRemote = SupabaseMessagingService(Supabase.instance.client);
final messagingRepository = MessagingRepository(
Get.find<AppDatabase>(),
messagingRemote,
);
Get.put<SupabaseMessagingService>(messagingRemote, permanent: true);
Get.put<MessagingRepository>(messagingRepository, permanent: true);
Get.put<ChatService>(ChatService(messagingRepository), permanent: true);
await messagingRepository.initialize();
Get.put<FcmNotificationService>(
FcmNotificationService(messagingRepository),
permanent: true,
);
unawaited(Get.find<FcmNotificationService>().initialize());
Get.put(CommunityRepository(Supabase.instance.client));
Get.put(
CommunityService(
Get.find<CommunityRepository>(),
Get.find<AppDatabase>(),
),
permanent: true,
);
Get.put(NotificationDbService(Get.find<AppDatabase>()));
await NotificationService.instance.initialize(
onNotificationTap: (response) {
debugPrint('Notification tapée, payload: ${response.payload}');
},
);
runApp(DevicePreview(enabled: false, builder: (context) => const MyApp()));
} catch (e, stackTrace) {
print('[Error] Erreur d\'initialisation: $e');
print(stackTrace);
}
}

class MyApp extends StatelessWidget {
const MyApp({super.key});
@override
Widget build(BuildContext context) {
final localeService = Get.find<LocaleService>();
return Obx(
() => GetMaterialApp(
title: 'Scrole',
debugShowCheckedModeBanner: false,
theme: AppTheme.lightTheme,
darkTheme: AppTheme.darkTheme,
themeMode: Get.find<ThemeService>().themeMode,
translations: ScroleTranslations(),
locale: localeService.locale,
fallbackLocale: const Locale('en'),
localizationsDelegates: const [
GlobalMaterialLocalizations.delegate,
GlobalWidgetsLocalizations.delegate,
GlobalCupertinoLocalizations.delegate,
],
supportedLocales: const [
Locale('fr'),
Locale('en'),
Locale('es'),
Locale('de'),
Locale('it'),
Locale('pt'),
Locale('zh'),
Locale('ja'),
Locale('ru'),
],
initialRoute: AppPages.root,
getPages: AppRoutes.routes,
builder: (context, child) {
return DevicePreview.appBuilder(
context,
ResponsiveBreakpoints.builder(
breakpoints: [
const Breakpoint(start: 0, end: 559, name: MOBILE),
const Breakpoint(start: 560, end: 1050, name: TABLET),
const Breakpoint(
start: 1051,
end: double.infinity,
name: DESKTOP,
),
],
child: child!,
),
);
},
),
);
}
}
