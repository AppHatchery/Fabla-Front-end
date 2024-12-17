import 'dart:async';

class PageTimer {
  Timer? _timer;
  int _time = 0;

  void start() async {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (value) {
      _time++;
    });
  }

  int stop() {
    _timer?.cancel();
    _timer = null;
    return _time;
  }

  int reset() {
    final time = stop();
    _time = 0;
    start();
    return time;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _time = 0;
  }
}
