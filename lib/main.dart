import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FlutterBlueApp(),
    );
  }
}

class FlutterBlueApp extends StatelessWidget {
  const FlutterBlueApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: StreamBuilder<BluetoothAdapterState>(
          stream: FlutterBluePlus.adapterState,
          initialData: BluetoothAdapterState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothAdapterState.on) {
              FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
              return FindDeviceScreen();
            }
            return const Text('Error no bluetooth');
          }),
    );
  }
}

class FindDeviceScreen extends StatelessWidget {
  const FindDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scanning of device"),
      ),
      body: Column(
        children: [
          Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(width: 2, color: Colors.grey)),
                child: StreamBuilder<List<ScanResult>>(
                  stream: FlutterBluePlus.scanResults,
                  initialData: const [],
                  builder: (context, snapshot) => Column(
                    children: snapshot.data!
                        .map((d) => ListTile(
                            title: Text(d.device.localName),
                            subtitle: Card(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    d.device.localName,
                                    style: const TextStyle(
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  TextButton(
                                    child: const Icon(Icons.bluetooth),
                                    onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) {
                                      connectToDevice(d.device);
                                      d.device.discoverServices();
                                      return DeviceScreen(
                                          bluetoothDevice: d.device);
                                    })),
                                  )
                                ],
                              ),
                            )))
                        .toList(),
                  ),
                ),
              )),
        ],
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBluePlus.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
                onPressed: () => FlutterBluePlus.stopScan(),
                backgroundColor: Colors.red,
                child: const Icon(Icons.stop));
          } else {
            return FloatingActionButton(
                child: const Icon(Icons.search),
                onPressed: () => FlutterBluePlus.startScan(
                    timeout: const Duration(seconds: 4)));
          }
        },
      ),
    );
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
  }
}

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key, required this.bluetoothDevice});

  final BluetoothDevice bluetoothDevice;

  @override
  Widget build(BuildContext context) {
    if (bluetoothDevice.servicesList!.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Connected to ${bluetoothDevice.localName}"),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const Text(
                    'Device Name: ',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    bluetoothDevice.localName.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const Text(
                    'Axe X: ',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    bluetoothDevice
                        .servicesList!.first.characteristics.last.lastValue
                        .toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                ],
              ),
            ),
            TextButton.icon(
                onPressed: () => bluetoothDevice
                    .servicesList!.first.characteristics.last
                    .read(),
                icon: const Icon(Icons.update),
                label: const Text('Update'))
          ],
        ),
      );
    } else {
      return const Scaffold();
    }
  }
}
