import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'add.dart';

class WalletPage extends StatefulWidget {
  final List<Yatirim> yatirimlar;
  const WalletPage({super.key, required this.yatirimlar});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double? _usdtTry;                            
  final Map<String, double> _cryptoUsdt = {};  
  Map<String, double>? _goldTry;               

  final Map<int, double?> _unitTryNow = {};
  final Map<int, double?> _lineTry = {};
  final Map<int, double?> _pnlTry = {}; 

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refreshPrices();
  }

  double? _parseTrNum(String s) {
    final cleaned = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  Future<double> _getUsdtTryNow() async {
    if (_usdtTry != null) return _usdtTry!;
    try {
      final res = await http.get(Uri.parse(
          'https://api.binance.com/api/v3/ticker/price?symbol=USDTTRY'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _usdtTry = double.tryParse(data['price'] as String) ?? 0.0;
        return _usdtTry!;
      }
    } catch (_) {}
    return 0.0;
  }

  Future<double?> _getCryptoUsdtNow(String base) async {
    final key = base.toUpperCase();
    if (_cryptoUsdt.containsKey(key)) return _cryptoUsdt[key];
    try {
      final res = await http.get(Uri.parse(
          'https://api.binance.com/api/v3/ticker/price?symbol=${key}USDT'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final p = double.tryParse(data['price'] as String);
        if (p != null) {
          _cryptoUsdt[key] = p;
          return p;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _ensureGoldNow() async {
    if (_goldTry != null) return;
    try {
      final res = await http.get(Uri.parse('https://finans.truncgil.com/today.json'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        double? sat(String keyTr) {
          final obj = data[keyTr];
          if (obj is Map) {
            final s = (obj['Satış'] ?? obj['Satis'] ?? obj['Selling'])?.toString();
            if (s != null) return _parseTrNum(s);
          }
          return null;
        }
        final map = <String, double>{};
        final gram = sat('Gram Altın');
        final ceyrek = sat('Çeyrek Altın');
        final tam = sat('Tam Altın');
        final cumhuriyet = sat('Cumhuriyet Altını');
        if (gram != null) map['Gram'] = gram;
        if (ceyrek != null) map['Çeyrek'] = ceyrek;
        if (tam != null) map['Tam'] = tam;
        if (cumhuriyet != null) map['Cumhuriyet'] = cumhuriyet;
        _goldTry = map;
      }
    } catch (_) {}
  }

  Future<double?> _getUnitTryNow(Yatirim y) async {
    if (y.tur == 'Kripto') {
      final usdt = await _getCryptoUsdtNow(y.adi);
      if (usdt == null) return null;
      final k = await _getUsdtTryNow();
      if (k == 0) return null;
      return usdt * k;
    }
    if (y.tur == 'Altın') {
      await _ensureGoldNow();
      return _goldTry?[y.adi];
    }
    return null;
  }

  Future<void> _refreshPrices() async {
    if (_loading) return;
    setState(() => _loading = true);

    for (int i = 0; i < widget.yatirimlar.length; i++) {
      final y = widget.yatirimlar[i];
      try {
        final unitNow = await _getUnitTryNow(y);
        _unitTryNow[i] = unitNow;
        _lineTry[i] = (unitNow != null) ? unitNow * y.miktar : null;

        final buy = y.alimBirimFiyatiTry;
        if (buy != null && unitNow != null) {
          _pnlTry[i] = (unitNow - buy) * y.miktar;
        } else {
          _pnlTry[i] = null;
        }
      } catch (_) {
        _unitTryNow[i] = null;
        _lineTry[i] = null;
        _pnlTry[i] = null;
      }

      if (mounted) setState(() {}); 
    }

    if (mounted) setState(() => _loading = false);
  }

  final Map<String, String?> _logoUrlCache = {};
  final Map<String, Future<String?>> _logoFutureCache = {};

  Future<bool> _urlExists(String url) async {
    try {
      final uri = Uri.parse(url);
      final h = await http.head(uri);
      if (h.statusCode == 200) return true;
      final g = await http.get(uri);
      return g.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _coingeckoLogo(String symbol) async {
    try {
      final q = Uri.encodeComponent(symbol);
      final r = await http
          .get(Uri.parse('https://api.coingecko.com/api/v3/search?query=$q'));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final List coins = data['coins'] ?? [];
        Map<String, dynamic>? match = coins.cast<Map<String, dynamic>?>().firstWhere(
          (c) => (c?['symbol']?.toString().toLowerCase() == symbol.toLowerCase()),
          orElse: () => null,
        );
        match ??= coins.isNotEmpty ? coins.first as Map<String, dynamic> : null;
        if (match != null) {
          final id = match['id']?.toString();
          if (id != null) {
            final cr = await http.get(Uri.parse(
                'https://api.coingecko.com/api/v3/coins/$id?localization=false&tickers=false&market_data=false&community_data=false&developer_data=false&sparkline=false'));
            if (cr.statusCode == 200) {
              final cd = jsonDecode(cr.body);
              final img = cd['image'] ?? {};
              final url = (img['small'] ?? img['thumb'])?.toString();
              if (url != null && await _urlExists(url)) return url;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _resolveLogoUrl(String symbol) async {
    final key = symbol.toUpperCase();
    if (_logoUrlCache.containsKey(key)) return _logoUrlCache[key];
    if (_logoFutureCache.containsKey(key)) return _logoFutureCache[key];

    final fut = () async {
      final spothq =
          'https://cdn.jsdelivr.net/gh/spothq/cryptocurrency-icons@master/128/color/${symbol.toLowerCase()}.png';
      if (await _urlExists(spothq)) {
        _logoUrlCache[key] = spothq;
        return spothq;
      }
      final cryptoicons =
          'https://cryptoicons.org/api/icon/${symbol.toLowerCase()}/64';
      if (await _urlExists(cryptoicons)) {
        _logoUrlCache[key] = cryptoicons;
        return cryptoicons;
      }
      final cg = await _coingeckoLogo(symbol);
      if (cg != null) {
        _logoUrlCache[key] = cg;
        return cg;
      }
      _logoUrlCache[key] = null;
      return null;
    }();

    _logoFutureCache[key] = fut;
    final url = await fut;
    _logoFutureCache.remove(key);
    return url;
  }

  Widget _fallbackAvatar(String text) {
    final initial = (text.isNotEmpty ? text[0].toUpperCase() : '?');
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.black,
      child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 20)),
    );
  }

  Widget _coinAvatar(String symbol) {
    return FutureBuilder<String?>(
      future: _resolveLogoUrl(symbol),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFEDEDED),
            child: SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final url = snap.data;
        if (url == null) return _fallbackAvatar(symbol);
        return ClipOval(
          child: Image.network(
            url,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => _fallbackAvatar(symbol),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(Yatirim y) =>
      y.tur == 'Kripto' ? _coinAvatar(y.adi) : _fallbackAvatar(y.adi);

  // ---------- Kart UI ----------
  String _formatQty(Yatirim y) =>
      y.tur == 'Kripto' ? y.miktar.toStringAsFixed(8) : y.miktar.toStringAsFixed(2);

  String _formatTry(double? v) => v == null ? '₺-' : '₺${v.toStringAsFixed(2)}';

  Widget _pnlChip(double? pnl) {
    if (pnl == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('PnL: —', style: TextStyle(color: Colors.black54)),
      );
    }
    final isPos = pnl >= 0;
    final color = isPos ? const Color(0xFF0F9D58) : const Color(0xFFDB4437);
    final sign = isPos ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.5)),
      ),
      child: Text(
        'PnL: $sign${_formatTry(pnl).substring(1)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildRow(int index, Yatirim y) {
    final line = _lineTry[index];
    final pnl = _pnlTry[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Stack(
        children: [
          // Kart gövdesi
          Card(
            elevation: 4,
            margin: const EdgeInsets.only(top: 18), 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
              child: Row(
                children: [
                  SizedBox(width: 48, height: 48, child: _buildAvatar(y)),
                  const SizedBox(width: 14),

                  // Orta: Ad + Miktar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(y.adi,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(_formatQty(y),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),

                  Text(
                    _formatTry(line),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 24,
            top: 0,
            child: _pnlChip(pnl),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.yatirimlar;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        title: const Text('Yatırımlarım'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF1F1F1),
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: _loading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: _loading ? null : _refreshPrices,
            tooltip: 'Fiyatları Güncelle',
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Henüz yatırım eklenmedi.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => _refreshPrices(),
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                itemCount: items.length,
                itemBuilder: (context, i) => _buildRow(i, items[i]),
              ),
            ),
    );
  }
}
