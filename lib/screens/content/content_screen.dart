import 'package:flutter/material.dart';

import '../../ble/ble_service.dart';
import 'image_screen.dart';

class ContentScreen extends StatelessWidget {
  final BleService bleService;

  const ContentScreen({
    super.key,
    required this.bleService,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Контент',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Выберите, что будет отображаться на экране ручки.',
          style: TextStyle(
            color: Colors.white60,
          ),
        ),

        const SizedBox(height: 28),

        _SceneCard(
          icon: Icons.settings_input_component,
          title: 'Передачи',
          subtitle:
              'Показывать текущую передачу',

          onTap: () {
            bleService.setScene('GEAR');

            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  'Сцена "Передачи" выбрана',
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        _SceneCard(
          icon: Icons.image_outlined,
          title: 'Картинка',
          subtitle:
              'Выбрать изображение для экрана',

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImageScreen(
                  bleService: bleService,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        _SceneCard(
          icon: Icons.gif_box_outlined,
          title: 'GIF',
          subtitle:
              'Анимированная сцена',

          enabled: false,

          onTap: () {},
        ),
      ],
    );
  }
}

class _SceneCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const _SceneCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: enabled ? onTap : null,

        borderRadius:
            BorderRadius.circular(16),

        child: Padding(
          padding:
              const EdgeInsets.all(18),

          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,

                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.12),

                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                child: Icon(
                  icon,
                  color: enabled
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                      : Colors.white30,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color:
                            Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),

              if (enabled)
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white54,
                )
              else
                const Text(
                  'Скоро',
                  style: TextStyle(
                    color: Colors.white38,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}