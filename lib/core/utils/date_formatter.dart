/// Utility class for safe date formatting in Indonesian without locale dependencies.
class AppDateFormatter {
  AppDateFormatter._();

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Format: "Agustus 2026"
  static String formatMonthYear(DateTime date) {
    return '${_months[date.month - 1]} ${date.year}';
  }

  /// Format: "27 Agustus 2026"
  static String formatDate(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  /// Format: "27 Agu 2026, 21:55"
  static String formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${_monthsShort[date.month - 1]} ${date.year}, $hour:$minute';
  }

  /// Cek apakah dua DateTime berada pada hari yang sama (mengabaikan jam/menit/detik)
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Format judul hari cerdas: "Hari Ini, 29 Agu 2026", "Kemarin, 28 Agu 2026", atau "27 Agu 2026"
  static String formatDayTitle(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (isSameDay(date, now)) {
      return 'Hari Ini, ${formatDate(date)}';
    } else if (isSameDay(date, yesterday)) {
      return 'Kemarin, ${formatDate(date)}';
    } else {
      return formatDate(date);
    }
  }
}
