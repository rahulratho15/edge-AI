import 'dart:io';

enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String text;
  final String? imagePath;
  final DateTime timestamp;
  bool isStreaming;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.imagePath,
    DateTime? timestamp,
    this.isStreaming = false,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? text,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      imagePath: imagePath,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  bool get hasImage => imagePath != null && File(imagePath!).existsSync();

  static String generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString();
}
