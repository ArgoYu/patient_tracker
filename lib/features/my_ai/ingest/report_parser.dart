class ParsedReport {
  final String overview;
  final String chiefComplaint;
  final String history;
  final String diagnosis;
  final List<String> recommendations;
  final List<String> highlights;
  final List<String> followUps;

  const ParsedReport({
    required this.overview,
    required this.chiefComplaint,
    required this.history,
    required this.diagnosis,
    required this.recommendations,
    required this.highlights,
    required this.followUps,
  });
}

ParsedReport parseReportText(String t) {
  String pick(String key) {
    final re = RegExp(
      '$key\\s*:\\s*(.+?)(?:\\n\\s*[A-Z][a-zA-Z ]+:|\\n*\$)',
      dotAll: true,
      caseSensitive: false,
    );
    final m = re.firstMatch(t);
    return (m != null) ? m.group(1)!.trim() : '';
  }

  final cc = pick('Chief complaint');
  final hx = pick('History');
  final dx = pick('Diagnosis');
  final rec = pick('Recommendations');

  final recLines = rec.isEmpty
      ? const <String>[]
      : rec
          .split(RegExp(r'[;\n•]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

  final hl = <String>[
    if (cc.isNotEmpty) 'Chief complaint: $cc',
    if (dx.isNotEmpty) 'Diagnosis: $dx',
  ];

  final fu = <String>[
    ...recLines.where(
      (s) => s.toLowerCase().contains('follow') || s.toLowerCase().contains('call'),
    ),
  ];

  final overview = [
    if (cc.isNotEmpty) 'CC: $cc',
    if (hx.isNotEmpty) 'Hx: $hx',
    if (dx.isNotEmpty) 'Dx: $dx',
  ].join(' • ');

  return ParsedReport(
    overview: overview,
    chiefComplaint: cc.isEmpty ? 'No chief complaint captured.' : cc,
    history: hx.isEmpty ? 'No additional history recorded.' : hx,
    diagnosis: dx.isEmpty ? 'No clear diagnostic summary recorded.' : dx,
    recommendations: recLines,
    highlights: hl,
    followUps: fu.isEmpty ? recLines : fu,
  );
}
