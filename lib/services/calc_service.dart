import 'dart:math' as math;

// ──────────────────────────────────────────────
// Simple recursive-descent expression evaluator
// ──────────────────────────────────────────────
class _Parser {
  final String src;
  int pos = 0;

  _Parser(this.src);

  double parse() {
    final v = _expr();
    if (pos < src.length) throw FormatException('Ungültige Eingabe');
    return v;
  }

  double _expr() {
    var v = _term();
    while (pos < src.length && (src[pos] == '+' || src[pos] == '-')) {
      final op = src[pos++];
      final r = _term();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  }

  double _term() {
    var v = _factor();
    while (pos < src.length && (src[pos] == '*' || src[pos] == '/')) {
      final op = src[pos++];
      final r = _factor();
      if (op == '/' && r == 0) throw FormatException('Division durch 0');
      v = op == '*' ? v * r : v / r;
    }
    return v;
  }

  double _factor() {
    _skipWs();
    if (pos < src.length && src[pos] == '(') {
      pos++;
      final v = _expr();
      _skipWs();
      if (pos >= src.length || src[pos] != ')') {
        throw FormatException('Fehlende schließende Klammer');
      }
      pos++;
      return v;
    }
    if (pos < src.length && src[pos] == '-') {
      pos++;
      return -_factor();
    }
    return _number();
  }

  double _number() {
    _skipWs();
    final start = pos;
    if (pos < src.length && src[pos] == '-') pos++;
    while (pos < src.length && (src[pos].contains(RegExp(r'[0-9]')) || src[pos] == '.')) {
      pos++;
    }
    final s = src.substring(start, pos);
    if (s.isEmpty || s == '-') throw FormatException('Ungültige Zahl');
    return double.parse(s);
  }

  void _skipWs() {
    while (pos < src.length && src[pos] == ' ') pos++;
  }
}

// ──────────────────────────────────────────────
// Formatting helpers
// ──────────────────────────────────────────────
String _fmtSig(double v, {int sig = 6}) {
  if (v.isNaN) return 'Fehler';
  if (v.isInfinite) return v > 0 ? '∞' : '-∞';
  if (v == 0) return '0';
  final abs = v.abs();
  final mag = (math.log(abs) / math.ln10).floor();
  final decimals = (sig - 1 - mag).clamp(0, 10).toInt();
  final s = v.toStringAsFixed(decimals);
  // trim trailing zeros after decimal point
  if (s.contains('.')) {
    return s.replaceAll(RegExp(r'\.?0+$'), '');
  }
  return s;
}

String _fmtEuro(double v) => '${v.toStringAsFixed(2)} €';
String _fmtPct(double v) => '${_fmtSig(v)} %';

// ──────────────────────────────────────────────
// Public API
// ──────────────────────────────────────────────
class CalcService {
  // ── Grundrechner ──────────────────────────────
  static CalcResult grundrechner(String expression) {
    try {
      final clean = expression.replaceAll(',', '.').replaceAll(' ', '');
      final val = _Parser(clean).parse();
      final res = _fmtSig(val);
      return CalcResult(
        values: {'Ergebnis': res},
        historyText: 'NR: $expression = $res',
      );
    } catch (e) {
      return CalcResult(values: {'Fehler': e.toString()}, historyText: '', error: true);
    }
  }

  // ── Prozentrechnung ──────────────────────────
  static CalcResult prozentDazu(double g, double p) {
    final pw = g * p / 100;
    final res = g + pw;
    return CalcResult(
      values: {
        'Prozentwert': _fmtSig(pw),
        'Ergebnis ($g + $p%)': _fmtSig(res),
      },
      historyText: 'Prozent dazu: $g + $p% = ${_fmtSig(res)}',
    );
  }

  static CalcResult prozentWeg(double g, double p) {
    final pw = g * p / 100;
    final res = g - pw;
    return CalcResult(
      values: {
        'Prozentwert': _fmtSig(pw),
        'Ergebnis ($g − $p%)': _fmtSig(res),
      },
      historyText: 'Prozent weg: $g - $p% = ${_fmtSig(res)}',
    );
  }

  static CalcResult prozentDavon(double g, double p) {
    final res = g * p / 100;
    return CalcResult(
      values: {'Prozentwert ($p% von $g)': _fmtSig(res)},
      historyText: 'Prozent davon: $p% von $g = ${_fmtSig(res)}',
    );
  }

  static CalcResult prozentSatz(double g, double w) {
    if (g == 0) return _err('Grundwert darf nicht 0 sein');
    final p = w / g * 100;
    return CalcResult(
      values: {'Prozentsatz': _fmtPct(p)},
      historyText: 'Prozentsatz: $w von $g = ${_fmtPct(p)}',
    );
  }

  static CalcResult bruttoAusNetto(double netto, double mwst) {
    final brutto = netto * (1 + mwst / 100);
    final steuer = brutto - netto;
    return CalcResult(
      values: {
        'Mehrwertsteuer ($mwst%)': _fmtEuro(steuer),
        'Bruttopreis': _fmtEuro(brutto),
      },
      historyText:
          'Brutto aus Netto: ${_fmtEuro(netto)} + $mwst% MwSt = ${_fmtEuro(brutto)}',
    );
  }

  static CalcResult nettoAusBrutto(double brutto, double mwst) {
    final netto = brutto / (1 + mwst / 100);
    final steuer = brutto - netto;
    return CalcResult(
      values: {
        'Mehrwertsteuer ($mwst%)': _fmtEuro(steuer),
        'Nettopreis': _fmtEuro(netto),
      },
      historyText:
          'Netto aus Brutto: ${_fmtEuro(brutto)} - $mwst% MwSt = ${_fmtEuro(netto)}',
    );
  }

  // ── Kreditberechnung ─────────────────────────
  static CalcResult kreditEinmalig(double k, double pJahr, double nMonate) {
    // Einfache Verzinsung
    final zinsen = k * (pJahr / 100) * (nMonate / 12);
    final rueck = k + zinsen;
    return CalcResult(
      values: {
        'Zinsen gesamt': _fmtEuro(zinsen),
        'Rückzahlungsbetrag': _fmtEuro(rueck),
      },
      historyText:
          'Kredit (einmalig): ${_fmtEuro(k)}, $pJahr% p.a., ${nMonate.toInt()} Monate → '
          'Rückzahlung ${_fmtEuro(rueck)}, Zinsen ${_fmtEuro(zinsen)}',
    );
  }

  static CalcResult ratenkreditLaufzeit(double k, double pJahr, double nMonate) {
    final r = pJahr / 100 / 12;
    double rate;
    if (r == 0) {
      rate = k / nMonate;
    } else {
      rate = k * r * math.pow(1 + r, nMonate) / (math.pow(1 + r, nMonate) - 1);
    }
    final zinsen = rate * nMonate - k;
    return CalcResult(
      values: {
        'Monatliche Rate': _fmtEuro(rate),
        'Zinsen gesamt': _fmtEuro(zinsen),
      },
      historyText:
          'Ratenkredit: ${_fmtEuro(k)}, $pJahr%, ${nMonate.toInt()} Monate → '
          'Rate ${_fmtEuro(rate)}, Zinsen gesamt ${_fmtEuro(zinsen)}',
    );
  }

  static CalcResult ratenkreditRate(double k, double pJahr, double rate) {
    final r = pJahr / 100 / 12;
    if (r > 0 && k * r >= rate) {
      return _err('Rate zu niedrig: muss > ${_fmtEuro(k * r)} sein');
    }
    double nMonate;
    if (r == 0) {
      nMonate = k / rate;
    } else {
      nMonate = -math.log(1 - k * r / rate) / math.log(1 + r);
    }
    final vollRate = nMonate.floor();
    // Schlussrate
    double rest = k;
    for (int i = 0; i < vollRate; i++) {
      rest = rest * (1 + r) - rate;
    }
    final schluss = rest > 0 ? rest * (1 + r) : 0.0;
    final zinsen = rate * vollRate + schluss - k;
    return CalcResult(
      values: {
        'Laufzeit': '${vollRate + (schluss > 0.01 ? 1 : 0)} Monate',
        'Monatliche Rate': _fmtEuro(rate),
        'Schlussrate': schluss > 0.01 ? _fmtEuro(schluss) : 'gleich wie Rate',
        'Zinsen gesamt': _fmtEuro(zinsen),
      },
      historyText:
          'Ratenkredit: ${_fmtEuro(k)}, $pJahr%, Rate ${_fmtEuro(rate)} → '
          '${vollRate + (schluss > 0.01 ? 1 : 0)} Monate, Zinsen ${_fmtEuro(zinsen)}',
    );
  }

  // ── Mathematische Funktionen ─────────────────
  static CalcResult fakultaet(double n) {
    if (n < 0 || n != n.floorToDouble() || n > 20) {
      return _err('n muss eine nicht-negative ganze Zahl ≤ 20 sein');
    }
    int f = 1;
    for (int i = 2; i <= n.toInt(); i++) f *= i;
    return CalcResult(
      values: {'${n.toInt()}!': '$f'},
      historyText: '${n.toInt()}! = $f',
    );
  }

  static CalcResult quadratwurzel(double n) {
    if (n < 0) return _err('Wurzel aus negativer Zahl nicht definiert');
    final res = math.sqrt(n);
    return CalcResult(
      values: {'√$n': _fmtSig(res)},
      historyText: '√$n = ${_fmtSig(res)}',
    );
  }

  static CalcResult potenz(double basis, double exp) {
    final res = math.pow(basis, exp).toDouble();
    return CalcResult(
      values: {'$basis ^ $exp': _fmtSig(res)},
      historyText: '$basis ^ $exp = ${_fmtSig(res)}',
    );
  }

  static CalcResult primzahlen(double untere, double obere) {
    if (untere > obere) return _err('Untere Grenze > obere Grenze');
    if (obere > 10000) return _err('Obere Grenze max 10000');
    final List<int> primes = [];
    for (int i = math.max(2, untere.toInt()); i <= obere.toInt(); i++) {
      if (_isPrime(i)) primes.add(i);
    }
    final s = primes.isEmpty ? 'Keine Primzahlen' : primes.join(', ');
    return CalcResult(
      values: {
        'Anzahl': '${primes.length}',
        'Primzahlen': s,
      },
      historyText:
          'Primzahlen ${untere.toInt()}..${obere.toInt()}: ${primes.length} gefunden',
    );
  }

  static bool _isPrime(int n) {
    if (n < 2) return false;
    for (int i = 2; i <= math.sqrt(n).toInt(); i++) {
      if (n % i == 0) return false;
    }
    return true;
  }

  static CalcResult dezimalZuBruch(double dezimal) {
    if (dezimal.isInfinite || dezimal.isNaN) return _err('Ungültige Zahl');
    // Up to 6 decimal places precision
    const precision = 1000000;
    final sign = dezimal < 0 ? -1 : 1;
    final abs = dezimal.abs();
    int zaehler = (abs * precision).round();
    int nenner = precision;
    final g = _gcd(zaehler, nenner);
    zaehler = sign * zaehler ~/ g;
    nenner = nenner ~/ g;
    final ganzzahl = zaehler ~/ nenner;
    final rest = zaehler % nenner;
    String bruch;
    if (rest == 0) {
      bruch = '$ganzzahl';
    } else if (ganzzahl.abs() > 0) {
      bruch = '${ganzzahl > 0 ? ganzzahl : -ganzzahl} ${rest.abs()}/$nenner';
    } else {
      bruch = '$zaehler/$nenner';
    }
    return CalcResult(
      values: {'Bruch': bruch, 'Dezimal': _fmtSig(dezimal)},
      historyText: '$dezimal = $bruch',
    );
  }

  static int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  // ── Schule ────────────────────────────────────
  static CalcResult zeugnisnote(List<double> noten) {
    final valid = noten.where((n) => n >= 1 && n <= 6).toList();
    if (valid.isEmpty) return _err('Keine gültigen Noten eingegeben');
    final sum = valid.fold(0.0, (a, b) => a + b);
    final avg = sum / valid.length;
    final zeugnis = avg.round().clamp(1, 6);
    return CalcResult(
      values: {
        'Anzahl Noten': '${valid.length}',
        'Durchschnitt': _fmtSig(avg, sig: 4),
        'Zeugnisnote': '$zeugnis (${_notenBezeichnung(zeugnis)})',
      },
      historyText:
          'Zeugnis: ${valid.length} Noten, Ø ${_fmtSig(avg, sig: 4)} → Note $zeugnis',
    );
  }

  static String _notenBezeichnung(int n) {
    switch (n) {
      case 1: return 'sehr gut';
      case 2: return 'gut';
      case 3: return 'befriedigend';
      case 4: return 'ausreichend';
      case 5: return 'mangelhaft';
      case 6: return 'ungenügend';
      default: return '';
    }
  }

  // ── Informationstechnik ───────────────────────
  static CalcResult grafikspeicher(
      double breite, double hoehe, double farbtiefe, double fps, double sek) {
    final bitsPerFrame = breite * hoehe * farbtiefe;
    final bytesPerFrame = bitsPerFrame / 8;
    final totalBytes = sek > 0 ? bytesPerFrame * fps * sek : bytesPerFrame;
    final label = sek > 0 ? 'Videodateigröße' : 'Grafikspeicher';
    return CalcResult(
      values: {
        label: _formatBytes(totalBytes),
        'Byte': '${totalBytes.toStringAsFixed(0)} B',
      },
      historyText: '$label: ${breite.toInt()}×${hoehe.toInt()} px, '
          '${farbtiefe.toInt()} bit${sek > 0 ? ', ${fps.toInt()} fps, ${sek.toInt()} s' : ''} '
          '= ${_formatBytes(totalBytes)}',
    );
  }

  static String _formatBytes(double bytes) {
    if (bytes < 1024) return '${bytes.toStringAsFixed(0)} B';
    if (bytes < 1024 * 1024) return '${_fmtSig(bytes / 1024)} KiB';
    if (bytes < 1024 * 1024 * 1024) return '${_fmtSig(bytes / (1024 * 1024))} MiB';
    return '${_fmtSig(bytes / (1024 * 1024 * 1024))} GiB';
  }

  static CalcResult zahlensystem(double dezimalZahl, double quellBasis) {
    // Convert from source base to decimal first, then to all bases
    int basis = quellBasis.toInt();
    int dezimal;
    if (basis == 10) {
      dezimal = dezimalZahl.toInt();
    } else {
      // interpret dezimalZahl's digits in quellBasis
      final s = dezimalZahl.toInt().toString();
      dezimal = 0;
      for (var c in s.split('')) {
        final d = int.tryParse(c) ?? -1;
        if (d < 0 || d >= basis) return _err('Ungültige Ziffer "$c" für Basis $basis');
        dezimal = dezimal * basis + d;
      }
    }
    return CalcResult(
      values: {
        'Dezimal (10)': '$dezimal',
        'Binär (2)': dezimal.toRadixString(2),
        'Ternär (3)': dezimal.toRadixString(3),
        'Oktal (8)': dezimal.toRadixString(8),
      },
      historyText:
          '${dezimalZahl.toInt()} (Basis $basis) → '
          'Dez: $dezimal, Bin: ${dezimal.toRadixString(2)}, '
          'Tern: ${dezimal.toRadixString(3)}, Okt: ${dezimal.toRadixString(8)}',
    );
  }

  static CalcResult datenmenge(double wert, String einheit) {
    // Convert to bits first
    final Map<String, double> toBits = {
      'bit': 1,
      'Byte': 8,
      'KiB': 8.0 * 1024,
      'MiB': 8.0 * 1024 * 1024,
      'GiB': 8.0 * 1024 * 1024 * 1024,
      'TiB': 8.0 * 1024 * 1024 * 1024 * 1024,
      'KB': 8.0 * 1000,
      'MB': 8.0 * 1000 * 1000,
      'GB': 8.0 * 1000 * 1000 * 1000,
      'TB': 8.0 * 1000 * 1000 * 1000 * 1000,
    };
    final factor = toBits[einheit] ?? 1;
    final totalBits = wert * factor;
    return CalcResult(
      values: {
        'bit': _fmtSig(totalBits),
        'Byte': _fmtSig(totalBits / 8),
        'KiB (1024)': _fmtSig(totalBits / 8 / 1024),
        'MiB (1024²)': _fmtSig(totalBits / 8 / (1024 * 1024)),
        'KB (1000)': _fmtSig(totalBits / 8 / 1000),
        'MB (1000²)': _fmtSig(totalBits / 8 / (1000 * 1000)),
      },
      historyText: '$wert $einheit = ${_fmtSig(totalBits / 8 / (1024 * 1024))} MiB '
          '= ${_fmtSig(totalBits / 8 / (1000 * 1000))} MB',
    );
  }

  static CalcResult _err(String msg) =>
      CalcResult(values: {'Fehler': msg}, historyText: '', error: true);
}

class CalcResult {
  final Map<String, String> values;
  final String historyText;
  final bool error;

  const CalcResult({
    required this.values,
    required this.historyText,
    this.error = false,
  });
}
