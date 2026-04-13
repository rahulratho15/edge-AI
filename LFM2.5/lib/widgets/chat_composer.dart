import 'package:flutter/material.dart';

class ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool hasImage;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.hasImage,
    required this.onSend,
    required this.onPickImage,
    required this.onClearImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FB),
        border: Border(
          top: BorderSide(color: Color(0xFFD9E3F0)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasImage)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC9DBF7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        size: 18,
                        color: Color(0xFF1A5FB4),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Image attached',
                          style: TextStyle(
                            color: Color(0xFF17417B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: enabled ? onClearImage : null,
                        icon: const Icon(Icons.close),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Remove image',
                      ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: enabled ? onPickImage : null,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    tooltip: 'Attach image',
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, child) {
                        return TextField(
                          controller: controller,
                          enabled: enabled,
                          minLines: 1,
                          maxLines: 5,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (enabled &&
                                (value.text.trim().isNotEmpty || hasImage)) {
                              onSend();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: hasImage
                                ? 'Ask something about the image'
                                : 'Type a message',
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      final canSend =
                          enabled && (value.text.trim().isNotEmpty || hasImage);

                      return FilledButton(
                        onPressed: canSend ? onSend : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(54, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Icon(Icons.send_rounded),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
