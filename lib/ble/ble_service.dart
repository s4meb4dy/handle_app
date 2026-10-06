import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/gear_position.dart';
import 'ble_protocol.dart';
import 'ble_permissions.dart';

class BleService {
  // ============================================================
  // ESP32 BLE UUID
  // ============================================================
  //
  // ПОКА здесь стоят временные UUID.
  //
  // Если в твоём ESP32 скетче уже есть реальные UUID —
  // позже заменим их здесь.
  //
  // При этом ниже есть автоматический поиск характеристик,
  // поэтому приложение сможет работать даже если UUID
  // пока не совпадают.
  // ============================================================

  static const String serviceUuid =
      '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

  static const String commandCharacteristicUuid =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

  static const String statusCharacteristicUuid =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  // ============================================================
  // BLE OBJECTS
  // ============================================================

  BluetoothDevice? device;

  BluetoothCharacteristic? commandCharacteristic;

  BluetoothCharacteristic? statusCharacteristic;

  StreamSubscription<List<ScanResult>>? scanSubscription;

  StreamSubscription<BluetoothConnectionState>?
      connectionSubscription;

  StreamSubscription<List<int>>? statusSubscription;

  // ============================================================
  // STREAMS
  // ============================================================

  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  final StreamController<List<GearPosition>> _gearController =
      StreamController<List<GearPosition>>.broadcast();

  Stream<String> get statusStream => _statusController.stream;

  Stream<List<GearPosition>> get gearsStream =>
      _gearController.stream;

  // ============================================================
  // STATE
  // ============================================================

  bool get isConnected => device != null;

  final List<GearPosition> _gears = [];

  List<GearPosition> get gears =>
      List.unmodifiable(_gears);

  // ============================================================
  // SCAN
  // ============================================================

  Future<List<ScanResult>> scan() async {
    final results = <ScanResult>[];

    // На всякий случай останавливаем старое сканирование.
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    await scanSubscription?.cancel();
    scanSubscription = null;

    scanSubscription =
        FlutterBluePlus.scanResults.listen((items) {
      for (final result in items) {
        final alreadyExists = results.any(
          (r) => r.device.remoteId ==
              result.device.remoteId,
        );

        if (!alreadyExists) {
          results.add(result);

          final name =
              result.advertisementData.advName;

          print(
            'BLE DEVICE: '
            '${result.device.remoteId} '
            '"$name" '
            'RSSI=${result.rssi}',
          );
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
      );

      await Future.delayed(
        const Duration(seconds: 5),
      );

      await FlutterBluePlus.stopScan();
    } finally {
      await scanSubscription?.cancel();
      scanSubscription = null;
    }

    return results;
  }

  // ============================================================
  // CONNECT
  // ============================================================

  Future<void> connect(
    BluetoothDevice target,
  ) async {
    await disconnect();

    device = target;

    print('');
    print('========================================');
    print('CONNECTING TO HANDLE');
    print('DEVICE: ${target.remoteId}');
    print('========================================');

    try {
      await target.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );
    } catch (e) {
      print('BLE CONNECT ERROR: $e');

      device = null;

      rethrow;
    }

    print('BLE CONNECTED');

    // ----------------------------------------------------------
    // CONNECTION STATE
    // ----------------------------------------------------------

    connectionSubscription =
        target.connectionState.listen(
      (state) {
        print(
          'BLE CONNECTION STATE: $state',
        );

        if (state ==
            BluetoothConnectionState.disconnected) {
          device = null;
          commandCharacteristic = null;
          statusCharacteristic = null;

          statusSubscription?.cancel();
          statusSubscription = null;
        }
      },
    );

    // ----------------------------------------------------------
    // DISCOVER SERVICES
    // ----------------------------------------------------------

    final services =
        await target.discoverServices();

    print('');
    print('========================================');
    print('BLE SERVICES');
    print('========================================');

    for (final service in services) {
      print(
        'SERVICE: ${service.uuid.str128}',
      );

      for (final characteristic
          in service.characteristics) {
        print(
          '  CHARACTERISTIC: '
          '${characteristic.uuid.str128}',
        );

        print(
          '    read=${characteristic.properties.read} '
          'write=${characteristic.properties.write} '
          'writeNR='
          '${characteristic.properties.writeWithoutResponse} '
          'notify=${characteristic.properties.notify} '
          'indicate=${characteristic.properties.indicate}',
        );
      }
    }

    print('========================================');

    // ----------------------------------------------------------
    // СНАЧАЛА ИЩЕМ ПО UUID
    // ----------------------------------------------------------

    for (final service in services) {
      final currentServiceUuid =
          service.uuid.str128.toLowerCase();

      if (currentServiceUuid !=
          serviceUuid.toLowerCase()) {
        continue;
      }

      for (final characteristic
          in service.characteristics) {
        final uuid =
            characteristic.uuid.str128.toLowerCase();

        if (uuid ==
            commandCharacteristicUuid
                .toLowerCase()) {
          commandCharacteristic =
              characteristic;
        }

        if (uuid ==
            statusCharacteristicUuid
                .toLowerCase()) {
          statusCharacteristic =
              characteristic;
        }
      }
    }

    // ----------------------------------------------------------
    // ЕСЛИ UUID НЕ СОВПАЛИ —
    // АВТОМАТИЧЕСКИ ИЩЕМ ПОДХОДЯЩИЕ
    // ----------------------------------------------------------

    if (commandCharacteristic == null ||
        statusCharacteristic == null) {
      print('');
      print(
        'BLE UUID NOT MATCHED. '
        'USING AUTOMATIC DISCOVERY...',
      );

      for (final service in services) {
        for (final characteristic
            in service.characteristics) {
          // Командная характеристика:
          // должна поддерживать WRITE.
          if (commandCharacteristic == null &&
              (characteristic.properties.write ||
                  characteristic.properties
                      .writeWithoutResponse)) {
            commandCharacteristic =
                characteristic;

            print(
              'AUTO WRITE CHARACTERISTIC: '
              '${characteristic.uuid.str128}',
            );
          }

          // Статусная характеристика:
          // должна поддерживать NOTIFY.
          if (statusCharacteristic == null &&
              (characteristic.properties.notify ||
                  characteristic.properties
                      .indicate)) {
            statusCharacteristic =
                characteristic;

            print(
              'AUTO STATUS CHARACTERISTIC: '
              '${characteristic.uuid.str128}',
            );
          }
        }
      }
    }

    // ----------------------------------------------------------
    // ПРОВЕРЯЕМ РЕЗУЛЬТАТ
    // ----------------------------------------------------------

    print('');
    print('========================================');
    print('BLE CHARACTERISTICS');
    print('========================================');

    print(
      'COMMAND: '
      '${commandCharacteristic?.uuid.str128 ?? "NOT FOUND"}',
    );

    print(
      'STATUS: '
      '${statusCharacteristic?.uuid.str128 ?? "NOT FOUND"}',
    );

    print('========================================');

    if (commandCharacteristic == null) {
      throw Exception(
        'COMMAND characteristic not found',
      );
    }

    if (statusCharacteristic == null) {
      throw Exception(
        'STATUS characteristic not found',
      );
    }

    // ----------------------------------------------------------
    // NOTIFICATIONS
    // ----------------------------------------------------------

    await statusCharacteristic!.setNotifyValue(
      true,
    );

    await statusSubscription?.cancel();

    statusSubscription =
        statusCharacteristic!.lastValueStream.listen(
      _onStatusReceived,
    );

    print(
      'STATUS notifications enabled',
    );

    // ----------------------------------------------------------
    // ПОЛУЧАЕМ CONFIG
    // ----------------------------------------------------------

    try {
      await send(BleProtocol.getConfig);
    } catch (e) {
      print(
        'GET CONFIG ERROR: $e',
      );
    }
  }

  // ============================================================
  // STATUS RECEIVED
  // ============================================================

  void _onStatusReceived(
    List<int> bytes,
  ) {
    if (bytes.isEmpty) {
      return;
    }

    final text = utf8.decode(
      bytes,
      allowMalformed: true,
    ).trim();

    if (text.isEmpty) {
      return;
    }

    print(
      'BLE RX: $text',
    );

    _statusController.add(text);

    _parseStatus(text);
  }

  // ============================================================
  // PARSE STATUS
  // ============================================================

  void _parseStatus(
    String text,
  ) {
    final lines = text.split('\n');

    for (final line in lines) {
      final clean = line.trim();

      if (clean.isEmpty) {
        continue;
      }

      // --------------------------------------------------------
      // CONFIGURATION LINE
      // --------------------------------------------------------

      if (clean.startsWith('CFG;')) {
        try {
          final gear =
              GearPosition.fromBle(clean);

          if (gear.gear.isEmpty) {
            continue;
          }

          _gears.removeWhere(
            (item) => item.gear == gear.gear,
          );

          _gears.add(gear);

          _gearController.add(
            List.unmodifiable(_gears),
          );
        } catch (e) {
          print(
            'CFG PARSE ERROR: $e',
          );
        }
      }
    }
  }

  // ============================================================
  // SEND COMMAND
  // ============================================================

  Future<void> send(
    String command,
  ) async {
    final characteristic =
        commandCharacteristic;

    if (characteristic == null) {
      throw Exception(
        'HANDLE is not connected',
      );
    }

    final bytes = utf8.encode(command);

    print(
      'BLE TX: $command',
    );

    await characteristic.write(
      bytes,
      withoutResponse: false,
    );
  }

  // ============================================================
  // GEAR COMMANDS
  // ============================================================

  Future<void> saveGear(
    String gear,
  ) async {
    await send(
      BleProtocol.saveGear(gear),
    );
  }

  Future<void> deleteGear(
    String gear,
  ) async {
    await send(
      BleProtocol.deleteGear(gear),
    );
  }

  Future<void> deleteAllGears() async {
    await send(
      BleProtocol.deleteAll,
    );
  }

  Future<void> refreshConfig() async {
    await send(
      BleProtocol.getConfig,
    );
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  Future<void> setDelay(
    int milliseconds,
  ) async {
    await send(
      BleProtocol.setDelay(
        milliseconds,
      ),
    );
  }

  Future<void> setZone(
    double degrees,
  ) async {
    await send(
      BleProtocol.setZone(
        degrees,
      ),
    );
  }

  // ============================================================
  // SCENE
  // ============================================================

  Future<void> setScene(
    String scene,
  ) async {
    await send(
      BleProtocol.setScene(
        scene,
      ),
    );
  }

  // ============================================================
  // DISCONNECT
  // ============================================================

  Future<void> disconnect() async {
    await statusSubscription?.cancel();
    statusSubscription = null;

    await connectionSubscription?.cancel();
    connectionSubscription = null;

    if (device != null) {
      try {
        await device!.disconnect();
      } catch (_) {}
    }

    device = null;

    commandCharacteristic = null;
    statusCharacteristic = null;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    scanSubscription?.cancel();
    scanSubscription = null;

    statusSubscription?.cancel();
    statusSubscription = null;

    connectionSubscription?.cancel();
    connectionSubscription = null;

    _statusController.close();
    _gearController.close();
  }
}