import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final Function(String text) onSend;
  final VoidCallback onAttachImage;
  final bool isGenerating;
  final bool hasImage;
  final VoidCallback? onClearImage;

  const ChatInput({
    super.key,
    required this.onSend,
    required this.onAttachImage,
    required this.isGenerating,
    this.hasImage = false,
    this.onClearImage,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isGenerating) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF30363D).withValues(alpha: 0.8),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image attachment indicator
              if (widget.hasImage)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image,
                          color: Color(0xFFFFB300), size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Image attached',
                        style:
                            TextStyle(color: Color(0xFFFFB300), fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: widget.onClearImage,
                        child: const Icon(Icons.close,
                            color: Color(0xFFFFB300), size: 14),
                      ),
                    ],
                  ),
                ),
              // Input row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildIconButton(
                    icon: Icons.add_photo_alternate_outlined,
                    onTap: widget.isGenerating ? null : widget.onAttachImage,
                    color: const Color(0xFF8B949E),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _focusNode.hasFocus
                              ? const Color(0xFFFFB300).withValues(alpha: 0.5)
                              : const Color(0xFF30363D),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: 4,
                        minLines: 1,
                        enabled: !widget.isGenerating,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.isGenerating
                              ? 'Generating...'
                              : 'Type a message...',
                          hintStyle: TextStyle(
                            color: const Color(0xFF8B949E)
                                .withValues(alpha: 0.6),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: _buildSendButton(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final canSend = _hasText && !widget.isGenerating;
    return GestureDetector(
      onTap: canSend ? _handleSend : null,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: canSend
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                )
              : null,
          color: canSend ? null : const Color(0xFF21262D),
          boxShadow: canSend
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.arrow_upward_rounded,
          color: canSend ? Colors.white : const Color(0xFF484F58),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF21262D),
        ),
        child: Icon(
          icon,
          color: onTap != null ? color : color.withValues(alpha: 0.4),
          size: 22,
        ),
      ),
    );
  }
}
