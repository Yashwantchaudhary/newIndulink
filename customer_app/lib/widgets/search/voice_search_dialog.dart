import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';

/// Voice Search Dialog
class VoiceSearchDialog extends StatefulWidget {
  final Function(String) onSearchQuery;

  const VoiceSearchDialog({
    super.key,
    required this.onSearchQuery,
  });

  @override
  State<VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<VoiceSearchDialog>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _initSpeech();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' && _text.isNotEmpty) {
            widget.onSearchQuery(_text);
            Navigator.pop(context);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
          _showError('Error: ${error.errorMsg}');
        },
      );

      if (available) {
        _startListening();
      } else {
        _showError('Speech recognition not available');
      }
    } catch (e) {
      _showError('Failed to initialize speech: $e');
    }
  }

  Future<void> _startListening() async {
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _text = result.recognizedWords;
        });
      },
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: AppConstants.borderRadiusLarge,
      ),
      child: Padding(
        padding: AppConstants.paddingAll24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Microphone Animation
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 120 + (_animationController.value * 20),
                  height: 120 + (_animationController.value * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(
                          0.3 + (_animationController.value * 0.3),
                        ),
                        blurRadius: 20 + (_animationController.value * 10),
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic,
                    size: 60,
                    color: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Status Text
            Text(
              _isListening ? 'Listening...' : 'Initializing...',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Recognized Text
            if (_text.isNotEmpty)
              Container(
                padding: AppConstants.paddingAll16,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant,
                  borderRadius: AppConstants.borderRadiusMedium,
                ),
                child: Text(
                  _text,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              )
            else
              Text(
                'Try saying "cement", "bricks", etc.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
