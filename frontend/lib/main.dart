import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_constants.dart';
import 'services/api_service.dart';
import 'services/firebase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/route_provider.dart';
import 'providers/sos_provider.dart';
import 'providers/journey_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initializeIfPossible();
  runApp(const SafeHerAIApp());
}

class SafeHerAIApp extends StatelessWidget {
  const SafeHerAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService(baseUrl: AppConstants.defaultApiUrl);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => RouteProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => SOSProvider(apiService: apiService)),
        ChangeNotifierProvider(create: (_) => JourneyProvider(apiService: apiService)),
      ],
      child: MaterialApp(
        title: 'SafeHer AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.accent,
            surface: AppColors.surface,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          fontFamily: 'Roboto',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
