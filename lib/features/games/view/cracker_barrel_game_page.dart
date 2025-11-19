import 'package:flutter/material.dart';

import '../../../shared/utils/toast.dart';
import '../../../shared/widgets/glass.dart';

class CrackerBarrelGamePage extends StatelessWidget {
  const CrackerBarrelGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cracker Barrel Peg Puzzle'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const _CrackerBarrelGame(),
    );
  }
}

class _CrackerBarrelGame extends StatefulWidget {
  const _CrackerBarrelGame();

  @override
  State<_CrackerBarrelGame> createState() => _CrackerBarrelGameState();
}

class _CrackerBarrelGameState extends State<_CrackerBarrelGame> {
  static const int _slotCount = 15;
  static const int _initialEmptyIndex = 4;
  static const List<_PegMove> _moves = [
    _PegMove(0, 1, 3),
    _PegMove(3, 1, 0),
    _PegMove(0, 2, 5),
    _PegMove(5, 2, 0),
    _PegMove(1, 3, 6),
    _PegMove(6, 3, 1),
    _PegMove(1, 4, 8),
    _PegMove(8, 4, 1),
    _PegMove(2, 4, 7),
    _PegMove(7, 4, 2),
    _PegMove(2, 5, 9),
    _PegMove(9, 5, 2),
    _PegMove(3, 4, 5),
    _PegMove(5, 4, 3),
    _PegMove(3, 7, 12),
    _PegMove(12, 7, 3),
    _PegMove(3, 6, 10),
    _PegMove(10, 6, 3),
    _PegMove(4, 7, 11),
    _PegMove(11, 7, 4),
    _PegMove(4, 8, 13),
    _PegMove(13, 8, 4),
    _PegMove(5, 8, 12),
    _PegMove(12, 8, 5),
    _PegMove(5, 9, 14),
    _PegMove(14, 9, 5),
    _PegMove(6, 7, 8),
    _PegMove(8, 7, 6),
    _PegMove(7, 8, 9),
    _PegMove(9, 8, 7),
    _PegMove(10, 11, 12),
    _PegMove(12, 11, 10),
    _PegMove(11, 12, 13),
    _PegMove(13, 12, 11),
    _PegMove(12, 13, 14),
    _PegMove(14, 13, 12),
  ];

  late List<bool> _pegs;
  int? _selected;

  @override
  void initState() {
    super.initState();
    _pegs = _createInitialBoard();
  }

  List<bool> _createInitialBoard() {
    final board = List<bool>.filled(_slotCount, true);
    board[_initialEmptyIndex] = false;
    return board;
  }

  void _resetBoard() {
    setState(() {
      _pegs = _createInitialBoard();
      _selected = null;
    });
  }

  void _handleTap(int index) {
    if (_pegs[index]) {
      setState(() {
        _selected = _selected == index ? null : index;
      });
      return;
    }

    final selected = _selected;
    if (selected == null) {
      return;
    }

    final move = _findMove(selected, index);
    if (move == null) {
      setState(() => _selected = null);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => showToast(
          context,
          'Illegal move. Jump over one peg into an empty spot.',
        ),
      );
      return;
    }

    setState(() {
      _pegs[move.from] = false;
      _pegs[move.over] = false;
      _pegs[move.to] = true;
      _selected = null;
    });

    if (!_hasAnyMoves()) {
      final remaining = _remainingPegs;
      final message = remaining == 1
          ? 'Genius! Only one peg left.'
          : 'No more moves. $remaining pegs remain.';
      WidgetsBinding.instance
          .addPostFrameCallback((_) => showToast(context, message));
    }
  }

  _PegMove? _findMove(int from, int to) {
    for (final move in _moves) {
      if (move.from == from &&
          move.to == to &&
          _pegs[move.over] &&
          !_pegs[to]) {
        return move;
      }
    }
    return null;
  }

  bool _hasAnyMoves() {
    for (final move in _moves) {
      if (_pegs[move.from] && _pegs[move.over] && !_pegs[move.to]) {
        return true;
      }
    }
    return false;
  }

  bool _canMoveTo(int index) {
    final selected = _selected;
    if (selected == null || _pegs[index]) return false;
    return _findMove(selected, index) != null;
  }

  int get _remainingPegs => _pegs.where((peg) => peg).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final remaining = _remainingPegs;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Glass(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'Pegs left: $remaining',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Glass(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: _buildBoard(cs),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _resetBoard,
            child: const Text('Reset puzzle'),
          ),
          const SizedBox(height: 8),
          Text(
            _selected == null
                ? 'Tap a peg to select, then tap an empty hole to jump.'
                : 'Choose an empty hole to jump into.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildBoard(ColorScheme cs) {
    final rows = <Widget>[];
    var index = 0;
    for (var row = 1; row <= 5; row++) {
      final rowTiles = <Widget>[];
      for (var col = 0; col < row; col++) {
        final slot = index++;
        rowTiles.add(
          _PegWidget(
            filled: _pegs[slot],
            selected: _selected == slot,
            highlight: _canMoveTo(slot),
            color: cs.primary,
            onTap: () => _handleTap(slot),
          ),
        );
      }
      rows.add(
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: (5 - row) * 12.0, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rowTiles.length; i++) ...[
                if (i != 0) const SizedBox(width: 12),
                rowTiles[i],
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}

class _PegMove {
  const _PegMove(this.from, this.over, this.to);

  final int from;
  final int over;
  final int to;
}

class _PegWidget extends StatelessWidget {
  const _PegWidget({
    required this.filled,
    required this.selected,
    required this.highlight,
    required this.color,
    required this.onTap,
  });

  final bool filled;
  final bool selected;
  final bool highlight;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = selected
        ? cs.secondary
        : highlight
            ? color.withValues(alpha: 0.7)
            : color.withValues(alpha: 0.35);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : cs.surface.withValues(alpha: 0.08),
          border: Border.all(color: borderColor, width: selected ? 3 : 2),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: filled
            ? const Icon(Icons.circle, color: Colors.white, size: 18)
            : highlight
                ? Icon(Icons.radio_button_unchecked,
                    color: color.withValues(alpha: 0.8), size: 18)
                : null,
      ),
    );
  }
}
