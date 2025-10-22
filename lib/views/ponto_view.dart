import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'historico_view.dart';

class PontoView extends StatefulWidget {
  const PontoView({super.key});

  @override
  State<PontoView> createState() => _PontoViewState();
}

class _PontoViewState extends State<PontoView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _carregando = false;
  String? _ultimoTipo;

  @override
  void initState() {
    super.initState();
    _verificarPermissoesLocalizacao();
    _buscarUltimoRegistro();
  }

  /// 🔹 Verifica e solicita permissão de localização ao abrir o app
  Future<void> _verificarPermissoesLocalizacao() async {
    bool servicoHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicoHabilitado) {
      _mostrarMensagem('Por favor, ative o serviço de localização.');
      return;
    }

    LocationPermission permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        _mostrarMensagem('Permissão de localização negada.');
        return;
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      _mostrarMensagem(
        'Permissão de localização negada permanentemente. Vá nas configurações e ative manualmente.',
      );
    }
  }

  /// 🔹 Busca o último ponto batido (entrada/saída)
  Future<void> _buscarUltimoRegistro() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _db
          .collection('pontos')
          .where('uid', isEqualTo: user.uid)
          .orderBy('data', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _ultimoTipo = snapshot.docs.first['tipo'] as String?;
        setState(() {});
      }
    } catch (e) {
      debugPrint('Erro ao buscar último registro: $e');
    }
  }

  /// 🔹 Registra ponto de entrada ou saída
  Future<void> _baterPonto(String tipo) async {
    setState(() => _carregando = true);

    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _carregando = false);
      return;
    }

    final senhaValida = await _confirmarSenha();
    if (!senhaValida) {
      setState(() => _carregando = false);
      return;
    }

    bool servicoHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicoHabilitado) {
      _mostrarMensagem('Ative o serviço de localização!');
      setState(() => _carregando = false);
      return;
    }

    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        _mostrarMensagem('Permissão de localização negada!');
        setState(() => _carregando = false);
        return;
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      _mostrarMensagem('Permissão de localização permanentemente negada!');
      setState(() => _carregando = false);
      return;
    }

    final posicao = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    const latTrabalho = -22.571053;
    const lonTrabalho = -47.403930;

    final distancia = Geolocator.distanceBetween(
      latTrabalho,
      lonTrabalho,
      posicao.latitude,
      posicao.longitude,
    );

    if (distancia > 100) {
      _mostrarMensagem('Você está fora do limite de 100 metros!');
      setState(() => _carregando = false);
      return;
    }

    await _db.collection('pontos').add({
      'uid': user.uid,
      'data': Timestamp.now(),
      'tipo': tipo,
      'latitude': posicao.latitude,
      'longitude': posicao.longitude,
      'distancia': distancia,
    });

    _mostrarMensagem('Ponto de $tipo registrado com sucesso!');
    _ultimoTipo = tipo;

    setState(() => _carregando = false);
  }

  /// 🔹 Confirma senha antes de registrar ponto
  Future<bool> _confirmarSenha() async {
    final senhaController = TextEditingController();
    bool confirmado = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Senha'),
        content: TextField(
          controller: senhaController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Senha',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final cred = EmailAuthProvider.credential(
                  email: _auth.currentUser!.email!,
                  password: senhaController.text,
                );
                await _auth.currentUser!.reauthenticateWithCredential(cred);
                confirmado = true;
                Navigator.pop(context);
              } catch (_) {
                _mostrarMensagem('Senha incorreta.');
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return confirmado;
  }

  /// 🔹 Mostra mensagens simples na tela
  void _mostrarMensagem(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final podeEntrar = _ultimoTipo == 'saida' || _ultimoTipo == null;
    final podeSair = _ultimoTipo == 'entrada';

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text('Registro de Ponto'),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade600,
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Center(
        child: _carregando
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time_filled,
                        color: Colors.indigo.shade700, size: 80),
                    const SizedBox(height: 16),
                    Text(
                      'Bem-vindo(a), ${_auth.currentUser?.email ?? 'Usuário'}',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed:
                          podeEntrar ? () => _baterPonto('entrada') : null,
                      icon: const Icon(Icons.login),
                      label: const Text('Registrar Entrada'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: podeSair ? () => _baterPonto('saida') : null,
                      icon: const Icon(Icons.logout),
                      label: const Text('Registrar Saída'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoricoView(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('Ver Histórico'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: BorderSide(color: Colors.indigo.shade600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
