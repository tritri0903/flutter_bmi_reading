import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:o3d/o3d.dart';
import 'package:flutter_cube/flutter_cube.dart';

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
      home: DefaultTabController(
          length: 2,
          child: Scaffold(
            body: TabBarView(children: [
              const FlutterBlueApp(),
              ConnectedDevice(),
            ]),
            bottomNavigationBar: const TabBar(tabs: [
              Tab(icon: Icon(Icons.search)),
              Tab(icon: Icon(Icons.connected_tv))
            ]),
          )),
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
              //FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
              return const FindDeviceScreen();
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
                      child: const Icon(Icons.ac_unit),
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) {
                        d.device.connect();
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
}

class ConnectedDevice extends StatefulWidget {
  ConnectedDevice({super.key});

  @override
  State<ConnectedDevice> createState() => _ConnectedDeviceState();
}

class _ConnectedDeviceState extends State<ConnectedDevice>
    with SingleTickerProviderStateMixin {
  // to control the animation
  final O3DController controller = O3DController();

  late Object _cube;
  late Scene _scene;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: Duration(milliseconds: 3000), vsync: this)
          ..addListener(() {
            _cube.rotation.y = _controller.value * 360;
            _cube.position.x = _controller.value * 12 - 5;
            _cube.updateTransform();
            _scene.update();
          })
          ..repeat();
  }

  void _onSceneCreated(Scene scene) {
    _scene = scene;
    _cube = Object(
        position: Vector3(-5, 0, 0),
        scale: Vector3(1.0, 1.0, 1.0),
        backfaceCulling: false,
        fileName: 'assets/cube/cube.obj');
    scene.world.add(_cube);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 500,
          child: Cube(
            onSceneCreated: _onSceneCreated,
          ),
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(width: 2, color: Colors.grey)),
          child: StreamBuilder<List<BluetoothDevice>>(
            stream: Stream.periodic(const Duration(seconds: 2))
                .asyncMap((_) => FlutterBluePlus.connectedSystemDevices),
            initialData: const [],
            builder: (context, snapshot) => Column(
              children: snapshot.data!.map((d) {
                if (d.localName.isNotEmpty) {
                  return Card(
                    child: ListTile(
                      title: Text(
                        d.localName,
                        style: const TextStyle(
                            fontSize: 15.0, fontWeight: FontWeight.w500),
                      ),
                      trailing: TextButton(
                        child: const Icon(Icons.ac_unit),
                        onPressed: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (context) {
                          d.connect();
                          return DeviceScreen(bluetoothDevice: d);
                        })),
                      ),
                    ),
                  );
                } else {
                  return ListTile(
                    title: Text(d.remoteId.toString()),
                  );
                }
              }).toList(),
            ),
          ),
        )
      ],
    );
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
      body: Container(
        margin: const EdgeInsets.all(8.0),
        child: StreamBuilder<BluetoothConnectionState>(
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
                            return const Center(
                                child: Column(
                              children: [
                                CircularProgressIndicator(),
                                Text("Looking for characteristics")
                              ],
                            ));
                          }
                        },
                      ),
                    ],
                  ),
                );
              } else {
                return Center(
                  child: Column(
                    children: const [
                      CircularProgressIndicator(),
                      Text("Waiting for connection")
                    ],
                  ),
                );
              }
            }),
      ),
    );
  }
}

List<Widget> _buildService(List<BluetoothService> services) {
  return services.map((s) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 4.0),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: ListTile(
        title: Text(s.serviceUuid.toString()),
        subtitle: SizedBox(
          child: Column(
            children: s.characteristics.map((c) {
              //c.read();
              //c.setNotifyValue(true);
              return StreamBuilder<List<int>>(
                  stream: c.lastValueStream,
                  initialData: c.lastValue,
                  builder: (context, snapshot) {
                    return ListTile(
                      title: Text(c.descriptors.first.lastValue.toString()),
                      trailing: Text(floatToString(snapshot.data)),
                    );
                  });
            }).toList(),
          ),
        ),
      ),
    );
  }).toList();
}

String floatToString(data) {
  final bytes = Uint8List.fromList(data);
  final byteData = ByteData.sublistView(bytes);
  double value = byteData.getFloat32(0, Endian.little);
  return value.toStringAsFixed(3);
}
