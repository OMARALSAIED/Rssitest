import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ListViewDevices extends StatelessWidget {
  const ListViewDevices({
    super.key,
    required this.scanResults,
    required this.classroom,
  });

  final List<ScanResult> scanResults;
  final String classroom;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: scanResults.length,
        itemBuilder: (context, index) {
          final result = scanResults[index];
          return ListTile(
            title: Text(result.device.name ?? 'Unknown Device'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Device ID: ${result.device.id}'),
                Text('RSSI: ${result.rssi}'),
                Text('Classroom: ${classroom.isNotEmpty ? classroom : 'N/A'}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
