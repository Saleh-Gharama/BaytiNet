class FormatUtils {
  static String formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes ب";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} ك.ب";
    if (bytes < 1024 * 1024 * 1024) return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} م.ب";
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ج.ب";
  }
}
