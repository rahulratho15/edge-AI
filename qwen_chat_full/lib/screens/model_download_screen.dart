import 'package:flutter/material.dart';
import '../services/model_manager.dart';

class ModelDownloadScreen extends StatefulWidget {
  final VoidCallback onDownloadComplete;

  const ModelDownloadScreen({super.key, required this.onDownloadComplete});

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen>
    with SingleTickerProviderStateMixin {
  final ModelManager _modelManager = ModelManager();
  late AnimationController _pulseController;

  bool _isDownloading = false;
  String _status = '';
  double _modelProgress = 0.0;
  double _mmprojProgress = 0.0;
  int _currentStep = 0; // 0=idle, 1=downloading model, 2=downloading mmproj, 3=done
  String _downloadedSize = '';
  String _totalSize = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _checkExistingModels();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingModels() async {
    if (await _modelManager.areAllModelsReady()) {
      widget.onDownloadComplete();
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _error = null;
      _currentStep = 1;
      _status = 'Downloading Qwen3.5-0.8B (Q8_0)...';
    });

    try {
      // Download main model
      await _modelManager.downloadModel(
        onProgress: (received, total) {
          setState(() {
            _modelProgress = total > 0 ? received / total : 0;
            _downloadedSize = ModelManager.formatBytes(received);
            _totalSize = total > 0 ? ModelManager.formatBytes(total) : '~812 MB';
          });
        },
      );

      // Download vision projector
      setState(() {
        _currentStep = 2;
        _status = 'Downloading vision projector...';
        _mmprojProgress = 0;
      });

      await _modelManager.downloadMmproj(
        onProgress: (received, total) {
          setState(() {
            _mmprojProgress = total > 0 ? received / total : 0;
            _downloadedSize = ModelManager.formatBytes(received);
            _totalSize = total > 0 ? ModelManager.formatBytes(total) : '~100 MB';
          });
        },
      );

      setState(() {
        _currentStep = 3;
        _status = 'Ready!';
      });

      await Future.delayed(const Duration(milliseconds: 500));
      widget.onDownloadComplete();
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _error = e.toString();
        _status = 'Download failed';
        _currentStep = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.08);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00BCD4)
                                .withValues(alpha: 0.3 + _pulseController.value * 0.2),
                            blurRadius: 20 + _pulseController.value * 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Title
              const Text(
                'Qwen Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Full Quality • Q8_0 • Offline AI',
                style: TextStyle(
                  color: const Color(0xFF00BCD4).withValues(alpha: 0.8),
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 40),
              // Model info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF30363D),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Model', 'Qwen3.5-0.8B'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Quantization', 'Q8_0 (Full Quality)'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Size', '~812 MB + ~100 MB vision'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Capabilities', 'Text + Vision'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Progress section
              if (_isDownloading) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Step 1: Model
                      _buildProgressStep(
                        'Main Model (Q8_0)',
                        _currentStep >= 1
                            ? (_currentStep > 1 ? 1.0 : _modelProgress)
                            : 0,
                        _currentStep == 1,
                        _currentStep > 1,
                      ),
                      const SizedBox(height: 8),
                      // Step 2: mmproj
                      _buildProgressStep(
                        'Vision Projector',
                        _currentStep >= 2
                            ? (_currentStep > 2 ? 1.0 : _mmprojProgress)
                            : 0,
                        _currentStep == 2,
                        _currentStep > 2,
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          '$_downloadedSize / $_totalSize',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              // Error display
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D1F1F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF6D3030)),
                  ),
                  child: Text(
                    'Error: $_error',
                    style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Download button
              if (!_isDownloading || _error != null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _startDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_error != null ? Icons.refresh : Icons.download_rounded),
                        const SizedBox(width: 10),
                        Text(
                          _error != null ? 'Retry Download' : 'Download Model',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00BCD4),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStep(
    String label,
    double progress,
    bool isActive,
    bool isComplete,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isComplete
                  ? Icons.check_circle
                  : isActive
                      ? Icons.downloading
                      : Icons.circle_outlined,
              color: isComplete
                  ? const Color(0xFF4CAF50)
                  : isActive
                      ? const Color(0xFF00BCD4)
                      : const Color(0xFF484F58),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive || isComplete
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
            const Spacer(),
            if (isActive || isComplete)
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Color(0xFF00BCD4),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF21262D),
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? const Color(0xFF4CAF50) : const Color(0xFF00BCD4),
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
