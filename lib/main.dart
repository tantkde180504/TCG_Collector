import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/catalog_viewmodel.dart';
import 'viewmodels/cart_viewmodel.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'views/login_screen.dart';
import 'views/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => CatalogViewModel()),
        ChangeNotifierProvider(create: (_) => CartViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
      ],
      child: MaterialApp(
        title: 'Pokémon TCG Collector',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          primaryColor: Colors.amber,
          colorScheme: const ColorScheme.dark(
            primary: Colors.amber,
            secondary: Colors.redAccent,
            surface: Color(0xFF1E1E1E),
            background: Color(0xFF121212),
            error: Colors.redAccent,
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFF1E1E1E),
            disabledColor: Colors.grey.shade800,
            selectedColor: Colors.amber,
            secondarySelectedColor: Colors.amber,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            labelStyle: const TextStyle(color: Colors.white),
            secondaryLabelStyle: const TextStyle(color: Colors.black),
            brightness: Brightness.dark,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    
    if (authVM.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }
    
    return authVM.isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}
