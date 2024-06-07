import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scanner_test_rssi/file_service.dart';
import 'package:scanner_test_rssi/list_view.dart';


class DataSetHandeling extends StatefulWidget {
  @override
  _DataSetHandelingState createState() => _DataSetHandelingState();
}

class _DataSetHandelingState extends State<DataSetHandeling> {
  List<ScanResult> scanResults = [];
  Map<String, int> lastRssiValues = {};
  StreamSubscription<List<ScanResult>>? scanSubscription;
  bool isScanning = false;
  bool isAutoScanning = false;
  TextEditingController classroomController = TextEditingController();
  String classroom = '';
  String savedData = '';
  List<String> rssiChanges = [];
  Timer? writeTimer;

  @override
  void dispose() {
    scanSubscription?.cancel();
    classroomController.dispose();
    writeTimer?.cancel();
    super.dispose();
  }

  void _startScan() async {
    setState(() {
      isScanning = true;
    });
    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        int index = scanResults.indexWhere((r) => r.device.id == result.device.id);
        if (index >= 0) {
          if (scanResults[index].rssi != result.rssi) {
            scanResults[index] = result;
            _logRssiChange(result);
          }
        } else {
          scanResults.add(result);
          _logRssiChange(result);
        }
      }
      setState(() {}); // تحديث الواجهة فقط بعد معالجة كل النتائج
    });

    await FlutterBluePlus.startScan(
      androidScanMode: AndroidScanMode.lowLatency,
    );
  }

  void _stopScan() async {
    setState(() {
      isScanning = false;
    });
    await FlutterBluePlus.stopScan();
    scanSubscription?.cancel();
  }

  void _toggleAutoScan() {
    setState(() {
      isAutoScanning = !isAutoScanning;
    });
    if (isAutoScanning) {
      _startScan();
    } else {
      _stopScan();
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/ble_data.txt');
  }

  Future<void> _writeDataBatch() async {
    if (rssiChanges.isNotEmpty) {
      final file = await _localFile;
      await file.writeAsString(rssiChanges.join('\n') + '\n', mode: FileMode.writeOnlyAppend);
      rssiChanges.clear();
    }
  }

  void _logRssiChange(ScanResult result) {
    String data = jsonEncode({
      'device_name': result.device.name,
      'device_id': result.device.id.toString(),
      'rssi': result.rssi,
      'timestamp': DateTime.now().toIso8601String(),
      'classroom': classroom.isNotEmpty ? classroom : 'N/A',
    });
    rssiChanges.add(data);

    // جدولة الكتابة إلى الملف بشكل دوري
    writeTimer?.cancel();
    writeTimer = Timer(Duration(seconds: 5), _writeDataBatch);
  }

  Future<void> _saveData() async {
    List<Map<String, dynamic>> data = scanResults.map((result) {
      return {
        'device_name': result.device.name,
        'device_id': result.device.id.toString(),
        'rssi': result.rssi,
        'classroom': classroom.isNotEmpty ? classroom : 'N/A',
      };
    }).toList();

    String jsonData = jsonEncode(data);
    await FileService.writeData('ble_data.txt', jsonData + '\n');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data saved successfully')),
    );
  }

  Future<void> _readData() async {
    String contents = await FileService.readData('ble_data.txt');
    setState(() {
      savedData = contents;
    });
  }

  Future<void> _exportData() async {
    await FileService.exportData('ble_data.txt');
  }

  Future<void> _resetData() async {
    try {
      final file = await _localFile;
      await file.writeAsString('');
      setState(() {
        savedData = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data reset successfully')),
      );
    } catch (e) {
      print('Error resetting data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reset data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BLE Scanner'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: classroomController,
              decoration: InputDecoration(
                labelText: 'Enter Classroom Number',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  classroom = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _resetData,
              child: Text("Reset"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _toggleAutoScan,
              child: Text(isAutoScanning ? 'Stop Auto Scan' : 'Start Auto Scan'),
            ),
          ),
          Expanded(
            child: ListViewDevices(scanResults: scanResults, classroom: classroom),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _saveData,
                  child: Text('Save'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _readData,
                  child: Text('Read Data'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _exportData,
                  child: Text('Export'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Saved Data:'),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Text(savedData),
            ),
          ),
        ],
      ),
    );
  }
}
