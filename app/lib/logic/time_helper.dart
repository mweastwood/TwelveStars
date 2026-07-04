class TimeHelper {
  static DateTime? _customTime;

  static void setCustomTime(DateTime? time) {
    _customTime = time;
  }

  static DateTime now() {
    return _customTime ?? DateTime.now();
  }
}
