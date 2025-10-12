import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'wallet.dart';

class Yatirim {
  final String tur;
  final String adi;
  final double miktar;
  final DateTime? alimTarihi;          
  final double? alimBirimFiyatiTry;    

  Yatirim({
    required this.tur,
    required this.adi,
    required this.miktar,
    this.alimTarihi,
    this.alimBirimFiyatiTry,
  });
}

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

  DateTime? alimTarihi; 

  final List<String> turList = ['Hisse', 'Altın', 'Kripto'];
  final List<String> altinList = ['Gram', 'Çeyrek', 'Tam', 'Cumhuriyet'];
  final List<String> hisseList = ['Ebebek', 'BIENY', 'BIGCH'];

  List<String> coinList = [];
  bool coinLoading = false;

  String coinQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchBinanceCoins();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchBinanceCoins() async {
    setState(() => coinLoading = true);
    final response =
        await http.get(Uri.parse('https://api.binance.com/api/v3/exchangeInfo'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final symbols = data['symbols'] as List;
      final coins = symbols
          .where((s) => s['quoteAsset'] == 'USDT' && s['status'] == 'TRADING')
          .map<String>((s) => s['baseAsset'] as String)
          .toSet()
          .toList()
        ..sort((a, b) => a.compareTo(b));
      setState(() {
        coinList = coins;
        coinLoading = false;
      });
    } else {
      setState(() => coinLoading = false);
    }
  }

  List<String> get filteredCoins {
    if (coinQuery.trim().isEmpty) return coinList;
    final q = coinQuery.toLowerCase();
    return coinList.where((c) => c.toLowerCase().contains(q)).toList();
  }

  void _onQueryChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => coinQuery = val);
    });
  }


  Future<double?> _binanceCloseOnDay({
    required String symbol, 
    required DateTime day,
  }) async {
    final start = DateTime.utc(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;

    final uri = Uri.parse(
        'https://api.binance.com/api/v3/klines?symbol=$symbol&interval=1d&startTime=$startMs&endTime=$endMs&limit=1');

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final arr = jsonDecode(res.body);
        if (arr is List && arr.isNotEmpty) {
          final k = arr[0] as List;
          final closeStr = k[4].toString(); 
          return double.tryParse(closeStr);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<double?> _cryptoUnitTryOn({
    required String baseAsset,  
    required DateTime day,
  }) async {
    final sym = '${baseAsset.toUpperCase()}USDT';
    final closeUsdt = await _binanceCloseOnDay(symbol: sym, day: day);
    if (closeUsdt == null) return null;

    final closeUsdtTry = await _binanceCloseOnDay(symbol: 'USDTTRY', day: day);
    if (closeUsdtTry == null || closeUsdtTry == 0) return null;

    return closeUsdt * closeUsdtTry;
  }


  @override
  Widget build(BuildContext context) {
    final bool yatirimAdiSecildi =
        (selectedTur == 'Kripto' && selectedAdi != null) ||
        (selectedTur == 'Altın' && selectedAdi2 != null) ||
        (selectedTur == 'Hisse' && selectedAdi3 != null);

    final bool ekleAktif = selectedTur != null &&
        yatirimAdiSecildi &&
        miktar != null &&
        miktar!.isNotEmpty;

    String _dateLabel(DateTime? d) {
      if (d == null) return 'Seçilmedi';
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final dd = d.day.toString().padLeft(2, '0');
      return '$dd.$m.$y';
    }

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
              const Text('Yatırım Türü',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...turList.map(
                (tur) => RadioListTile<String>(
                  title: Text(tur),
                  value: tur,
                  groupValue: selectedTur,
                  onChanged: (val) {
                    setState(() {
                      selectedTur = val;
                      selectedAdi = null;
                      selectedAdi2 = null;
                      selectedAdi3 = null;
                      miktar = null;
                      alimTarihi = null;
                      _searchCtrl.clear();
                      coinQuery = '';
                    });
                  },
                ),
              ),

              if (selectedTur == 'Kripto') ...[
                const SizedBox(height: 16),
                const Text('Yatırım Adı (Binance)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Coin ara (ör. BTC, ETH)',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                  onChanged: _onQueryChanged,
                ),
                const SizedBox(height: 8),
                if (coinLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    height: 320,
                    child: filteredCoins.isEmpty
                        ? const Center(
                            child: Text('Sonuç bulunamadı',
                                style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: filteredCoins.length,
                            itemBuilder: (context, i) {
                              final adi = filteredCoins[i];
                              return RadioListTile<String>(
                                title: Text(adi),
                                value: adi,
                                groupValue: selectedAdi,
                                onChanged: (val) {
                                  setState(() {
                                    selectedAdi = val;
                                    miktar = null;
                                  });
                                },
                              );
                            },
                          ),
                  ),
              ],

              if (selectedTur == 'Altın') ...[
                const SizedBox(height: 16),
                const Text('Yatırım Adı',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ...altinList.map(
                  (adi) => RadioListTile<String>(
                    title: Text(adi),
                    value: adi,
                    groupValue: selectedAdi2,
                    onChanged: (val) {
                      setState(() {
                        selectedAdi2 = val;
                        miktar = null;
                      });
                    },
                  ),
                ),
              ],

              if (selectedTur == 'Hisse') ...[
                const SizedBox(height: 16),
                const Text('Yatırım Adı',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ...hisseList.map(
                  (adi) => RadioListTile<String>(
                    title: Text(adi),
                    value: adi,
                    groupValue: selectedAdi3,
                    onChanged: (val) {
                      setState(() {
                        selectedAdi3 = val;
                        miktar = null;
                      });
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Text('Alım Tarihi (isteğe bağlı)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_dateLabel(alimTarihi),
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: alimTarihi ?? now,
                        firstDate: DateTime(2017, 1, 1), 
                        lastDate: now,
                        helpText: 'Alım tarihi seç',
                      );
                      if (picked != null) {
                        setState(() => alimTarihi = picked);
                      }
                    },
                    icon: const Icon(Icons.date_range),
                    label: const Text('Seç'),
                  ),
                ],
              ),

              if ( (selectedTur == 'Kripto' && selectedAdi != null) ||
                   (selectedTur == 'Altın'  && selectedAdi2 != null) ||
                   (selectedTur == 'Hisse'  && selectedAdi3 != null)
              ) ...[
                const SizedBox(height: 16),
                const Text('Miktar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Miktar giriniz',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => miktar = val),
                ),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: ekleAktif
                    ? () async {
                        final yatTur = selectedTur!;
                        final yatAdi = selectedAdi ?? selectedAdi2 ?? selectedAdi3 ?? '';
                        final temiz = (miktar ?? '').replaceAll(',', '.');
                        final miktarDouble = double.tryParse(temiz) ?? 0.0;

                        double? alimTl; // TL birim alış

                        if (alimTarihi != null) {
                          if (yatTur == 'Kripto') {
                            alimTl = await _cryptoUnitTryOn(
                              baseAsset: yatAdi,
                              day: alimTarihi!,
                            );
                          } else {
                            alimTl = null;
                          }
                        }

                        globalYatirimlar.add(
                          Yatirim(
                            tur: yatTur,
                            adi: yatAdi,
                            miktar: miktarDouble,
                            alimTarihi: alimTarihi,
                            alimBirimFiyatiTry: alimTl,
                          ),
                        );

                        if (!mounted) return;
                        setState(() {
                          selectedTur = null;
                          selectedAdi = null;
                          selectedAdi2 = null;
                          selectedAdi3 = null;
                          miktar = null;
                          alimTarihi = null;
                          _searchCtrl.clear();
                          coinQuery = '';
                        });
                      }
                    : null,
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
                  style:
                      TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
