import 'dart:async';
import 'dart:convert';

/// Represents a single strip of data in a visualization.
class DataStrip {
  String title;
  double startValue;
  double endValue;
  (String, int) interval;
  double currentValue;
  String iconUrl;
  int color; // ARGB value
  double height;

  DataStrip({
    required this.title,
    required this.startValue,
    required this.endValue,
    required this.interval,
    required this.iconUrl,
    required this.color,
    required this.height,
  }) : currentValue = startValue;

  /// Resets the strip to its initial state.
  void reset() {
    currentValue = startValue;
  }

  /// Sets the start value of the strip.
  void setStartValue(double value) {
    startValue = value;
  }

  /// Sets the end value of the strip.
  void setEndValue(double value) {
    endValue = value;
  }

  /// Sets the interval of the strip.
  void setInterval((String, int) newInterval) {
    interval = newInterval;
  }

  /// Sets the icon of the strip.
  void setIcon(String url) {
    iconUrl = url;
  }

  /// Sets the color of the strip.
  void setColor(int newColor) {
    color = newColor;
  }

  /// Returns the JSON of the strip.
  String toJson() {
    return jsonEncode(toMap());
  }

  /// Returns a map representation of the strip.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'startValue': startValue,
      'endValue': endValue,
      'interval': {
        'type': interval.$1,
        'value': interval.$2,
      },
      'currentValue': currentValue,
      'iconUrl': iconUrl,
      'color': color,
      'height': height,
    };
  }
}

/// Manages a collection of DataStrips and provides data as a stream.
class GenerateData {
  String title;
  String subtitle;
  DateTime startDate;
  DateTime endDate;
  List<DataStrip> dataStrips;

  StreamController<String>? _controller;
  Timer? _timer;
  DateTime? _currentTime;

  GenerateData({
    required this.title,
    required this.subtitle,
    required this.startDate,
    required this.endDate,
    required this.dataStrips,
  });

  /// Returns JSON of a specified strip, if not specified, return all strips sorted by value.
  String getStrips([int? stripNumber]) {
    if (stripNumber != null) {
      if (stripNumber >= 0 && stripNumber < dataStrips.length) {
        return dataStrips[stripNumber].toJson();
      }
      throw ArgumentError('Strip index out of bounds');
    }

    // Sort decreasing by value
    final sorted = List<DataStrip>.from(dataStrips)
      ..sort((a, b) => b.currentValue.compareTo(a.currentValue));

    return jsonEncode(sorted.map((s) => s.toMap()).toList());
  }

  /// Starts the stream of JSON data strips.
  Stream<String> startStream([int? maxIterations]) {
    _stopRunningStream();
    _controller = StreamController<String>();
    _currentTime = startDate;
    int iterations = 0;

    void updateAndEmit() {
      if (_currentTime == null || _controller == null) return;

      if (_currentTime!.isAfter(endDate) || (maxIterations != null && iterations >= maxIterations)) {
        stopStream();
        return;
      }

      // Calculate progress (0.0 to 1.0)
      double totalDuration = endDate.difference(startDate).inMilliseconds.toDouble();
      double elapsed = _currentTime!.difference(startDate).inMilliseconds.toDouble();
      double progress = totalDuration > 0 ? (elapsed / totalDuration).clamp(0.0, 1.0) : 1.0;

      // Update values
      for (var strip in dataStrips) {
        strip.currentValue = strip.startValue + (strip.endValue - strip.startValue) * progress;
      }

      // Emit current state sorted
      _controller!.add(getStrips());

      // Advance time based on the interval of the first strip or a default step
      // The spec doesn't specify exactly how time advances for the stream, 
      // so we use a reasonable step based on the intervals of the strips.
      _currentTime = _advanceTime(_currentTime!, dataStrips.first.interval);
      iterations++;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => updateAndEmit());
    
    // Emit initial state
    updateAndEmit();

    return _controller!.stream;
  }

  DateTime _advanceTime(DateTime time, (String, int) interval) {
    final type = interval.$1.toUpperCase();
    final value = interval.$2;

    switch (type) {
      case 'H': return time.add(Duration(hours: value));
      case 'D': return time.add(Duration(days: value));
      case 'W': return time.add(Duration(days: 7 * value));
      case 'M': return DateTime(time.year, time.month + value, time.day, time.hour);
      case 'Q': return DateTime(time.year, time.month + (3 * value), time.day, time.hour);
      case 'Y': return DateTime(time.year + value, time.month, time.day, time.hour);
      default: return time.add(const Duration(days: 1));
    }
  }

  /// Stops the stream of JSON data strips.
  void stopStream() {
    _stopRunningStream();
  }

  void _stopRunningStream() {
    _timer?.cancel();
    _timer = null;
    _controller?.close();
    _controller = null;
  }

  /// Resets all strips to their initial state.
  void resetAll() {
    for (var strip in dataStrips) {
      strip.reset();
    }
    _currentTime = startDate;
  }
}
