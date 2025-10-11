import 'package:flutter/material.dart';
import 'wallet.dart';

// Yatırım modeli
class Yatirim {
  final String tur;
  final String adi;
  final double miktar;

  Yatirim({required this.tur, required this.adi, required this.miktar});
}

// Global yatırım listesi
List<Yatirim> globalYatirimlar = [];

class Add extends StatefulWidget {
  const Add({super.key});

  @override
  State<Add> createState() => _AddState();
}

class _AddState extends State<Add> {
  String? selectedTur;
  String? selectedAdi;
  String? selectedAdi2;
  String? selectedAdi3;
  String? miktar;

  final List<String> turList = ['Hisse', 'Altın', 'Kripto'];
  final List<String> coinList = ['BTC', 'ETH', 'XRP'];
  final List<String> altinList = ['Gram', 'Çeyrek', 'Tam', "Cumhuriyet"];
  final List<String> hisseList = ['Ebebek', 'BIENY', 'BIGCH'];

  @override
  Widget build(BuildContext context) {
    bool yatirimAdiSecildi = (selectedTur == 'Kripto' && selectedAdi != null) ||
        (selectedTur == 'Altın' && selectedAdi2 != null) ||
        (selectedTur == 'Hisse' && selectedAdi3 != null);

    bool ekleAktif = selectedTur != null &&
        yatirimAdiSecildi &&
        miktar != null &&
        miktar!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F1F1),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Yatırım Ekle',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WalletPage(yatirimlar: globalYatirimlar),
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Yatırım Türü', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ...turList.map((tur) => CheckboxListTile(
                    title: Text(tur),
                    value: selectedTur == tur,
                    onChanged: (val) {
                      setState(() {
                        selectedTur = val! ? tur : null;
                        selectedAdi = null;
                        selectedAdi2 = null;
                        selectedAdi3 = null;
                        miktar = null;
                      });
                    },
                  )),
              if (selectedTur == 'Kripto') ...[
                const SizedBox(height: 16),
                const Text('Yatırım Adı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ...coinList.map((adi) => CheckboxListTile(
                      title: Text(adi),
                      value: selectedAdi == adi,
                      onChanged: (val) {
                        setState(() {
                          selectedAdi = val! ? adi : null;
                          miktar = null;
                        });
                      },
                    )),
              ],
              if (selectedTur == 'Altın') ...[
                const SizedBox(height: 16),
                const Text('Yatırım Adı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ...altinList.map((adi) => CheckboxListTile(
                      title: Text(adi),
                      value: selectedAdi2 == adi,
                      onChanged: (val) {
                        setState(() {
                          selectedAdi2 = val! ? adi : null;
                          miktar = null;
                        });
                      },
                    )),
              ],
              if (selectedTur == 'Hisse') ...[
                const SizedBox(height: 16),
                const Text('Yatırım Adı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ...hisseList.map((adi) => CheckboxListTile(
                      title: Text(adi),
                      value: selectedAdi3 == adi,
                      onChanged: (val) {
                        setState(() {
                          selectedAdi3 = val! ? adi : null;
                          miktar = null;
                        });
                      },
                    )),
              ],
              if (yatirimAdiSecildi) ...[
                const SizedBox(height: 16),
                const Text('Miktar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Miktar giriniz',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    setState(() {
                      miktar = val;
                    });
                  },
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: ekleAktif
                    ? () {
                        String yatirimAdiSecilen = selectedAdi ?? selectedAdi2 ?? selectedAdi3 ?? '';
                        String temizMiktar = miktar!.replaceAll(',', '.');
                        double miktarDouble = double.tryParse(temizMiktar) ?? 0.0;

                        globalYatirimlar.add(Yatirim(
                          tur: selectedTur!,
                          adi: yatirimAdiSecilen,
                          miktar: miktarDouble,
                        ));

                        setState(() {
                          selectedTur = null;
                          selectedAdi = null;
                          selectedAdi2 = null;
                          selectedAdi3 = null;
                          miktar = null;
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ekleAktif ? Colors.white : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: ekleAktif ? 2 : 0,
                ),
                child: const Text(
                  'Ekle',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
