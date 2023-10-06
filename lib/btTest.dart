import 'dart:convert';
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
  List<String> serialOutput = [];
  BluetoothDevice? device;

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text('LED Control App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                connectToArduino();
              },
              child: Text('Connect to Arduino'),
            ),
            ElevatedButton(
              onPressed: () {
                sendCommand('LED1_ON');
              },
              child: Text('Turn On LED 1'),
            ),
            ElevatedButton(
              onPressed: () {
                sendCommand('LED2_ON');
              },
              child: Text('Turn On LED 2'),
            ),
            ElevatedButton(
              onPressed: () {
                sendCommand('LED_OFF');
              },
              child: Text('Turn Off LEDs'),
            ),
            SizedBox(height: 20),
            Text('Serial Output:'),
            Expanded(
              child: ListView.builder(
                itemCount: serialOutput.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(serialOutput[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void connectToArduino() async {
    try {
      // Find and connect to your Arduino device
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      }
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

      await FlutterBluePlus.startScan();

      await Future.delayed(Duration(seconds: 10), ()async{
        await FlutterBluePlus.stopScan();
      });

      await device!.connect();
      print('Connected to ${device?.platformName}');

      // Discover services
      List<BluetoothService> services = await device!.discoverServices();

      // Find the characteristic for receiving serial data
      BluetoothCharacteristic? receiveCharacteristic;
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            receiveCharacteristic = characteristic;
            break;
          }
        }
        if (receiveCharacteristic != null) {
          break;
        }
      }

      if (receiveCharacteristic != null) {
        // Listen to notifications from the Arduino
        receiveCharacteristic.setNotifyValue(true);
        receiveCharacteristic.lastValueStream.listen((data) {
          String message = utf8.decode(data);
          setState(() {
            serialOutput.add(message);
          });
        });
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void sendCommand(String command) async {
    if (device != null) {
      try {
        // Find the characteristic for writing data
        BluetoothCharacteristic? writeCharacteristic;
        List<BluetoothService> services = await device!.discoverServices();
        for (BluetoothService service in services) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.properties.write) {
              writeCharacteristic = characteristic;
              break;
            }
          }
          if (writeCharacteristic != null) {
            break;
          }
        }

        if (writeCharacteristic != null) {
          // Send the string command to the Arduino
          await writeCharacteristic.write(utf8.encode(command));
        } else {
          print('Write characteristic not found.');
        }
      } catch (error) {
        print('Error: $error');
      }
    } else {
      print('Device not connected');
    }
  }

//   Future<void> _toggleLED() async {
//     if (Platform.isAndroid) {
//       await FlutterBluePlus.turnOn();
//     }
//     BluetoothDevice device = BluetoothDevice(remoteId: DeviceIdentifier(''));
//
//
// // Start scanning
// // Note: You should always call `scanResults.listen` before you call startScan!
//
//
//     final service = await device.discoverServices().then((services) => services[0]);
//     final characteristic = await service.characteristics
//         .firstWhere((c) => c.uuid.toString() == "0000ffe1-0000-1000-8000-00805f9b34fb");
//
//     final newValue = isLEDOn ? '0' : '1';
//     await characteristic.write(newValue.codeUnits);
//     await device.disconnect();
//     setState(() {
//       isLEDOn = !isLEDOn;
//     });
//   }
}
