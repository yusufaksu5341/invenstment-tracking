import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class Graph extends StatefulWidget {
  final String coinSymbol;
  final String interval; 

  const Graph({super.key, required this.coinSymbol, required this.interval});

  @override
  State<Graph> createState() => _GraphState();
}

class _GraphState extends State<Graph> {
  List<FlSpot> spots = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchGraphData();
  }

  Future<void> fetchGraphData() async {
    final symbol = '${widget.coinSymbol.toUpperCase()}USDT';
    final interval = '1d';
    int limit = switch (widget.interval) {
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
          loading = false;
        });
      }
    } catch (_) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.coinSymbol.toUpperCase()} Grafiği'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color.fromARGB(255, 128, 33, 243),
          
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
