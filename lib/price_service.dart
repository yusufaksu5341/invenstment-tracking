import 'dart:convert';
import 'package:http/http.dart' as http;
import 'stock_price_service.dart';


class PriceService {
  PriceService._();
  static final PriceService instance = PriceService._();
  final StockPriceService _stocks = StockPriceService('YOUR_ALPHA_VANTAGE_KEY');


  final http.Client _client = http.Client();

  double? _usdtTry;
  DateTime? _usdtTryTs;
  final Duration _usdtTryTtl = const Duration(seconds: 60);

  final Map<String, double> _cryptoUsdt = {};
  final Map<String, DateTime> _cryptoUsdtTs = {};
  final Duration _cryptoTtl = const Duration(seconds: 30);

  Map<String, double>? _goldTry;
  DateTime? _goldTs;
  final Duration _goldTtl = const Duration(minutes: 10);

  double? _parseTrNum(String s) {
    final cleaned = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  Future<double> _getUsdtTry() async {
    final now = DateTime.now();
    if (_usdtTry != null &&
        _usdtTryTs != null &&
        now.difference(_usdtTryTs!) < _usdtTryTtl) {
      return _usdtTry!;
    }
    final uri = Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=USDTTRY');
    final res = await _client.get(uri);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _usdtTry = double.tryParse(data['price'] as String) ?? 0;
      _usdtTryTs = now;
      return _usdtTry!;
    } else {
      throw Exception('USDTTRY alınamadı');
    }
  }

  Future<double?> getCryptoPriceTry(String baseAsset) async {
    final usdt = await _getCryptoPriceUsdt(baseAsset);
    if (usdt == null) return null;
    final k = await _getUsdtTry();
    return usdt * k;
  }

  Future<double?> _getCryptoPriceUsdt(String baseAsset) async {
    final now = DateTime.now();
    final key = baseAsset.toUpperCase();

    if (_cryptoUsdt.containsKey(key) &&
        _cryptoUsdtTs[key] != null &&
        now.difference(_cryptoUsdtTs[key]!) < _cryptoTtl) {
      return _cryptoUsdt[key];
    }


final symbol = '${key}USDT';
    final uri = Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=$symbol');
    final res = await _client.get(uri);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final price = double.tryParse(data['price'] as String);
      if (price != null) {
        _cryptoUsdt[key] = price;
        _cryptoUsdtTs[key] = now;
        return price;
      }
    }
    return null;
  }

  Future<void> _ensureGold() async {
    final now = DateTime.now();
    if (_goldTry != null && _goldTs != null && now.difference(_goldTs!) < _goldTtl) {
      return;
    }
    final uri = Uri.parse('https://finans.truncgil.com/today.json');
    final res = await _client.get(uri);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final map = <String, double>{};
      double? sat(String keyTr) {
        final obj = data[keyTr];
        if (obj is Map) {
          final s = (obj['Satış'] ?? obj['Satis'] ?? obj['Selling'])?.toString();
          if (s != null) return _parseTrNum(s);
        }
        return null;
      }

      final gram = sat('Gram Altın');
      final ceyrek = sat('Çeyrek Altın');
      final tam = sat('Tam Altın');
      final cumhuriyet = sat('Cumhuriyet Altını');

      if (gram != null) map['Gram'] = gram;
      if (ceyrek != null) map['Çeyrek'] = ceyrek;
      if (tam != null) map['Tam'] = tam;
      if (cumhuriyet != null) map['Cumhuriyet'] = cumhuriyet;

      _goldTry = map;
      _goldTs = now;
    } else {
      throw Exception('Altın fiyatları alınamadı');
    }
  }

  Future<double?> getGoldPriceTry(String altinTipi) async {
    await _ensureGold();
    return _goldTry?[altinTipi];
  }

 
  Future<double?> getStockPriceTry(String displayName) async {
    final map = <String, String>{
      'Ebebek': 'EBEBK.IS',
      'BIENY': 'BIENY',
      'BIGCH': 'BIGCH', 
    };
    final symbol = map[displayName];
    if (symbol == null) return null;

    try {
      final uri = Uri.parse(
          'https://query1.finance.yahoo.com/v7/finance/quote?symbols=$symbol');
      final res = await _client.get(uri, headers: {
        'User-Agent':
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122 Safari/537.36',
        'Accept': 'application/json',
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final result = (data['quoteResponse']?['result'] as List?)?.first;
        if (result == null) return null;
        final price = (result['regularMarketPrice'] as num?)?.toDouble();
        final currency = result['currency']?.toString();
        if (price == null) return null;

        if (currency == 'TRY') return price;
        // USD veya USDT ise USDTTRY ile çevir
        if (currency == 'USD' || currency == 'USDT' || currency == null) {
          final k = await _getUsdtTry();
          return price * k;
        }
      }
    } catch (_) {
    }
    return null;
  }

  Future<double?> getUnitPriceTry({
    required String tur,
    required String adi,
  }) async {
    if (tur == 'Kripto') return getCryptoPriceTry(adi);
    if (tur == 'Altın') return getGoldPriceTry(adi);
    if (tur == 'Hisse') return getStockPriceTry(adi);
    return null;
  }
}
