
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class Graph extends StatefulWidget {
  const Graph({super.key});

  @override
  State<Graph> createState() => _GraphState();
}

class _GraphState extends State<Graph> {
  String? selectedCoin;
  String selectedInterval = '1d';
  List<FlSpot> spots = [];
  bool loading = false;
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> coinList = [];
  List<String> filteredCoins = [];

  final List<String> intervals = ['Gün', 'Hafta', 'Ay', 'Yıl'];

  @override
  void initState() {
    super.initState();
    fetchCoinList();
  }

  Future<void> fetchCoinList() async {
    final uri = Uri.parse('https://api.binance.com/api/v3/exchangeInfo');
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final symbols = data['symbols'] as List;
        final coins = symbols
            .where((s) => s['quoteAsset'] == 'USDT' && s['status'] == 'TRADING')
            .map<String>((s) => s['baseAsset'] as String)
            .toSet()
            .toList()
          ..sort();
        setState(() => coinList = coins);
      }
    } catch (_) {}
  }

  void filterCoins(String query) {
    final q = query.toLowerCase();
    setState(() {
      filteredCoins = coinList.where((c) => c.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> fetchGraphData() async {
    if (selectedCoin == null) return;
    setState(() => loading = true);
    final symbol = '${selectedCoin!.toUpperCase()}USDT';
    final interval = '1d';
    int limit = switch (selectedInterval) {
      '1d' => 1,
      '1w' => 7,
      '1mo' => 30,
      '1y' => 365,
      _ => 30,
    };

    final uri = Uri.parse(
      'https://api.binance.com/api/v3/klines?symbol=$symbol&interval=$interval&limit=$limit',
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<FlSpot> tempSpots = [];
        for (int i = 0; i < data.length; i++) {
          final kline = data[i];
          final close = double.tryParse(kline[4].toString()) ?? 0.0;
          tempSpots.add(FlSpot(i.toDouble(), close));
        }
        setState(() => spots = tempSpots);
      }
    } catch (_) {}
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Grafiği'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Coin ara (ör. BTC, ETH)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: filterCoins,
            ),
            if (filteredCoins.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredCoins.length,
                itemBuilder: (context, index) {
                  final coin = filteredCoins[index];
                  return ListTile(
                    title: Text(coin),
                    onTap: () {
                      setState(() {
                        selectedCoin = coin;
                        _searchCtrl.text = coin;
                        filteredCoins.clear();
                      });
                      fetchGraphData();
                    },
                  );
                },
              ),
            const SizedBox(height: 16),
            if (selectedCoin != null)
              Column(
                children: [
                  if (loading)
                    const CircularProgressIndicator()
                  else
                    SizedBox(
                      height: 300,
                      child: LineChart(
                        LineChartData(
                          titlesData: FlTitlesData(show: true),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 2,
                              dotData: FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: intervals.map((interval) {
                      final isSelected = interval == selectedInterval;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
                          foregroundColor: isSelected ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          setState(() => selectedInterval = interval);
                          fetchGraphData();
                        },
                        child: Text(interval),
                      );
                    }).toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
