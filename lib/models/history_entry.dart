class HistoryEntry {
  final String id;
  final DateTime timestamp;
  final String text; // formatted display string
  final bool isDateStamp;
  final bool isSideCalc;

  const HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.text,
    this.isDateStamp = false,
    this.isSideCalc = false,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: j['id'] ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(j['ts'] ?? 0),
        text: j['text'] ?? '',
        isDateStamp: j['dateStamp'] ?? false,
        isSideCalc: j['sideCalc'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ts': timestamp.millisecondsSinceEpoch,
        'text': text,
        'dateStamp': isDateStamp,
        'sideCalc': isSideCalc,
      };
}
