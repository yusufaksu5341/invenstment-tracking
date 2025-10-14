import 'dart:convert';
import 'package:http/http.dart' as http;

class StockPriceService {
  StockPriceService(this.apiKey);
  final String apiKey;
  final http.Client _client = http.Client();

  Future<double?> _usdTry() async {
    final r = await _client.get(Uri.parse('https://api.exchangerate.host/latest?base=USD&symbols=TRY'));
    if (r.statusCode != 200) return null;
    final d = jsonDecode(r.body);
    return (d['rates']?['TRY'] as num?)?.toDouble();
  }

  Future<double?> getPriceTry(String symbol) async {
    final u = Uri.parse('https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$apiKey');
    final r = await _client.get(u);
    if (r.statusCode != 200) return null;
    final d = jsonDecode(r.body);
    final q = d['Global Quote'] as Map?;
    if (q == null) return null;
    final s = q['05. price']?.toString();
    final p = s == null ? null : double.tryParse(s);
    if (p == null) return null;
    if (symbol.toUpperCase().endsWith('.IS')) return p;
    final k = await _usdTry();
    if (k == null) return null;
    return p * k;
  }
}