class BuenosAiresTime {
  BuenosAiresTime._();

  static const Duration _offset = Duration(hours: 3);

  static DateTime now() {
    return DateTime.now().toUtc().subtract(_offset);
  }

  static DateTime toBuenosAires(DateTime dateTime) {
    final utc = dateTime.isUtc ? dateTime : dateTime.toUtc();
    return utc.subtract(_offset);
  }

  static DateTime? tryParseToBuenosAires(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return null;
    return toBuenosAires(parsed);
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--/-- ----';
    final ba = toBuenosAires(dateTime);
    final day = ba.day.toString().padLeft(2, '0');
    final month = ba.month.toString().padLeft(2, '0');
    final year = ba.year.toString();
    final hour = ba.hour.toString().padLeft(2, '0');
    final minute = ba.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  static String formatDateTimeFromIso(String iso) {
    final ba = tryParseToBuenosAires(iso);
    if (ba == null) return '--/-- ----';
    final day = ba.day.toString().padLeft(2, '0');
    final month = ba.month.toString().padLeft(2, '0');
    final year = (ba.year % 100).toString().padLeft(2, '0');
    final hour = ba.hour.toString().padLeft(2, '0');
    final minute = ba.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  static String formatHourMinuteFromIso(String? iso) {
    final ba = tryParseToBuenosAires(iso);
    if (ba == null) return '';
    final hour = ba.hour.toString().padLeft(2, '0');
    final minute = ba.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String dateKeyFromIso(String? iso) {
    final ba = tryParseToBuenosAires(iso);
    if (ba == null) return '';
    final year = ba.year.toString().padLeft(4, '0');
    final month = ba.month.toString().padLeft(2, '0');
    final day = ba.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
