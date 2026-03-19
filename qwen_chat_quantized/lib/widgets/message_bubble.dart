import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isUser),
          if (!isUser) const SizedBox(width: 10),
          Flexible(child: _buildBubble(context, isUser)),
          if (isUser) const SizedBox(width: 10),
          if (isUser) _buildAvatar(isUser),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUser
              ? [const Color(0xFF5C6BC0), const Color(0xFF3949AB)]
              : [const Color(0xFFFFB300), const Color(0xFFFF8F00)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isUser
                    ? const Color(0xFF3949AB)
                    : const Color(0xFFFFB300))
                .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isUser ? Icons.person_rounded : Icons.bolt_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildBubble(BuildContext context, bool isUser) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF1E3A5F) : const Color(0xFF1C2333),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        border: Border.all(
          color: isUser
              ? const Color(0xFF2E5A8F).withValues(alpha: 0.5)
              : const Color(0xFF2A3444).withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.hasImage) _buildImagePreview(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: isUser
                  ? Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    )
                  : _buildMarkdownContent(),
            ),
            if (message.isStreaming)
              Padding(
                padding: const EdgeInsets.only(left: 14, bottom: 8),
                child: _buildStreamingDots(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 200),
      child: Image.file(
        File(message.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 100,
            color: const Color(0xFF2D2D2D),
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMarkdownContent() {
    if (message.text.isEmpty && message.isStreaming) {
      return const SizedBox.shrink();
    }
    return MarkdownBody(
      data: message.text,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          color: Color(0xFFE0E0E0),
          fontSize: 15,
          height: 1.5,
        ),
        h1: const TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        h2: const TextStyle(
            color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
        h3: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        code: const TextStyle(
          color: Color(0xFFFFCC80),
          backgroundColor: Color(0xFF263238),
          fontSize: 13,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A3444)),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        blockquoteDecoration: BoxDecoration(
          border: const Border(
            left: BorderSide(color: Color(0xFFFFB300), width: 3),
          ),
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(4),
        ),
        listBullet: const TextStyle(color: Color(0xFFFFCC80), fontSize: 15),
        strong:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        em: const TextStyle(
            color: Color(0xFFB0BEC5), fontStyle: FontStyle.italic),
        a: const TextStyle(color: Color(0xFFFFB300)),
      ),
    );
  }

  Widget _buildStreamingDots() {
    return const _StreamingDotsWidget();
  }
}

class _StreamingDotsWidget extends StatefulWidget {
  const _StreamingDotsWidget();

  @override
  State<_StreamingDotsWidget> createState() => _StreamingDotsWidgetState();
}

class _StreamingDotsWidgetState extends State<_StreamingDotsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final t = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (0.3 + 0.7 * ((t * 3.14159 * 2).clamp(0, 6.28) < 3.14 ? (t * 3.14159 * 2).clamp(0, 3.14) / 3.14 : 0)).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.only(right: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFB300).withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}
