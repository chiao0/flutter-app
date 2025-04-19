import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'login_screen.dart';
import 'reg.dart';
import 'dart:io' show Platform;
import 'google_fit_data_screen.dart';  // 加入這行！

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (!kIsWeb) {
      if (Platform.isAndroid) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
        );
      } else if (Platform.isIOS) {
        await FirebaseAppCheck.instance.activate(
          appleProvider: AppleProvider.debug,
        );
      }
    }

    FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
      phoneNumber: "+16505551234",
      smsCode: "123456",
    );

    print("Firebase successfully initialized with App Check (if not Web)");
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '健康管理',
      theme: ThemeData(primarySwatch: Colors.blue),
      routes: {
        '/': (context) => const MyHomePage(),
        '/register': (context) => const RegistrationPage(),
        '/login': (context) => const LoginScreen(),
        '/google_fit_data': (context) => GoogleFitDataScreen(),  // 加入這行！
      },
    );
  }
}
