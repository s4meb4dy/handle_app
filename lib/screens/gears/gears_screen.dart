import 'dart:async';

import 'package:flutter/material.dart';

import '../../ble/ble_service.dart';
import '../../models/gear_position.dart';

class GearsScreen extends StatefulWidget {
  final BleService bleService;

  const GearsScreen({
    super.key,
    required this.bleService,
  });

  @override
  State<GearsScreen> createState() => _GearsScreenState();
}

class _GearsScreenState extends State<GearsScreen> {
  final List<String> gears = [
    'N',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    'R',
  ];

  String selectedGear = '1';

  double zone = 15.0;

  int delay = 300;

  List<GearPosition> savedPositions = [];

  StreamSubscription<List<GearPosition>>? gearSubscription;

  @override
  void initState() {
    super.initState();

    gearSubscription =
        widget.bleService.gearsStream.listen((items) {
      if (!mounted) return;

      setState(() {
        savedPositions = items;
      });
    });
  }

  @override
  void dispose() {
    gearSubscription?.cancel();
    super.dispose();
  }

  bool isSaved(String gear) {
    return savedPositions.any(
      (item) => item.gear == gear && item.configured,
    );
  }

  GearPosition? getPosition(String gear) {
    for (final item in savedPositions) {
      if (item.gear == gear) {
        return item;
      }
    }

    return null;
  }

  Future<void> saveSelectedGear() async {
    try {
      await widget.bleService.saveGear(
        selectedGear,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Положение $selectedGear сохраняется...',
          ),
        ),
      );
    } catch (e) {
      showError(e);
    }
  }

  Future<void> deleteGear(String gear) async {
    try {
      await widget.bleService.deleteGear(gear);
    } catch (e) {
      showError(e);
    }
  }

  Future<void> deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить все передачи?'),
          content: const Text(
            'Все сохранённые положения будут удалены.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await widget.bleService.deleteAllGears();

      if (!mounted) return;

      setState(() {
        savedPositions.clear();
      });
    } catch (e) {
      showError(e);
    }
  }

  void showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPosition = getPosition(selectedGear);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Передачи',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            _ConnectionIndicator(
              connected: widget.bleService.isConnected,
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          'Настройка положений ручки',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(
                color: Colors.white60,
              ),
        ),

        const SizedBox(height: 28),

        _SettingsCard(
          title: 'Задержка смены картинки',
          subtitle:
              'Защита от кратковременного проскакивания передачи',

          value: '$delay мс',

          child: Slider(
            min: 50,
            max: 1000,
            divisions: 19,
            value: delay.toDouble(),
            label: '$delay мс',

            onChanged: (value) {
              setState(() {
                delay = value.round();
              });
            },

            onChangeEnd: (value) {
              widget.bleService.setDelay(
                value.round(),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        _SettingsCard(
          title: 'Зона передачи',
          subtitle:
              'Чем больше зона, тем проще попасть в передачу',

          value: '${zone.toStringAsFixed(0)}°',

          child: Slider(
            min: 5,
            max: 30,
            divisions: 25,
            value: zone,

            label:
                '${zone.toStringAsFixed(0)}°',

            onChanged: (value) {
              setState(() {
                zone = value;
              });
            },

            onChangeEnd: (value) {
              widget.bleService.setZone(
                value,
              );
            },
          ),
        ),

        const SizedBox(height: 30),

        const Text(
          'Выберите передачу',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 14),

        GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),

          itemCount: gears.length,

          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.25,
          ),

          itemBuilder: (context, index) {
            final gear = gears[index];

            final selected =
                gear == selectedGear;

            final saved =
                isSaved(gear);

            return _GearButton(
              gear: gear,
              selected: selected,
              saved: saved,

              onPressed: () {
                setState(() {
                  selectedGear = gear;
                });
              },
            );
          },
        ),

        const SizedBox(height: 20),

        if (selectedPosition?.configured == true)
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      selectedGear,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Text(
                      'X = ${selectedPosition!.x!.toStringAsFixed(2)}°\n'
                      'Y = ${selectedPosition.y!.toStringAsFixed(2)}°',
                    ),
                  ),

                  IconButton(
                    tooltip: 'Удалить',
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                    onPressed: () {
                      deleteGear(
                        selectedGear,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 14),

        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: saveSelectedGear,
            icon: const Icon(
              Icons.save_outlined,
            ),
            label: Text(
              'Сохранить $selectedGear',
            ),
          ),
        ),

        const SizedBox(height: 14),

        OutlinedButton.icon(
          onPressed: () {
            widget.bleService.refreshConfig();
          },
          icon: const Icon(
            Icons.refresh,
          ),
          label: const Text(
            'Обновить сохранённые позиции',
          ),
        ),

        const SizedBox(height: 12),

        TextButton.icon(
          onPressed: deleteAll,
          icon: const Icon(
            Icons.delete_sweep_outlined,
          ),
          label: const Text(
            'Удалить все передачи',
          ),
        ),
      ],
    );
  }
}

class _GearButton extends StatelessWidget {
  final String gear;
  final bool selected;
  final bool saved;
  final VoidCallback onPressed;

  const _GearButton({
    required this.gear,
    required this.selected,
    required this.saved,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,

      style: FilledButton.styleFrom(
        backgroundColor: selected
            ? Theme.of(context)
                .colorScheme
                .primary
            : const Color(0xFF191D23),

        foregroundColor: selected
            ? Colors.white
            : Colors.white70,

        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
      ),

      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Text(
            gear,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (saved)
            const Icon(
              Icons.check,
              size: 15,
            ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final Widget child;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  value,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            child,
          ],
        ),
      ),
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  final bool connected;

  const _ConnectionIndicator({
    required this.connected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: connected
            ? Colors.green.withOpacity(0.15)
            : Colors.red.withOpacity(0.15),

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 9,
            color: connected
                ? Colors.green
                : Colors.red,
          ),

          const SizedBox(width: 6),

          Text(
            connected
                ? 'Подключено'
                : 'Нет связи',
            style:
                const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}