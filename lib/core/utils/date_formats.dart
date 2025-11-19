// lib/core/utils/date_formats.dart

/// Formats a [DateTime] as YYYY-MM-DD.
String formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Formats a [DateTime] with time as YYYY-MM-DD HH:MM.
String formatDateTime(DateTime date) =>
    '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

/// Formats only the time portion of a [DateTime] as HH:MM.
String formatTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
