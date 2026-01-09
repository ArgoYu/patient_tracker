// lib/data/models/rx_check_in.dart

class RxCheckIn {
  const RxCheckIn({
    required this.timestamp,
    required this.medicationId,
  });

  final DateTime timestamp;
  final String medicationId;
}
