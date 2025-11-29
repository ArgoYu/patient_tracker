
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../data/models/ai_co_consult_outcome.dart';

Future<void> exportOutcomePdf(BuildContext context, AiCoConsultOutcome o) async {
  final doc = pw.Document();
  final df = DateFormat('y-MM-dd HH:mm');

  pw.Widget section(String title, String body) => pw.Column(children: [
    pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    pw.SizedBox(height: 4),
    pw.Text(body),
    pw.SizedBox(height: 8),
  ]);

  doc.addPage(pw.MultiPage(build: (_) => [
    pw.Header(level: 0, child: pw.Text('Echo AI Summary', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
    pw.Text('Generated: ${df.format(o.generatedAt)}'),
    pw.SizedBox(height: 10),
    section('Overview', o.summary),
    section('Chief Complaint', o.chiefComplaint),
    section('History', o.historySummary),
    section('Diagnosis', o.diagnosisSummary),
    section('Recommendations', o.recommendations),
    pw.SizedBox(height: 10),
    pw.Text('Timeline', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
    pw.Column(children: o.timeline.map((it) =>
      pw.Bullet(text: '${df.format(it.when)} — ${it.title}: ${it.detail}')).toList()),
    pw.SizedBox(height: 10),
    pw.Text('Suggested Questions', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
    pw.Column(children: o.followUpQuestions.map((q)=>pw.Bullet(text:q)).toList()),
  ]));
  await Printing.layoutPdf(onLayout: (_) => doc.save());
}
