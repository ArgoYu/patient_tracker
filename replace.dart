import 'dart:io';

void main() {
  const path = 'lib/app_modules/my_ai_page.dart';
  final text = File(path).readAsStringSync();

  const startMarker = '    return _DetailCard(';
  final startIndex = text.indexOf(startMarker);
  if (startIndex == -1) {
    throw StateError('Start marker not found');
  }

  const lineEnding = '\r\n';
  const endMarker = '    );';
  final endIndex =
      text.indexOf(endMarker + lineEnding, startIndex) + (endMarker + lineEnding).length;
  if (endIndex == (endMarker + lineEnding).length - 1) {
    throw StateError('End marker not found');
  }

  final newBlockLines = <String>[
    "    final entries = <_SessionOutputEntry>[",
    "      _SessionOutputEntry(",
    "        label: 'Clinical Summary',",
    "        icon: Icons.description_outlined,",
    "        state: summaryState ?? _AutoProcessState.pending,",
    "        onTap: summaryHandler,",
    "      ),",
    "      _SessionOutputEntry(",
    "        label: 'Follow-up Timeline',",
    "        icon: Icons.timeline_outlined,",
    "        state: timelineState ?? _AutoProcessState.pending,",
    "        onTap: timelineHandler,",
    "      ),",
    "      _SessionOutputEntry(",
    "        label: 'Patient Qs',",
    "        icon: Icons.chat_bubble_outline,",
    "        state: patientState ?? _AutoProcessState.pending,",
    "        onTap: patientHandler,",
    "      ),",
    "      _SessionOutputEntry(",
    "        label: 'View All',",
    "        icon: Icons.list_alt_outlined,",
    "        state: _AutoProcessState.done,",
    "        onTap: onViewAll,",
    "      ),",
    "    ];",
  ];

  final newBlock = newBlockLines.join(lineEnding);
  final newText = text.replaceRange(startIndex, endIndex, newBlock);
  File(path).writeAsStringSync(newText);
}
