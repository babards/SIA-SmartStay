import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/auth_service.dart';
import 'services/weather_service.dart';
import 'services/property_service.dart';
import 'services/notification_service.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/properties/add_property_screen.dart';
import 'screens/properties/manage_properties_screen.dart';
import 'screens/weather/weather_dashboard_screen.dart';
import 'screens/applications/application_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(SmartStayApp());
}

class SmartStayApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => WeatherService()),
        ChangeNotifierProvider(create: (_) => PropertyService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'SmartStay Bukidnon',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF2196F3)),
          primaryColor: Color(0xFF2196F3),
          scaffoldBackgroundColor: Color(0xFFF5F5F5),
          fontFamily: 'Roboto',
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF2196F3),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2196F3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        home: AuthWrapper(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/dashboard': (context) => DashboardScreen(),
          '/add-property': (context) => AddPropertyScreen(),
          '/manage-properties': (context) => ManagePropertiesScreen(),
          '/weather': (context) => WeatherDashboardScreen(),
          '/applications': (context) => ApplicationScreen(),
          '/profile': (context) => ProfileScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }

        if (snapshot.hasData) {
          return DashboardScreen();
        }

        return LoginScreen();
      },
    );
  }
}
