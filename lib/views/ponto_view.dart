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
    _inicializar();
  }

  Future<void> _inicializar() async {
    await _verificarPermissoesLocalizacao();
    await _buscarUltimoRegistro();
  }

  /// 🔹 Verifica e solicita permissão de localização ao abrir o app
  Future<void> _verificarPermissoesLocalizacao() async {
    try {
      final servicoHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicoHabilitado) {
        _mostrarMensagem('Por favor, ative o serviço de localização.');
        return;
      }

      LocationPermission permissao = await Geolocator.checkPermission();

      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }

      if (permissao == LocationPermission.denied) {
        _mostrarMensagem('Permissão de localização negada.');
      } else if (permissao == LocationPermission.deniedForever) {
        _mostrarMensagem(
          'Permissão negada permanentemente. Vá nas configurações e ative manualmente.',
        );
      }
    } catch (e) {
      _mostrarMensagem('Erro ao verificar permissões: $e');
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
        setState(() {
          _ultimoTipo = snapshot.docs.first['tipo'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar último registro: $e');
      _mostrarMensagem('Erro ao carregar último registro.');
    }
  }

  /// 🔹 Registra ponto de entrada ou saída
  Future<void> _baterPonto(String tipo) async {
    setState(() => _carregando = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _mostrarMensagem('Usuário não autenticado.');
        return;
      }

      final senhaValida = await _confirmarSenha();
      if (!senhaValida) return;

      final posicao = await _obterLocalizacaoAtual();
      if (posicao == null) return;

      const latTrabalho = -22.5600;
      const lonTrabalho = -47.4141;

      final distancia = Geolocator.distanceBetween(
        latTrabalho,
        lonTrabalho,
        posicao.latitude,
        posicao.longitude,
      );

      if (distancia > 100) {
        _mostrarMensagem('Você está fora do limite de 100 metros!');
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

      setState(() => _ultimoTipo = tipo);
      _mostrarMensagem('Ponto de $tipo registrado com sucesso!');
    } catch (e) {
      _mostrarMensagem('Erro ao registrar ponto: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  /// 🔹 Confirma senha antes de registrar ponto
  Future<bool> _confirmarSenha() async {
    final senhaController = TextEditingController();
    bool confirmado = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação de Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite sua senha para continuar.'),
            const SizedBox(height: 10),
            TextField(
              controller: senhaController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final cred = EmailAuthProvider.credential(
                  email: _auth.currentUser!.email!,
                  password: senhaController.text,
                );

                await _auth.currentUser!.reauthenticateWithCredential(cred);
                confirmado = true;

                await _solicitarLocalizacaoPosConfirmacao();
                Navigator.pop(context);
              } catch (_) {
                _mostrarMensagem('Senha incorreta, tente novamente.');
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    return confirmado;
  }

  /// 🔹 Solicita autorização de localização após confirmar senha
  Future<void> _solicitarLocalizacaoPosConfirmacao() async {
    try {
      bool servicoHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicoHabilitado) {
        _mostrarMensagem('Ative o serviço de localização.');
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
          'Permissão negada permanentemente. Vá nas configurações do dispositivo.',
        );
        return;
      }

      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _mostrarMensagem('Localização autorizada com sucesso!');
    } catch (e) {
      _mostrarMensagem('Erro ao solicitar localização: $e');
    }
  }

  /// 🔹 Obtém localização atual com tratamento de erro
  Future<Position?> _obterLocalizacaoAtual() async {
    try {
      final permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        _mostrarMensagem('Permissão de localização não concedida.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    } catch (e) {
      _mostrarMensagem('Erro ao obter localização: $e');
      return null;
    }
  }

  /// 🔹 Mostra mensagens amigáveis na tela
  void _mostrarMensagem(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
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
      ),
    );
  }
}
