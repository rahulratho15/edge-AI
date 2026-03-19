import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_message.dart';
import '../services/llm_service.dart';
import '../services/model_manager.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final LlmService _llmService = LlmService();
  final ModelManager _modelManager = ModelManager();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _attachedImagePath;
  String _loadingStatus = 'Loading model...';
  double _tokensPerSecond = 0;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _llmService.dispose();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      setState(() {
        _loadingStatus = 'Loading Qwen3.5-0.8B (Q4_K_M)...';
      });

      final modelPath = await _modelManager.modelPath;
      await _llmService.loadModel(modelPath, contextSize: 2048);

      setState(() {
        _loadingStatus = 'Loading vision projector...';
      });

      final mmprojPath = await _modelManager.mmprojPath;
      await _llmService.loadVisionProjector(mmprojPath);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadingStatus = 'Error: $e';
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 50), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _handleSend(String text) async {
    final hasImage = _attachedImagePath != null;
    final imagePath = _attachedImagePath;

    final userMessage = ChatMessage(
      id: ChatMessage.generateId(),
      role: MessageRole.user,
      text: text,
      imagePath: imagePath,
    );

    final assistantMessage = ChatMessage(
      id: ChatMessage.generateId(),
      role: MessageRole.assistant,
      text: '',
      isStreaming: true,
    );

    setState(() {
      _messages = [..._messages, userMessage, assistantMessage];
      _isGenerating = true;
      _attachedImagePath = null;
    });

    _scrollToBottom();

    try {
      final stopwatch = Stopwatch()..start();
      int tokenCount = 0;
      final buffer = StringBuffer();

      final stream = hasImage && imagePath != null
          ? _llmService.chatWithImage(text, imagePath)
          : _llmService.chat(text);

      await for (final token in stream) {
        buffer.write(token);
        tokenCount++;

        final elapsed = stopwatch.elapsedMilliseconds;
        if (elapsed > 0) {
          _tokensPerSecond = (tokenCount / elapsed) * 1000;
        }

        setState(() {
          final idx = _messages.length - 1;
          _messages[idx] = _messages[idx].copyWith(
            text: buffer.toString(),
          );
        });

        _scrollToBottom();
      }

      stopwatch.stop();

      setState(() {
        final idx = _messages.length - 1;
        _messages[idx] = _messages[idx].copyWith(isStreaming: false);
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        final idx = _messages.length - 1;
        _messages[idx] = _messages[idx].copyWith(
          text: '⚠️ Error: $e',
          isStreaming: false,
        );
        _isGenerating = false;
      });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF30363D),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFFFFB300),
                  ),
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Use camera to capture an image',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFFFFB300),
                  ),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Select an existing photo',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _attachedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  void _clearConversation() {
    setState(() {
      _messages = [];
      _attachedImagePath = null;
      _tokensPerSecond = 0;
    });
    _llmService.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading ? _buildLoadingView() : _buildChatView(),
          ),
          if (!_isLoading)
            ChatInput(
              onSend: _handleSend,
              onAttachImage: _pickImage,
              isGenerating: _isGenerating,
              hasImage: _attachedImagePath != null,
              onClearImage: () => setState(() => _attachedImagePath = null),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF161B22),
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
              ),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Qwen Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Q4_K_M • Quantized • 8GB Optimized',
                style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_tokensPerSecond > 0)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_tokensPerSecond.toStringAsFixed(1)} t/s',
              style: const TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        IconButton(
          onPressed: _messages.isEmpty ? null : _clearConversation,
          icon: Icon(
            Icons.delete_outline_rounded,
            color: _messages.isEmpty
                ? const Color(0xFF484F58)
                : const Color(0xFF8B949E),
          ),
          tooltip: 'Clear conversation',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0xFF30363D).withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: Color(0xFFFFB300),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _loadingStatus,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: _messages[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFB300).withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFFFFB300),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Start a conversation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quantized for speed & efficiency\nOptimized for 8GB RAM devices',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('Explain quantum computing'),
              _buildSuggestionChip('Write a haiku about AI'),
              _buildSuggestionChip('📷 Describe an image'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () {
        if (label.startsWith('📷')) {
          _pickImage();
        } else {
          _handleSend(label);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8B949E),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
