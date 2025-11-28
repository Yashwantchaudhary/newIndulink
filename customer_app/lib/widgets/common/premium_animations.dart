import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../config/app_colors.dart';

/// Premium Success Animation Widget (Confetti + Checkmark)
class PremiumSuccessAnimation extends StatefulWidget {
  final VoidCallback? onComplete;
  final String message;

  const PremiumSuccessAnimation({
    super.key,
    this.onComplete,
    this.message = 'Success!',
  });

  @override
  State<PremiumSuccessAnimation> createState() =>
      _PremiumSuccessAnimationState();
}

class _PremiumSuccessAnimationState extends State<PremiumSuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _checkmarkController;
  late AnimationController _confettiController;
  late Animation<double> _checkmarkAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _checkmarkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkmarkController, curve: Curves.elasticOut),
    );

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _checkmarkController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _checkmarkController.forward();
    _confettiController.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // Confetti
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ConfettiPainter(_confettiController.value),
                size: Size.infinite,
              );
            },
          ),

          // Success Checkmark
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.success, Color(0xFF00E676)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _checkmarkAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _CheckmarkPainter(_checkmarkAnimation.value),
                    );
                  },
                ),
              ),
            ),
          ),

          // Success Message
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _checkmarkAnimation,
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;

  _CheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);

    // Checkmark path
    path.moveTo(center.dx - 20, center.dy);
    path.lineTo(center.dx - 5, center.dy + 15);
    path.lineTo(center.dx + 20, center.dy - 10);

    final pathMetrics = path.computeMetrics().first;
    final extractPath = pathMetrics.extractPath(
      0,
      pathMetrics.length * progress,
    );

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_Confetti> confetti = [];

  _ConfettiPainter(this.progress) {
    // Generate confetti pieces
    for (int i = 0; i < 50; i++) {
      confetti.add(_Confetti());
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in confetti) {
      final paint = Paint()..color = piece.color;

      final x = size.width * piece.x;
      final y = size.height * (piece.y * progress);
      final rotation = piece.rotation * progress * 2 * math.pi;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.size,
          height: piece.size / 2,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Confetti {
  final double x;
  final double y;
  final double size;
  final double rotation;
  final Color color;

  _Confetti()
      : x = math.Random().nextDouble(),
        y = math.Random().nextDouble(),
        size = math.Random().nextDouble() * 10 + 5,
        rotation = math.Random().nextDouble(),
        color = [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.orange,
          Colors.purple,
          Colors.pink,
        ][math.Random().nextInt(7)];
}

/// Particle Effect Widget
class ParticleEffect extends StatefulWidget {
  final int particleCount;
  final Color particleColor;

  const ParticleEffect({
    super.key,
    this.particleCount = 30,
    this.particleColor = AppColors.primaryBlue,
  });

  @override
  State<ParticleEffect> createState() => _ParticleEffectState();
}

class _ParticleEffectState extends State<ParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
        return CustomPaint(
          painter: _ParticlePainter(
            progress: _controller.value,
            particleCount: widget.particleCount,
            color: widget.particleColor,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final int particleCount;
  final Color color;

  _ParticlePainter({
    required this.progress,
    required this.particleCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.6);

    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * math.pi;
      final distance = progress * 100;

      final x = size.width / 2 + math.cos(angle) * distance;
      final y = size.height / 2 + math.sin(angle) * distance;

      canvas.drawCircle(
        Offset(x, y),
        3 * (1 - progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Shimmer Loading Effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Colors.grey,
                Colors.white,
                Colors.grey,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
