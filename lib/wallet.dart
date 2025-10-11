import 'package:flutter/material.dart';
import 'add.dart'; // Yatirim modelini buradan alıyoruz

class WalletPage extends StatelessWidget {
  final List<Yatirim> yatirimlar;

  const WalletPage({super.key, required this.yatirimlar});
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        title: const Text('Yatırımlarım'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF1F1F1),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: yatirimlar.isEmpty
          ? const Center(
              child: Text(
                'Henüz yatırım eklenmedi.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: yatirimlar.length,
              itemBuilder: (context, index) {
                final yatirim = yatirimlar[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.black,
                          child: Text(
                            yatirim.tur[0],
                            style: const TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                yatirim.adi,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tür: ${yatirim.tur}',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${yatirim.miktar.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}