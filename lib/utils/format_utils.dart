import 'dart:math';

/// Utility functions for formatting storage sizes and numbers.
class FormatUtils {
  /// Formats a byte count into a human-readable string (e.g. "12.4 GB", "500 KB", "1.2 MB").
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    final clampedIndex = i.clamp(0, suffixes.length - 1);
    final size = bytes / pow(1024, clampedIndex);
    
    // If it's bytes (index 0), don't show decimals
    if (clampedIndex == 0) {
      return '$bytes B';
    }
    
    return '${size.toStringAsFixed(decimals)} ${suffixes[clampedIndex]}';
  }

  /// Formats a percentage value (0.0 to 1.0) into a percentage string (e.g. "82.5%").
  static String formatPercentage(double fraction, {int decimals = 1}) {
    final pct = (fraction * 100).clamp(0.0, 100.0);
    if (pct == pct.roundToDouble()) {
      return '${pct.toInt()}%';
    }
    return '${pct.toStringAsFixed(decimals)}%';
  }
}
