import 'package:permission_handler/permission_handler.dart';

class BlePermissions {
  static Future<bool> request() async {
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();

    return scan.isGranted && connect.isGranted;
  }
}