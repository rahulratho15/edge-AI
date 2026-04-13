import 'dart:io';

import 'package:flutter/material.dart';

import '../models/chat_message.dart';

class MessageCard extends StatelessWidget {
  final ChatMessage message;

  const MessageCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final alignment =
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start;
    final background =
        isUser ? const Color(0xFFDCEBFF) : const Color(0xFFFFFFFF);
    final borderColor =
        isUser ? const Color(0xFFBDD4F7) : const Color(0xFFDCE3EF);
    final titleColor =
        isUser ? const Color(0xFF18447E) : const Color(0xFF5B6F85);
    final textColor = const Color(0xFF132238);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? 'You' : 'LFM 2.5',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (message.hasImage) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(message.imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            width: double.infinity,
                            color: const Color(0xFFE9EEF6),
                            alignment: Alignment.center,
                            child: const Text('Image preview unavailable'),
                          );
                        },
                      ),
                    ),
                  ],
                  if (message.text.trim().isNotEmpty || message.isStreaming) ...[
                    const SizedBox(height: 10),
                    SelectableText(
                      message.text.trim().isEmpty
                          ? 'Generating response...'
                          : message.text,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (!isUser &&
                      !message.isStreaming &&
                      message.responseSeconds != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        '${message.responseSeconds!.toStringAsFixed(1)} s',
                        style: const TextStyle(
                          color: Color(0xFF6B7F98),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
