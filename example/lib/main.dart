import 'package:flutter/material.dart';
import 'package:flutter_video_compressor/flutter_video_compressor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Video Compressor Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Video Compressor Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _status = 'Plugin loaded successfully!';

  @override
  void initState() {
    super.initState();
    _testPlugin();
  }

  Future<void> _testPlugin() async {
    try {
      setState(() {
        _status = 'Testing plugin...';
      });

      final cacheResult = await FlutterVideoCompressor.clearCache();

      setState(() {
        _status = 'Plugin test completed!\nCache cleared: $cacheResult';
      });
    } catch (e) {
      setState(() {
        _status = 'Plugin test failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Flutter Video Compressor Plugin Example',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testPlugin,
              child: const Text('Test Plugin'),
            ),
          ],
        ),
      ),
    );
  }
}
