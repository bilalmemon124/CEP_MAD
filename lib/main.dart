import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:share_x/screens/home_screen.dart';
import 'package:share_x/screens/login_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShareX',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<User?>(
        future: _auth.authStateChanges().first, // Check the initial user state
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // Show loading indicator while checking
          } else {
            final User? user = snapshot.data;
            if (user != null) {
              // User is signed in, navigate to the home screen
              return const HomeScreen();
            } else {
              // User is not signed in, navigate to the login screen
              return const LoginScreen();
            }
          }
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
