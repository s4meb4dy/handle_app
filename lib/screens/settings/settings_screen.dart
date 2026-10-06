import 'package:flutter/material.dart';

import '../../ble/ble_service.dart';

class SettingsScreen extends StatelessWidget {
  final BleService bleService;

  const SettingsScreen({
    super.key,
    required this.bleService,
  });

  Future<void> connect(BuildContext context) async {
    try {
      final results =
          await bleService.scan();

      if (!context.mounted) {
        return;
      }

      if (results.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'BLE-устройства не найдены',
            ),
          ),
        );

        return;
      }

      final selected =
          await showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            child: ListView(
              shrinkWrap: true,

              children: results.map(
                (result) {
                  final name =
                      result.device.platformName;

                  return ListTile(
                    leading: const Icon(
                      Icons.bluetooth,
                    ),

                    title: Text(
                      name.isEmpty
                          ? 'Без имени'
                          : name,
                    ),

                    subtitle: Text(
                      result.device.remoteId
                          .toString(),
                    ),

                    onTap: () {
                      Navigator.pop(
                        context,
                        result.device,
                      );
                    },
                  );
                },
              ).toList(),
            ),
          );
        },
      );

      if (selected == null) {
        return;
      }

      await bleService.connect(
        selected,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'HANDLE подключён',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка подключения: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),

      children: [
        const Text(
          'Настройки',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Подключение и технические настройки.',
          style: TextStyle(
            color: Colors.white60,
          ),
        ),

        const SizedBox(height: 28),

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.bluetooth,
            ),

            title: const Text(
              'HANDLE',
            ),

            subtitle: Text(
              bleService.isConnected
                  ? 'Подключено'
                  : 'Не подключено',
            ),

            trailing: FilledButton(
              onPressed: () {
                connect(context);
              },

              child: Text(
                bleService.isConnected
                    ? 'Переподключить'
                    : 'Подключить',
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                ),

                title: const Text(
                  'Версия приложения',
                ),

                trailing: const Text(
                  '0.1.0',
                ),
              ),

              const Divider(
                height: 1,
              ),

              ListTile(
                leading: const Icon(
                  Icons.developer_board_outlined,
                ),

                title: const Text(
                  'Устройство',
                ),

                trailing: const Text(
                  'ESP32-C3',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}