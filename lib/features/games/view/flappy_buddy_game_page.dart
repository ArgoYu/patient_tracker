import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/widgets/glass.dart';

class FlappyBuddyGamePage extends StatelessWidget {
  const FlappyBuddyGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flappy Buddy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const _FlappyMiniGame(),
    );
  }
}

class _FlappyMiniGame extends StatefulWidget {
  const _FlappyMiniGame();

  @override
  State<_FlappyMiniGame> createState() => _FlappyMiniGameState();
}

class _FlappyMiniGameState extends State<_FlappyMiniGame> {
  double _gameHeight = 360;
  static const double _birdSize = 32;
  static const double _birdX = 64;
  static const double _gravity = 820;
  static const double _flapVelocity = -350;
  static const double _pipeWidth = 64;

  final List<_Pipe> _pipes = [];
  Timer? _timer;
  double _birdY = 0;
  double _velocity = 0;
  int _score = 0;
  bool _running = false;
  bool _gameOver = false;
  double _gameWidth = 320;

  @override
  void initState() {
    super.initState();
    _birdY = _gameHeight / 2 - _birdSize / 2;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _timer?.cancel();
    setState(() {
      _running = true;
      _gameOver = false;
      _score = 0;
      _birdY = _gameHeight / 2 - _birdSize / 2;
      _velocity = 0;
      _pipes
        ..clear()
        ..addAll(_generateInitialPipes());
    });
    _timer =
        Timer.periodic(const Duration(milliseconds: 16), (_) => _tick(0.016));
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _gameOver = true;
    });
  }

  double get _gap => (_gameHeight * 0.45).clamp(160.0, 260.0);
  double get _pipeSpeed => (_gameWidth * 0.4).clamp(120.0, 200.0);
  double get _pipeSpacing => (_gameWidth * 0.7).clamp(260.0, 360.0);

  List<_Pipe> _generateInitialPipes() {
    final list = <_Pipe>[];
    final spacing = _pipeSpacing;
    for (var i = 0; i < 3; i++) {
      final x = _gameWidth + i * spacing;
      list.add(_Pipe(x: x, gapCenter: _randomGapY()));
    }
    return list;
  }

  double _randomGapY() {
    final rand = math.Random();
    final minGap = _gap / 2 + 30;
    final maxGap = _gameHeight - _gap / 2 - 30;
    return rand.nextDouble() * (maxGap - minGap) + minGap;
  }

  void _tick(double dt) {
    if (!_running) return;
    setState(() {
      _velocity += _gravity * dt;
      _birdY += _velocity * dt;

      for (final pipe in _pipes) {
        pipe.x -= _pipeSpeed * dt;
        if (!pipe.counted && pipe.x + _pipeWidth < _birdX) {
          pipe.counted = true;
          _score += 1;
        }
      }
      if (_pipes.isNotEmpty && _pipes.first.x + _pipeWidth < 0) {
        _pipes.removeAt(0);
        _pipes.add(
          _Pipe(
            x: _pipes.last.x + _pipeSpacing,
            gapCenter: _randomGapY(),
          ),
        );
      }

      final media = MediaQuery.of(context).size;
      _gameHeight = media.height - kToolbarHeight - 120;
      _gameWidth = media.width - 32;

      if (_birdY < 0 || _birdY + _birdSize > _gameHeight) {
        _endGame();
      }
      for (final pipe in _pipes) {
        if (pipe.collides(_birdX, _birdSize, _birdY, _gap)) {
          _endGame();
          break;
        }
      }
    });
  }

  void _flap() {
    if (!_running) {
      _startGame();
      return;
    }
    setState(() {
      _velocity = _flapVelocity;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context).size;
        final width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : media.width;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : media.height;
        _gameHeight = height - 120;
        _gameWidth = width;

        return GestureDetector(
          onTap: _flap,
          child: Container(
            color: cs.surface.withValues(alpha: 0.04),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          cs.primary.withValues(alpha: 0.18),
                          cs.surface.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
                ..._pipes.map(
                  (pipe) => Positioned(
                    left: pipe.x,
                    top: 0,
                    bottom: 0,
                    width: _pipeWidth,
                    child: _PipeWidget(
                      gapCenter: pipe.gapCenter,
                      gapSize: _gap,
                      color: cs.primary,
                    ),
                  ),
                ),
                Positioned(
                  left: _birdX,
                  top: _birdY,
                  width: _birdSize,
                  height: _birdSize,
                  child: _BirdWidget(color: cs.secondary),
                ),
                Positioned(
                  top: 24,
                  left: 0,
                  right: 0,
                  child: Align(
                    child: Glass(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        'Score: $_score',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                if (!_running)
                  Center(
                    child: Glass(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      child: Text(
                        _gameOver
                            ? 'Game over! Tap to try again.'
                            : 'Tap to start!',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Pipe {
  _Pipe({required this.x, required this.gapCenter});

  double x;
  double gapCenter;
  bool counted = false;

  bool collides(double birdX, double birdSize, double birdY, double gap) {
    final withinX =
        birdX + birdSize > x && birdX < x + _FlappyMiniGameState._pipeWidth;
    final withinGap =
        birdY + birdSize < gapCenter + gap / 2 && birdY > gapCenter - gap / 2;
    return withinX && !withinGap;
  }
}

class _BirdWidget extends StatelessWidget {
  const _BirdWidget({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.favorite, color: Colors.white, size: 18),
    );
  }
}

class _PipeWidget extends StatelessWidget {
  const _PipeWidget({
    required this.gapCenter,
    required this.gapSize,
    required this.color,
  });

  final double gapCenter;
  final double gapSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter:
          _PipePainter(gapCenter: gapCenter, gapSize: gapSize, color: color),
    );
  }
}

class _PipePainter extends CustomPainter {
  const _PipePainter({
    required this.gapCenter,
    required this.gapSize,
    required this.color,
  });

  final double gapCenter;
  final double gapSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final gapTop = gapCenter - gapSize / 2;
    final gapBottom = gapCenter + gapSize / 2;
    final rectTop = Rect.fromLTWH(0, 0, size.width, gapTop);
    final rectBottom =
        Rect.fromLTWH(0, gapBottom, size.width, size.height - gapBottom);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rectTop, const Radius.circular(12)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rectBottom, const Radius.circular(12)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PipePainter oldDelegate) {
    return gapCenter != oldDelegate.gapCenter ||
        gapSize != oldDelegate.gapSize ||
        color != oldDelegate.color;
  }
}
