import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sa_somativa/views/registro_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailField = TextEditingController();
  final TextEditingController _senhaField = TextEditingController();
  bool _invisivel = true;
  bool _loading = false;

  // Método de login
  Future<void> _login() async {
    if (_emailField.text.isEmpty || _senhaField.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, preencha todos os campos.")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailField.text.trim(),
        password: _senhaField.text,
      );
      // AuthWidget fará o redirecionamento automaticamente
    } on FirebaseAuthException catch (e) {
      String mensagem = "Erro ao fazer login.";
      if (e.code == 'user-not-found') {
        mensagem = "Usuário não encontrado.";
      } else if (e.code == 'wrong-password') {
        mensagem = "Senha incorreta.";
      } else if (e.code == 'invalid-email') {
        mensagem = "Email inválido.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade600,
        elevation: 4,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_filled,
                      color: Colors.indigo.shade600, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    "Registro de Ponto",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailField,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _senhaField,
                    decoration: InputDecoration(
                      labelText: "Senha",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _invisivel = !_invisivel;
                          });
                        },
                        icon: Icon(
                          _invisivel
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: _invisivel,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : const Text(
                              "Entrar",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegistroView()),
                      );
                    },
                    child: const Text("Não tem uma conta? Registre-se."),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
