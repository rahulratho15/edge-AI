import 'dart:io';
import 'dart:math' as math;

import 'package:llamadart/llamadart.dart';

import '../models/chat_message.dart';

class LfmService {
  static const String _systemPrompt =
      'You are a small offline assistant running locally on an Android phone. '
      'Answer directly, briefly, and clearly. '
      'For image questions, describe only what is visible and say when you are unsure.';

  static const int _contextSize = 2048;
  static const int _fallbackContextSize = 1024;
  static const int _maxHistoryMessages = 6;

  static const GenerationParams _textParams = GenerationParams(
    maxTokens: 256,
    temp: 0.45,
    topP: 0.9,
    topK: 40,
    penalty: 1.05,
  );

  static const GenerationParams _visionParams = GenerationParams(
    maxTokens: 192,
    temp: 0.3,
    topP: 0.9,
    topK: 40,
    penalty: 1.02,
  );

  LlamaEngine? _engine;
  String? _projectorPath;
  bool _projectorLoaded = false;

  bool get isReady => _engine != null;

  Future<void> load({
    required String modelPath,
    required String projectorPath,
  }) async {
    await dispose();

    final safeThreads = math.max(1, math.min(2, Platform.numberOfProcessors));
    final profiles = <ModelParams>[
      ModelParams(
        contextSize: _contextSize,
        gpuLayers: 0,
        preferredBackend: GpuBackend.cpu,
        numberOfThreads: safeThreads,
        numberOfThreadsBatch: safeThreads,
        batchSize: 128,
        microBatchSize: 32,
      ),
      const ModelParams(
        contextSize: _fallbackContextSize,
        gpuLayers: 0,
        preferredBackend: GpuBackend.cpu,
        numberOfThreads: 1,
        numberOfThreadsBatch: 1,
        batchSize: 64,
        microBatchSize: 16,
      ),
    ];

    Object? lastError;

    for (final params in profiles) {
      final engine = LlamaEngine(LlamaBackend());
      try {
        await engine.loadModel(modelPath, modelParams: params);
        await engine.setLogLevel(LlamaLogLevel.warn);
        _engine = engine;
        _projectorPath = projectorPath;
        _projectorLoaded = false;
        return;
      } catch (error) {
        lastError = error;
        await engine.dispose();
      }
    }

    throw Exception('Unable to load the model on this device: $lastError');
  }

  Stream<String> reply({
    required List<ChatMessage> history,
    required String prompt,
    String? imagePath,
  }) async* {
    final engine = _engine;
    if (engine == null) {
      throw StateError('The model is not loaded.');
    }

    if (imagePath != null) {
      await _ensureProjectorLoaded();
    }

    final messages = <LlamaChatMessage>[
      LlamaChatMessage.fromText(
        role: LlamaChatRole.system,
        text: _systemPrompt,
      ),
      ...(imagePath == null ? _historyToLlamaMessages(history) : const []),
      _buildUserMessage(prompt: prompt, imagePath: imagePath),
    ];

    final params = imagePath == null ? _textParams : _visionParams;

    try {
      await for (final chunk in engine.create(messages, params: params)) {
        final content = chunk.choices.first.delta.content;
        if (content != null && content.isNotEmpty) {
          yield content;
        }
      }
    } finally {
      if (imagePath != null) {
        await _unloadProjectorIfNeeded();
      }
    }
  }

  Future<void> _ensureProjectorLoaded() async {
    if (_projectorLoaded) {
      return;
    }

    final engine = _engine;
    final projectorPath = _projectorPath;
    if (engine == null || projectorPath == null || projectorPath.isEmpty) {
      throw StateError('The multimodal projector is not configured.');
    }

    await engine.loadMultimodalProjector(projectorPath);
    _projectorLoaded = true;
  }

  Future<void> _unloadProjectorIfNeeded() async {
    final engine = _engine;
    if (engine == null || !_projectorLoaded) {
      return;
    }

    try {
      await engine.unloadMultimodalProjector();
    } finally {
      _projectorLoaded = false;
    }
  }

  Future<void> dispose() async {
    final engine = _engine;
    _engine = null;
    _projectorPath = null;
    _projectorLoaded = false;
    if (engine != null) {
      await engine.dispose();
    }
  }

  List<LlamaChatMessage> _historyToLlamaMessages(List<ChatMessage> history) {
    final stableMessages = history.where((message) {
      if (message.isStreaming) {
        return false;
      }
      if (message.hasImage) {
        return true;
      }
      return message.text.trim().isNotEmpty;
    }).toList(growable: false);

    final trimmedMessages = stableMessages.length > _maxHistoryMessages
        ? stableMessages.sublist(stableMessages.length - _maxHistoryMessages)
        : stableMessages;

    return trimmedMessages.map(_toLlamaMessage).toList(growable: false);
  }

  LlamaChatMessage _toLlamaMessage(ChatMessage message) {
    final role = message.role == MessageRole.user
        ? LlamaChatRole.user
        : LlamaChatRole.assistant;

    if (message.hasImage) {
      return LlamaChatMessage.withContent(
        role: role,
        content: [
          LlamaTextContent(
            message.text.trim().isEmpty
                ? 'Describe this image briefly.'
                : message.text.trim(),
          ),
          LlamaImageContent(path: message.imagePath!),
        ],
      );
    }

    return LlamaChatMessage.fromText(
      role: role,
      text: message.text.trim(),
    );
  }

  LlamaChatMessage _buildUserMessage({
    required String prompt,
    String? imagePath,
  }) {
    if (imagePath != null && imagePath.isNotEmpty) {
      return LlamaChatMessage.withContent(
        role: LlamaChatRole.user,
        content: [
          LlamaTextContent(prompt),
          LlamaImageContent(path: imagePath),
        ],
      );
    }

    return LlamaChatMessage.fromText(
      role: LlamaChatRole.user,
      text: prompt,
    );
  }
}
