import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class HistoricoView extends StatelessWidget {
  const HistoricoView({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final pontos = FirebaseFirestore.instance
        .collection('pontos')
        .where('uid', isEqualTo: uid)
        .orderBy('data', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Pontos'),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade600,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: pontos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum registro encontrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i]['data'] as Timestamp;
              final tipo = (docs[i]['tipo'] ?? '').toString();
              final distancia = (docs[i]['distancia'] as num?)?.toStringAsFixed(1) ?? '0.0';

              final dataFormatada = DateFormat('dd/MM/yyyy • HH:mm').format(data.toDate());

              final isEntrada = tipo.toLowerCase() == 'entrada';
              final cor = isEntrada ? Colors.green.shade600 : Colors.red.shade600;
              final icone = isEntrada ? LucideIcons.logIn : LucideIcons.logOut;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: cor.withOpacity(0.15),
                    child: Icon(icone, color: cor, size: 24),
                  ),
                  title: Text(
                    tipo.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cor,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dataFormatada,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Distância: $distancia m',
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
