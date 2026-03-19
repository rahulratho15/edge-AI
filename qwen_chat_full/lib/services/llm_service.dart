import 'package:llamadart/llamadart.dart';

/// Service wrapping llamadart for Qwen3.5-0.8B inference.
/// Supports both text and vision (multimodal) generation.
class LlmService {
  LlamaEngine? _engine;
  ChatSession? _session;
  bool _isModelLoaded = false;
  bool _isMmprojLoaded = false;
  bool _isGenerating = false;

  bool get isModelLoaded => _isModelLoaded;
  bool get isMmprojLoaded => _isMmprojLoaded;
  bool get isReady => _isModelLoaded;
  bool get isGenerating => _isGenerating;

  // ---------- Generation Parameters (non-thinking mode) ----------

  /// Text tasks: temperature=1.0, top_p=1.00, top_k=20, min_p=0.0,
  /// presence_penalty=2.0, repetition_penalty=1.0
  static const Map<String, double> textParams = {
    'temperature': 1.0,
    'top_p': 1.0,
    'top_k': 20.0,
    'min_p': 0.0,
    'presence_penalty': 2.0,
    'repeat_penalty': 1.0,
  };

  /// VL (Vision-Language) tasks: temperature=0.7, top_p=0.80, top_k=20,
  /// min_p=0.0, presence_penalty=1.5, repetition_penalty=1.0
  static const Map<String, double> vlParams = {
    'temperature': 0.7,
    'top_p': 0.80,
    'top_k': 20.0,
    'min_p': 0.0,
    'presence_penalty': 1.5,
    'repeat_penalty': 1.0,
  };

  // ---------- Model Loading ----------

  /// Load the main GGUF model. [contextSize] defaults to 4096 for full model.
  Future<void> loadModel(String modelPath, {int contextSize = 4096}) async {
    _engine = LlamaEngine(LlamaBackend());
    await _engine!.loadModel(modelPath);
    await _engine!.setLogLevel(LlamaLogLevel.warn);

    _session = ChatSession(
      _engine!,
      systemPrompt:
          'You are Qwen, a helpful AI assistant created by Alibaba Cloud. '
          'Answer questions directly, clearly, and helpfully. '
          'Be concise but thorough.',
    );
    _isModelLoaded = true;
  }

  /// Load the multimodal projector for vision support.
  Future<void> loadVisionProjector(String mmprojPath) async {
    if (_engine == null) throw StateError('Load model first');
    await _engine!.loadMultimodalProjector(mmprojPath);
    _isMmprojLoaded = true;
  }

  // ---------- Text Generation ----------

  /// Generate a text response (streaming). Yields tokens as they arrive.
  Stream<String> chat(String userMessage) async* {
    if (_session == null) throw StateError('Model not loaded');
    _isGenerating = true;

    try {
      await for (final chunk in _session!.create(
        [LlamaTextContent(userMessage)],
      )) {
        final content = chunk.choices.first.delta.content;
        if (content != null && content.isNotEmpty) {
          yield content;
        }
      }
    } finally {
      _isGenerating = false;
    }
  }

  // ---------- Vision Generation ----------

  /// Generate a response for an image + text prompt (streaming).
  Stream<String> chatWithImage(String userMessage, String imagePath) async* {
    if (_engine == null) throw StateError('Model not loaded');
    if (!_isMmprojLoaded) throw StateError('Vision projector not loaded');
    _isGenerating = true;

    try {
      final messages = [
        LlamaChatMessage.withContent(
          role: LlamaChatRole.user,
          content: [
            LlamaImageContent(path: imagePath),
            LlamaTextContent(userMessage),
          ],
        ),
      ];

      final response = _engine!.create(messages);
      await for (final chunk in response) {
        final content = chunk.choices.first.delta.content;
        if (content != null && content.isNotEmpty) {
          yield content;
        }
      }
    } finally {
      _isGenerating = false;
    }
  }

  // ---------- Cleanup ----------

  /// Clear chat history and start a new conversation.
  void clearHistory() {
    if (_engine != null && _isModelLoaded) {
      _session = ChatSession(
        _engine!,
        systemPrompt:
            'You are Qwen, a helpful AI assistant created by Alibaba Cloud. '
            'Answer questions directly, clearly, and helpfully. '
            'Be concise but thorough.',
      );
    }
  }

  /// Dispose the engine and release all resources.
  Future<void> dispose() async {
    _isGenerating = false;
    _isModelLoaded = false;
    _isMmprojLoaded = false;
    _session = null;
    if (_engine != null) {
      await _engine!.dispose();
      _engine = null;
    }
  }
}
