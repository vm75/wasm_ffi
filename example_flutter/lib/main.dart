import 'package:flutter/material.dart';

import 'example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wasm FFI Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('wasm-ffi tests')),
      body: const Column(
        children: [
          Expanded(
            child: AsyncRunnerWidget(
              'standalone/native_example.wasm',
              'Standalone',
            ),
          ),
          Divider(),
          Expanded(
            child: AsyncRunnerWidget(
              'emscripten/native_example.js',
              'Emscripten',
            ),
          ),
        ],
      ),
    );
  }
}

class AsyncRunnerWidget extends StatefulWidget {
  final String wasmPath;
  final String name;
  const AsyncRunnerWidget(this.wasmPath, this.name, {super.key});

  @override
  State<AsyncRunnerWidget> createState() => _AsyncRunnerWidgetState();
}

class _AsyncRunnerWidgetState extends State<AsyncRunnerWidget> {
  final Map<String, String> _data = {};

  // Simulated asynchronous runner.
  Future<Map<String, String>> fetchValues() async {
    final runner = await Example.create('assets/${widget.wasmPath}');
    return {
      'Library Name': runner.getLibraryName(),
      'Hello String': runner.hello(widget.name),
      'Size of Int': runner.intSize().toString(),
      'Size of Bool': runner.boolSize().toString(),
      'Size of Pointer': runner.pointerSize().toString(),
      'Static Init Check': runner.staticInitCheck().toString(),
    };
  }

  // Load data using the asynchronous runner
  Future<void> _loadData() async {
    final values = await fetchValues();
    setState(() {
      _data.clear();
      _data.addAll(values);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData(); // Automatically fetch data on initialization
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test WasmFfi (${widget.name})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_data.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              ..._data.entries.map(
                (entry) => Text(
                  '${entry.key}: ${entry.value}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
