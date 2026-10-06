import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../ble/ble_service.dart';

class ImageScreen extends StatefulWidget {
  final BleService bleService;

  const ImageScreen({
    super.key,
    required this.bleService,
  });

  @override
  State<ImageScreen> createState() =>
      _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  final CropController cropController =
      CropController();

  Uint8List? originalImage;

  Uint8List? croppedImage;

  bool processing = false;

  Future<void> selectImage() async {
    final picker = ImagePicker();

    final file = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();

    setState(() {
      originalImage = bytes;
      croppedImage = null;
    });
  }

  Future<void> cropImage() async {
    cropController.crop();
  }

  Future<void> onCropped(
    CropResult result,
  ) async {
    if (result is! CropSuccess) {
      return;
    }

    setState(() {
      processing = true;
    });

    try {
      final normalized =
          normalizeImage(
        result.croppedImage,
      );

      setState(() {
        croppedImage = normalized;
      });
    } finally {
      setState(() {
        processing = false;
      });
    }
  }

  Uint8List normalizeImage(
    Uint8List bytes,
  ) {
    final decoded =
        img.decodeImage(bytes);

    if (decoded == null) {
      throw Exception(
        'Не удалось обработать изображение',
      );
    }

    final resized =
        img.copyResize(
      decoded,
      width: 240,
      height: 240,
      interpolation:
          img.Interpolation.linear,
    );

    return Uint8List.fromList(
      img.encodeJpg(
        resized,
        quality: 85,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Изображение',
        ),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(20),

        child: originalImage == null
            ? _SelectImage(
                onPressed: selectImage,
              )
            : croppedImage == null
                ? _CropEditor(
                    image: originalImage!,
                    controller:
                        cropController,
                    onCropped:
                        onCropped,
                    onCrop: cropImage,
                  )
                : _Preview(
                    image: croppedImage!,
                    onRetry: () {
                      setState(() {
                        croppedImage = null;
                      });
                    },
                  ),
      ),
    );
  }
}

class _SelectImage extends StatelessWidget {
  final VoidCallback onPressed;

  const _SelectImage({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onPressed,

        icon: const Icon(
          Icons.photo_library_outlined,
        ),

        label: const Text(
          'Выбрать изображение',
        ),
      ),
    );
  }
}

class _CropEditor extends StatelessWidget {
  final Uint8List image;
  final CropController controller;
  final ValueChanged<CropResult> onCropped;
  final VoidCallback onCrop;

  const _CropEditor({
    required this.image,
    required this.controller,
    required this.onCropped,
    required this.onCrop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Настройте изображение',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Перемещайте и масштабируйте фотографию. '
          'В квадрат попадёт то, что увидит экран ручки.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white60,
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,

              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),

                child: Crop(
                  image: image,

                  controller: controller,

                  aspectRatio: 1,

                  onCropped: onCropped,

                  withCircleUi: false,

                  baseColor:
                      const Color(
                    0xFF090A0C,
                  ),

                  maskColor:
                      Colors.black
                          .withOpacity(0.65),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 54,

          child: FilledButton.icon(
            onPressed: onCrop,

            icon: const Icon(
              Icons.check,
            ),

            label: const Text(
              'Готово',
            ),
          ),
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  final Uint8List image;
  final VoidCallback onRetry;

  const _Preview({
    required this.image,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Предпросмотр',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Так изображение будет подготовлено для экрана 240×240.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white60,
          ),
        ),

        const SizedBox(height: 24),

        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,

              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),

                child: Image.memory(
                  image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 54,

          child: FilledButton(
            onPressed: () {
              // Пока BLE-загрузка изображения
              // ещё не реализована.
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'Изображение подготовлено. BLE-загрузка будет следующим этапом.',
                  ),
                ),
              );
            },

            child: const Text(
              'Использовать изображение',
            ),
          ),
        ),

        const SizedBox(height: 10),

        TextButton(
          onPressed: onRetry,
          child: const Text(
            'Изменить кадрирование',
          ),
        ),
      ],
    );
  }
}