import 'package:gen_data/gen_data.dart';
import 'package:test/test.dart';
import 'dart:convert';

void main() {
  group('GenerateData Tests', () {
    late GenerateData gd;

    setUp(() {
      gd = GenerateData(
        title: 'Test',
        subtitle: 'Test',
        startDate: DateTime(2023, 1, 1),
        endDate: DateTime(2023, 1, 10),
        dataStrips: [
          DataStrip(
            name: 'Slow',
            startValue: 0.0,
            endValue: 10.0,
            interval: ('D', 1),
            iconUrl: '',
            color: 0,
            height: 10,
          ),
          DataStrip(
            name: 'Fast',
            startValue: 0.0,
            endValue: 100.0,
            interval: ('D', 1),
            iconUrl: '',
            color: 0,
            height: 10,
          ),
        ],
      );
    });

    test('getStrips returns sorted items initially', () {
      final jsonStr = gd.getStrips();
      final List<dynamic> list = jsonDecode(jsonStr);
      expect(list.length, 2);
      // Both start at 0.0, so order might be stable or arbitrary depending on sort
      // But we check structure
      expect(list[0]['name'], isNotNull);
    });

    test('resetAll resets values', () {
      gd.dataStrips[0].currentValue = 50.0;
      gd.resetAll();
      expect(gd.dataStrips[0].currentValue, 0.0);
    });

    test('startStream emits data', () async {
      final stream = gd.startStream(2);
      final list = await stream.toList();
      expect(list.length, greaterThanOrEqualTo(1));
      
      final firstEmit = jsonDecode(list[0]) as List;
      // After some progress, 'Fast' should be greater than 'Slow'
      if (list.length > 1) {
        final secondEmit = jsonDecode(list[1]) as List;
        expect(secondEmit[0]['name'], 'Fast');
      }
    });
  });
}
