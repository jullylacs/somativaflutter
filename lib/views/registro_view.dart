import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailField = TextEditingController();
  final TextEditingController _senhaField = TextEditingController();
  final TextEditingController _confirmarSenhaField = TextEditingController();
  bool _ocultarSenha = true;
  bool _ocultarConfSenha = true;
  bool _carregando = false;

  Future<void> _registrar() async {
    if (_emailField.text.isEmpty ||
        _senhaField.text.isEmpty ||
        _confirmarSenhaField.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos.")),
      );
      return;
    }

    if (_senhaField.text != _confirmarSenhaField.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("As senhas não coincidem.")),
      );
      return;
    }

    setState(() => _carregando = true);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailField.text.trim(),
        password: _senhaField.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuário criado com sucesso!")),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String mensagem = "Erro ao criar usuário.";
      if (e.code == 'email-already-in-use') {
        mensagem = "Esse email já está em uso.";
      } else if (e.code == 'invalid-email') {
        mensagem = "Email inválido.";
      } else if (e.code == 'weak-password') {
        mensagem = "Senha muito fraca. Use ao menos 6 caracteres.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text("Registrar Novo Usuário"),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade600,
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
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_alt_1,
                      color: Colors.indigo.shade600, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    "Crie sua conta",
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
                          setState(() => _ocultarSenha = !_ocultarSenha);
                        },
                        icon: Icon(_ocultarSenha
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: _ocultarSenha,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmarSenhaField,
                    decoration: InputDecoration(
                      labelText: "Confirmar Senha",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _ocultarConfSenha = !_ocultarConfSenha);
                        },
                        icon: Icon(_ocultarConfSenha
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: _ocultarConfSenha,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _carregando ? null : _registrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _carregando
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : const Text(
                              "Registrar",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Voltar para o login"),
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
