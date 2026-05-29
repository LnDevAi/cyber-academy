import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/l10n/language_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: CyberAcademyApp(),
    ),
  );
}

class CyberAcademyApp extends ConsumerStatefulWidget {
  const CyberAcademyApp({super.key});

  @override
  ConsumerState<CyberAcademyApp> createState() => _CyberAcademyAppState();
}

class _CyberAcademyAppState extends ConsumerState<CyberAcademyApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(languageProvider.notifier).init());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'Cyber Academy E-DÉFENCE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: locale,
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
