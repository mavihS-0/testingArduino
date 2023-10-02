import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class LEDControlScreen extends StatefulWidget {
  @override
  _LEDControlScreenState createState() => _LEDControlScreenState();
}

class _LEDControlScreenState extends State<LEDControlScreen> {
  final String deviceName = "YourBluetoothDeviceName"; // Replace with your device name
  bool isLEDOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LED Control'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('LED Status: ${isLEDOn ? 'On' : 'Off'}'),
            ElevatedButton(
              onPressed: () => _toggleLED(),
              child: Text(isLEDOn ? 'Turn Off LED' : 'Turn On LED'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLED() async {
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
    BluetoothDevice device = BluetoothDevice(remoteId: DeviceIdentifier(''));
    var subscription = FlutterBluePlus.scanResults.listen(
            (results)  {
          for (ScanResult r in results) {
            print(r.device.platformName);
            if(r.device.platformName ==  deviceName){
              device = r.device;

            }
          }
        },
    ).onError((e){
      print(e.toString());
    });

// Start scanning
// Note: You should always call `scanResults.listen` before you call startScan!
    await FlutterBluePlus.startScan();
    // await device.connect();
// Stop scanning
    Future.delayed(Duration(seconds: 10), ()async{
      await FlutterBluePlus.stopScan();
    });

    final service = await device.discoverServices().then((services) => services[0]);
    final characteristic = await service.characteristics
        .firstWhere((c) => c.uuid.toString() == "0000ffe1-0000-1000-8000-00805f9b34fb");

    final newValue = isLEDOn ? '0' : '1';
    await characteristic.write(newValue.codeUnits);
    await device.disconnect();
    setState(() {
      isLEDOn = !isLEDOn;
    });
  }
}
