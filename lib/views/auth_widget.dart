import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sa_somativa/views/login_view.dart';
import 'package:sa_somativa/views/ponto_view.dart';

class AuthWidget extends StatelessWidget {
  const AuthWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 🔹 Estado de carregamento (aguardando Firebase responder)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Carregando...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // 🔹 Caso de erro inesperado
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Ocorreu um erro. Tente novamente mais tarde.',
                style: TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            ),
          );
        }

        // 🔹 Usuário autenticado → tela principal
        if (snapshot.hasData && snapshot.data != null) {
          return const PontoView();
        }

        // 🔹 Usuário não autenticado → tela de login
        return const LoginView();
      },
    );
  }
}
