import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:mokshayani/screens/auth_screen.dart';
import 'package:mokshayani/screens/chat_screen.dart';
import 'package:mokshayani/screens/discover_screen.dart';
import 'package:mokshayani/screens/library_screen.dart';
import 'package:mokshayani/screens/corpus_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mokshayani Enterprise Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const ChatbotUI(),
        '/discover': (context) => const DiscoverScreen(),
        '/library': (context) => const LibraryScreen(),
        '/corpus': (context) => const CorpusScreen(),
      },
    );
  }
}
