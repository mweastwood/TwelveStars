class CounterLogic {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
  }

  String get label => _count == 1 ? '1 star shining' : '$_count stars shining';
}
