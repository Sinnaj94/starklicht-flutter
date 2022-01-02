import 'dart:async';
import 'package:rxdart/rxdart.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_blue/flutter_blue.dart';
import '../messages/imessage.dart';
const serviceUUID = "0000ffe0-0000-1000-8000-00805f9b34fb";
const characterUUID = "0000ffe1-0000-1000-8000-00805f9b34fb";




abstract class BluetoothController<T> {
  Stream<T> scan(int duration);
  Future stopScan();
  void connect(T device);
  int broadcast(IBluetoothMessage m);
  bool send(IBluetoothMessage m, T device);
  Stream<bool> scanning();
  Stream<T> getConnectionStream();
  Future<List<T>> connectedDevicesStream();
  Stream<BluetoothState> stateStream();
}

class BluetoothControllerWidget implements BluetoothController<BluetoothDevice> {
  static final BluetoothControllerWidget _instance = BluetoothControllerWidget._internal();
  factory BluetoothControllerWidget() => _instance;

  BluetoothControllerWidget._internal();

  FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamController<BluetoothDevice> lamps = BehaviorSubject();
  StreamController<BluetoothDevice> connectionStream = BehaviorSubject();
  final Map<BluetoothDevice, BluetoothCharacteristic> deviceMap = {};
  Stopwatch stopwatch = Stopwatch()..start();

  @override
  Stream<BluetoothDevice> scan(int duration) {
    flutterBlue.scan(timeout: Duration(seconds: duration)).listen((res) {
      if(res.advertisementData.serviceUuids.contains(serviceUUID)) {
        lamps.add(res.device);
      }
    });
    return lamps.stream;
  }

  @override
  void connect(BluetoothDevice device) async {
    await device.connect();
    List<BluetoothService> services = await device.discoverServices();
    var s = services.firstWhere((service) => service.uuid == Guid(serviceUUID));
    var c = s.characteristics.firstWhere((characteristic) => characteristic.uuid == Guid(characterUUID));
    deviceMap[device] = c;
    connectionStream.add(device);
  }

  @override
  Future stopScan() {
    return flutterBlue.stopScan();
  }

  bool canSend() {
    return stopwatch.elapsedMilliseconds > 20;
  }

  @override
  int broadcast(IBluetoothMessage m) {
    if (canSend()) {
      deviceMap.forEach((key, value) {
        m.send(value);
      });
      print(stopwatch.elapsedMilliseconds);
      stopwatch = Stopwatch()..start();
    }
    return deviceMap.length;
  }

  @override
  bool send(IBluetoothMessage m, BluetoothDevice device) {
    return false;
  }

  @override
  Stream<bool> scanning() {
    return flutterBlue.isScanning;
  }

  @override
  Stream<BluetoothDevice> getConnectionStream() {
    return connectionStream.stream;
  }

  @override
  Future<List<BluetoothDevice>> connectedDevicesStream() {
    return flutterBlue.connectedDevices;
  }

  @override
  Stream<BluetoothState> stateStream() {
    return flutterBlue.state;
  }
}