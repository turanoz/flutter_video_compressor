import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video_compressor/flutter_video_compressor.dart';

void main() {
  group('FlutterVideoCompressor Integration Test', () {
    testWidgets('Plugin should be available', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Test'),
          ),
        ),
      ));

      // Verify that the plugin is available
      expect(FlutterVideoCompressor, isNotNull);
    });
  });
}
