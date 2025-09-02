import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/core/config/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:provider/provider.dart';
import 'screens/flash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // if (!kIsWeb) {
  //   await TeXRenderingServer.start();
  // }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // try {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  // } catch (e) {
  //   debugPrint('Firebase initialization error: $e');
  // }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  final String latexContent = r"""
    To solve the integral \(\int_{0}^{1} x^2 \, dx\), we use the power rule: the antiderivative of \(x^2\) is \(\frac{x^3}{3}\). Evaluating from 0 to 1:
    \[
    \left. \frac{x^3}{3} \right|_0^1 = \frac{1^3}{3} - \frac{0^3}{3} = \frac{1}{3}.
    \]
    For the sum \(\sum_{i=1}^{n} i\), we use the formula \(\frac{n(n+1)}{2}\). The equation
    \[
    \begin{aligned}
    x + 1 &= 2 \\
    x &= 1
    \end{aligned}
    \]
    confirms \(x = 1\). Thus, the answer is \(\frac{1}{3} + \frac{n(n+1)}{2}\).
  """;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CET Verse',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: const FlashScreen()),
      //home: TeXViewQuizExample()),
    );
  }
}
