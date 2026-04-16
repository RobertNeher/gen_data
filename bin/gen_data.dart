import 'package:gen_data/gen_data.dart';

void main(List<String> arguments) {
  final gd = GenerateData(
    title: '# Data Visualization',
    subtitle: 'Sample generated data',
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 10)),
    dataStrips: [
      DataStrip(
        title: '# Strip A',
        startValue: 10.0,
        endValue: 100.0,
        interval: ('D', 1),
        iconUrl: 'https://example.com/a.png',
        color: 0xFFFF0000,
        height: 50.0,
      ),
      DataStrip(
        title: '# Strip B',
        startValue: 50.0,
        endValue: 200.0,
        interval: ('D', 1),
        iconUrl: 'https://example.com/b.png',
        color: 0xFF00FF00,
        height: 50.0,
      ),
    ],
  );

  print('Initial Data Strips (Sorted):');
  print(gd.getStrips());

  print('\nStarting Stream for 10 iterations:');
  gd.startStream(10).listen((json) {
    print('Stream Emit: $json');
  });
}
