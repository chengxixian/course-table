import 'package:flutter/material.dart';

/// Round-dot matrix lettering in the same visual language as local-music's
/// `DotMatrixMark`: every character is a 5×7 grid of circular dots, with a
/// faint unlit grid behind it. This is deliberately not a pixel-square font.
class DotMatrixText extends StatelessWidget {
  final String text;
  final double height;
  final Color color;
  final bool showGrid;
  final Color? accent;

  const DotMatrixText(
    this.text, {
    super.key,
    required this.height,
    required this.color,
    this.showGrid = false,
    this.accent,
  });

  static const _glyphs = <String, List<String>>{
    'H': ['X...X', 'X...X', 'X...X', 'XXXXX', 'X...X', 'X...X', 'X...X'],
    'S': ['.XXXX', 'X....', 'X....', '.XXX.', '....X', '....X', 'XXXX.'],
    'U': ['X...X', 'X...X', 'X...X', 'X...X', 'X...X', 'X...X', '.XXX.'],
    ' ': ['.....', '.....', '.....', '.....', '.....', '.....', '.....'],
  };

  @override
  Widget build(BuildContext context) {
    final rows = _rowsFor(text);
    final cols = rows.isEmpty ? 1 : rows.first.length;
    final cell = height / 7;
    final width = cols * cell;
    return Semantics(
      label: text,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _DotMatrixPainter(
            rows: rows,
            cell: cell,
            color: color,
            showGrid: showGrid,
            accent: accent,
          ),
        ),
      ),
    );
  }

  static List<String> _rowsFor(String value) {
    final chars = value.toUpperCase().split('');
    if (chars.isEmpty) return ['.....'];
    final rows = List.generate(7, (_) => <String>[]);
    for (var i = 0; i < chars.length; i++) {
      final glyph = _glyphs[chars[i]] ?? _glyphs[' ']!;
      for (var y = 0; y < 7; y++) {
        rows[y].add(glyph[y]);
        if (i != chars.length - 1) rows[y].add('.');
      }
    }
    return rows.map((r) => r.join()).toList();
  }
}

class _DotMatrixPainter extends CustomPainter {
  final List<String> rows;
  final double cell;
  final Color color;
  final bool showGrid;
  final Color? accent;

  _DotMatrixPainter({
    required this.rows,
    required this.cell,
    required this.color,
    required this.showGrid,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = color.withValues(alpha: 0.10);
    final dotPaint = Paint()..color = color;
    final accentPaint = Paint()..color = accent ?? const Color(0xFFD71921);
    if (showGrid) {
      for (var y = 0; y < rows.length; y++) {
        for (var x = 0; x < rows[y].length; x++) {
          canvas.drawCircle(
            Offset((x + 0.5) * cell, (y + 0.5) * cell),
            cell * 0.12,
            gridPaint,
          );
        }
      }
    }
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        if (rows[y][x] != 'X') continue;
        final isAccent = accent != null && y == 1 && x == rows[y].length - 1;
        canvas.drawCircle(
          Offset((x + 0.5) * cell, (y + 0.5) * cell),
          cell * 0.28,
          isAccent ? accentPaint : dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotMatrixPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.cell != cell ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.accent != accent ||
        oldDelegate.rows != rows;
  }
}
