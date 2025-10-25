
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
  String selectedCoin = 'BTC';
  String selectedInterval = '1d';
  List<FlSpot> spots = [];
  bool loading = false;
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> intervals = ['1d', '1w', '1mo', '1y'];

  Future<void> fetchGraphData() async {
    setState(() => loading = true);
    final symbol = '${selectedCoin.toUpperCase()}USDT';
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
        setState(() {
          spots = tempSpots;
        });
      }
    } catch (_) {
      // handle error
    }
    setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    fetchGraphData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Grafiği'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Coin ara (ör. BTC, ETH)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      selectedCoin = _searchCtrl.text.trim().toUpperCase();
                    });
                    fetchGraphData();
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (loading)
              const CircularProgressIndicator()
            else
              Expanded(
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
      ),
    );
  }
}
