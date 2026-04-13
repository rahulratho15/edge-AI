import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_message.dart';
import '../services/lfm_service.dart';
import '../services/model_manager.dart';
import '../widgets/chat_composer.dart';
import '../widgets/message_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ModelManager _modelManager = ModelManager();
  final LfmService _lfmService = LfmService();
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _promptController = TextEditingController();

  List<ChatMessage> _messages = <ChatMessage>[];
  bool _checkingFiles = true;
  bool _filesReady = false;
  bool _downloadingFiles = false;
  bool _loadingRuntime = false;
  bool _sending = false;
  String _statusText = 'Checking local files...';
  String? _errorMessage;
  String? _selectedImagePath;
  double _downloadProgress = 0;
  int _downloadedBytes = 0;
  int _totalDownloadBytes = ModelManager.estimatedTotalBytes;
  String _runtimeLabel = 'Not loaded';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _promptController.dispose();
    unawaited(_lfmService.dispose());
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _checkingFiles = true;
      _errorMessage = null;
      _statusText = 'Checking local files...';
    });

    try {
      final filesReady = await _modelManager.areAssetsReady();
      if (!mounted) {
        return;
      }

      setState(() {
        _checkingFiles = false;
        _filesReady = filesReady;
        _statusText = filesReady
            ? 'Model files are ready.'
            : 'Model download required.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _checkingFiles = false;
        _errorMessage = error.toString();
        _statusText = 'Unable to check local files.';
      });
    }
  }

  Future<void> _downloadFiles() async {
    setState(() {
      _downloadingFiles = true;
      _errorMessage = null;
      _downloadProgress = 0;
      _downloadedBytes = 0;
      _totalDownloadBytes = ModelManager.estimatedTotalBytes;
      _statusText = 'Starting download...';
    });

    try {
      await _modelManager.downloadRequiredFiles(
        onProgress: (progress) {
          if (!mounted) {
            return;
          }

          setState(() {
            _statusText = '${progress.title}: ${progress.filename}';
            _downloadProgress = progress.overallProgress;
            _downloadedBytes = progress.receivedBytes;
            _totalDownloadBytes = progress.totalBytes;
          });
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _downloadingFiles = false;
        _filesReady = true;
        _statusText = 'Files ready. Load the model.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _downloadingFiles = false;
        _errorMessage = error.toString();
        _statusText = 'Download failed.';
      });
    }
  }

  Future<void> _loadRuntime() async {
    setState(() {
      _loadingRuntime = true;
      _errorMessage = null;
      _statusText = 'Loading model...';
    });

    try {
      await _lfmService.load(
        modelPath: await _modelManager.modelPath,
        projectorPath: await _modelManager.projectorPath,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loadingRuntime = false;
        _runtimeLabel = _lfmService.runtimeLabel;
        _statusText = 'Ready for text and image prompts.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingRuntime = false;
        _errorMessage = error.toString();
        _statusText = 'Model load failed.';
      });
    }
  }

  Future<void> _sendPrompt() async {
    if (!_lfmService.isReady || _sending) {
      return;
    }

    final rawPrompt = _promptController.text.trim();
    final imagePath = _selectedImagePath;
    if (rawPrompt.isEmpty && imagePath == null) {
      return;
    }

    final prompt =
        rawPrompt.isEmpty ? 'Describe this image briefly.' : rawPrompt;
    final priorMessages = List<ChatMessage>.from(_messages);
    final userMessage = ChatMessage(
      id: ChatMessage.newId(),
      role: MessageRole.user,
      text: prompt,
      imagePath: imagePath,
    );
    final assistantMessage = ChatMessage(
      id: ChatMessage.newId(),
      role: MessageRole.assistant,
      text: '',
      isStreaming: true,
    );

    _promptController.clear();
    setState(() {
      _messages = <ChatMessage>[
        ..._messages,
        userMessage,
        assistantMessage,
      ];
      _selectedImagePath = null;
      _sending = true;
      _errorMessage = null;
    });
    _scrollToBottom();

    final stopwatch = Stopwatch()..start();
    final buffer = StringBuffer();

    try {
      await for (final chunk in _lfmService.reply(
        history: priorMessages,
        prompt: prompt,
        imagePath: imagePath,
      )) {
        buffer.write(chunk);

        if (!mounted) {
          return;
        }

        setState(() {
          _updateLatestAssistantMessage(
            text: buffer.toString(),
            isStreaming: true,
          );
        });
        _scrollToBottom();
      }

      stopwatch.stop();
      if (!mounted) {
        return;
      }

      setState(() {
        _sending = false;
        _updateLatestAssistantMessage(
          text: buffer.toString().trim().isEmpty
              ? 'No response was generated.'
              : buffer.toString(),
          isStreaming: false,
          responseSeconds: stopwatch.elapsedMilliseconds / 1000,
        );
      });
    } catch (error) {
      stopwatch.stop();
      if (!mounted) {
        return;
      }

      setState(() {
        _sending = false;
        _updateLatestAssistantMessage(
          text: 'Error: $error',
          isStreaming: false,
          responseSeconds: stopwatch.elapsedMilliseconds / 1000,
        );
      });
    }
  }

  void _updateLatestAssistantMessage({
    required String text,
    required bool isStreaming,
    double? responseSeconds,
  }) {
    if (_messages.isEmpty) {
      return;
    }

    final lastIndex = _messages.length - 1;
    final lastMessage = _messages[lastIndex];
    if (lastMessage.role != MessageRole.assistant) {
      return;
    }

    _messages[lastIndex] = lastMessage.copyWith(
      text: text,
      isStreaming: isStreaming,
      responseSeconds: responseSeconds,
    );
  }

  Future<void> _pickImage() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _selectImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _selectImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 72,
      );

      if (!mounted || file == null) {
        return;
      }

      setState(() {
        _selectedImagePath = file.path;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Image selection failed: $error';
      });
    }
  }

  void _clearConversation() {
    setState(() {
      _messages = <ChatMessage>[];
      _selectedImagePath = null;
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LFM 2.5 Edge'),
        actions: [
          if (_lfmService.isReady)
            IconButton(
              onPressed: _messages.isEmpty ? null : _clearConversation,
              tooltip: 'Clear conversation',
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _lfmService.isReady ? _buildChatLayout() : _buildSetupLayout(),
    );
  }

  Widget _buildSetupLayout() {
    final theme = Theme.of(context);
    final busy = _checkingFiles || _downloadingFiles || _loadingRuntime;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFDCE3EF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local multimodal chat',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Simple Flutter Android app for text and image questions with LiquidAI LFM2.5-VL-450M.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5A6C82),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        _InfoPill(label: 'Model', value: 'Q4_0'),
                        _InfoPill(label: 'Projector', value: 'Q8_0'),
                        _InfoPill(label: 'Runtime', value: 'CPU + Vulkan'),
                        _InfoPill(label: 'Target', value: 'Android arm64'),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _buildStatusCard(
                      title: _statusText,
                      subtitle: _buildProgressSubtitle(),
                      progress: busy && _downloadProgress > 0
                          ? _downloadProgress
                          : busy
                              ? null
                              : _filesReady
                                  ? 1
                                  : 0,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2F0),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFFD6D0)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFB04035)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: busy
                            ? null
                            : _filesReady
                                ? _loadRuntime
                                : _downloadFiles,
                        child: Text(
                          _filesReady ? 'Load model' : 'Download files',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: busy ? null : _bootstrap,
                        child: const Text('Check again'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Best on Android 8+ arm64 phones. The app tries acceleration first and falls back to smaller CPU profiles when needed.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF66788E),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatLayout() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE3EF)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.memory_outlined,
                size: 18,
                color: Color(0xFF1A5FB4),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Runtime mode: $_runtimeLabel',
                  style: const TextStyle(
                    color: Color(0xFF1A2F46),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return MessageCard(message: _messages[index]);
                  },
                ),
        ),
        ChatComposer(
          controller: _promptController,
          enabled: !_sending,
          hasImage: _selectedImagePath != null,
          onSend: _sendPrompt,
          onPickImage: _pickImage,
          onClearImage: () {
            setState(() {
              _selectedImagePath = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F0FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.image_search_outlined,
                size: 36,
                color: Color(0xFF1A5FB4),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Ask a question or attach an image.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Short prompts are usually fastest. For image text, attach the image and ask exactly what you want extracted or explained.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF607287),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String subtitle,
    required double? progress,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE3EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF10243E),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF5F748C),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
          ),
        ],
      ),
    );
  }

  String _buildProgressSubtitle() {
    if (_downloadingFiles) {
      return '${ModelManager.formatBytes(_downloadedBytes)} / '
          '${ModelManager.formatBytes(_totalDownloadBytes)}';
    }
    if (_filesReady) {
      return 'The official Q4_0 model and Q8_0 projector are already on this device.';
    }
    return 'About 323 MB total download on first launch.';
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E2F3)),
      ),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xFF56708D),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xFF133456),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
