import 'package:flutter/material.dart';

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
  String? ondalikSecim;

  final List<String> turList = ['Hisse', 'Altın', 'Kripto'];
  final List<String> coinList = ['BTC', 'ETH', 'XRP'];
  final List<String> altinList = ['Gram', 'Çeyrek', 'Tam', "Cumhuriyet"];
  final List<String> hisseList = ['Ebebek', 'BIENY', 'BIGCH'];
 

  final List<String> ondalikList = ['Virgül', 'Nokta'];

  @override
  Widget build(BuildContext context) {
    bool ekleAktif =
        selectedTur != null &&
        selectedAdi != null &&
        miktar != null &&
        miktar!.isNotEmpty &&
        ondalikSecim != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F1F1),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Yatırım Ekle',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Yatırım Türü',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ...turList.map(
                (tur) => CheckboxListTile(
                  title: Text(tur),
                  value: selectedTur == tur,

                  onChanged: (val) {
                    setState(() {
                      selectedTur = val! ? tur : null;
                      selectedAdi = null;
                      selectedAdi2 = null;
                      selectedAdi3 = null;
                      miktar = null;
                      ondalikSecim = null;
                    });
                  },
                ),
              ),
              if (selectedTur == 'Kripto') ...[
                const SizedBox(height: 16),
                const Text(
                  'Yatırım Adı',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ...coinList.map(
                  (adi) => CheckboxListTile(
                    title: Text(adi),
                    value: selectedAdi == adi,
                    onChanged: (val) {
                      setState(() {
                        selectedAdi = val! ? adi : null;
                        miktar = null;
                        ondalikSecim = null;
                      });
                    },
                  ),
                ),
              ],
              if (selectedTur == 'Altın' ) ...[
                const SizedBox(height: 16),
                const Text(
                  'Yatırım Adı',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ...altinList.map(
                  (adi) => CheckboxListTile(
                    title: Text(adi),
                    value: selectedAdi2 == adi,
                    onChanged: (val) {
                      setState(() {
                        selectedAdi2 = val! ? adi : null;
                        miktar = null;
                        ondalikSecim = null;
                      });
                    },
                  ),
                ),
              ],
              if (selectedTur == 'Hisse') ...[
                const SizedBox(height: 16),
                const Text(
                  'Yatırım Adı',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ...hisseList.map(
                  (adi) => CheckboxListTile(
                    title: Text(adi),
                    value: selectedAdi3 == adi,
                    onChanged: (val) {
                      setState(() {
                        selectedAdi3 = val! ? adi : null;
                        miktar = null;
                        ondalikSecim = null;
                      });
                    },
                  ),
                ),
              ],

              if ((selectedAdi != null) ||
                  (selectedAdi2 != null) ||
                  (selectedAdi3 != null)) ...[
                const SizedBox(height: 16),
                const Text(
                  'Miktar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
              if (miktar != null && miktar!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Ondalık Seçimi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: ondalikSecim,
                  hint: const Text('Seçiniz'),
                  items:
                      ondalikList
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      ondalikSecim = val;
                    });
                  },
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: ekleAktif ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ekleAktif ? Colors.white : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: ekleAktif ? 2 : 0,
                ),
                child: const Text(
                  'Ekle',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
