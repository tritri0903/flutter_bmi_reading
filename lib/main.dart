import 'dart:developer';

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
      body: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(width: 2, color: Colors.grey)),
        child: StreamBuilder<List<ScanResult>>(
          stream: FlutterBluePlus.scanResults,
          initialData: const [],
          builder: (context, snapshot) => Column(
            children: snapshot.data!.map((d) {
              if (d.device.localName.isNotEmpty) {
                return Card(
                  child: ListTile(
                    title: Text(
                      d.device.localName,
                      style: const TextStyle(
                          fontSize: 15.0, fontWeight: FontWeight.w500),
                    ),
                    trailing: TextButton(
                      child: const Icon(Icons.bluetooth),
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) {
                        connectToDevice(d.device);
                        return DeviceScreen(bluetoothDevice: d.device);
                      })),
                    ),
                  ),
                );
              } else {
                return ListTile(
                  title: Text(d.device.remoteId.toString()),
                );
              }
            }).toList(),
          ),
        ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Connected to ${bluetoothDevice.localName}"),
      ),
      body: StreamBuilder<BluetoothConnectionState>(
          stream: bluetoothDevice.connectionState,
          builder: (context, snapshot) {
            if (snapshot.data == BluetoothConnectionState.connected) {
              bluetoothDevice.discoverServices();
              return SingleChildScrollView(
                child: Column(
                  children: [
                    StreamBuilder<List<BluetoothService>>(
                      stream: bluetoothDevice.servicesStream,
                      initialData: [],
                      builder: (context, snapshot) {
                        if (snapshot.data!.isNotEmpty) {
                          return Column(
                            children: _buildService(snapshot.data!),
                          );
                        } else {
                          return const CircularProgressIndicator();
                        }
                      },
                    ),
                  ],
                ),
              );
            } else {
              return const CircularProgressIndicator();
            }
          }),
    );
  }
}

List<Widget> _buildService(List<BluetoothService> services) {
  return services.map((s) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 4.0),
        color: Colors.grey,
      ),
      child: ListTile(
        title: Text(s.serviceUuid.toString()),
        subtitle: Builder(builder: (context) {
          return Column(
            children: s.characteristics.map((e) {
              return ListTile(
                title: const Text("Axe X:"),
                trailing: Text(e.lastValue.toString()),
              );
            }).toList(),
          );
        }),
      ),
    );
  }).toList();
}
