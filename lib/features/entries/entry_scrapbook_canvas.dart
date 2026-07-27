import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/media/local_path_image.dart';
import '../../core/theme/app_theme.dart';
import 'entry_placement.dart';

/// Scrapbook page where photos can be placed and dragged.
class EntryScrapbookCanvas extends StatelessWidget {
  const EntryScrapbookCanvas({
    required this.placements,
    super.key,
    this.editable = false,
    this.onChanged,
    this.onSelect,
    this.selectedId,
    this.height = 280,
  });

  final List<EntryPlacement> placements;
  final bool editable;
  final ValueChanged<List<EntryPlacement>>? onChanged;
  final ValueChanged<String?>? onSelect;
  final String? selectedId;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: AppColors.parchment,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.softBlush.withValues(alpha: 0.8),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _PageGridPainter()),
              ),
              if (placements.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      editable
                          ? 'Add photos, then drag them into place.'
                          : 'No photos on this page yet.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedOlive,
                          ),
                    ),
                  ),
                ),
              for (final placement in placements)
                _PlacementItem(
                  key: ValueKey(placement.id),
                  placement: placement,
                  canvasWidth: width,
                  canvasHeight: height,
                  editable: editable,
                  selected: selectedId == placement.id,
                  onSelect: () => onSelect?.call(placement.id),
                  onMove: (next) {
                    final updated = [
                      for (final p in placements)
                        if (p.id == next.id) next else p,
                    ];
                    onChanged?.call(updated);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PlacementItem extends StatefulWidget {
  const _PlacementItem({
    required this.placement,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.editable,
    required this.selected,
    required this.onSelect,
    required this.onMove,
    super.key,
  });

  final EntryPlacement placement;
  final double canvasWidth;
  final double canvasHeight;
  final bool editable;
  final bool selected;
  final VoidCallback onSelect;
  final ValueChanged<EntryPlacement> onMove;

  @override
  State<_PlacementItem> createState() => _PlacementItemState();
}

class _PlacementItemState extends State<_PlacementItem> {
  late EntryPlacement _local;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _local = widget.placement;
  }

  @override
  void didUpdateWidget(covariant _PlacementItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep size/position in sync when parent updates scale or coords.
    // Preserve in-progress drag position until pan ends.
    if (!_dragging && oldWidget.placement != widget.placement) {
      _local = widget.placement;
    } else if (!_dragging &&
        (oldWidget.placement.scale != widget.placement.scale ||
            oldWidget.placement.rotation != widget.placement.rotation)) {
      _local = widget.placement;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxSize = math.max(64.0, widget.canvasWidth * 0.92);
    final size =
        (widget.canvasWidth * _local.scale).clamp(36.0, maxSize).toDouble();
    final left = (_local.x * widget.canvasWidth)
        .clamp(0.0, math.max(0.0, widget.canvasWidth - size))
        .toDouble();
    final top = (_local.y * widget.canvasHeight)
        .clamp(0.0, math.max(0.0, widget.canvasHeight - size))
        .toDouble();

    final path = _local.localPath;
    final child = path == null
        ? Container(
            width: size,
            height: size,
            color: Colors.black12,
            child: const Icon(Icons.image_not_supported),
          )
        : LocalPathImage(
            path: path,
            width: size,
            height: size,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(8),
          );

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: widget.editable ? widget.onSelect : null,
        onPanStart: widget.editable ? (_) => _dragging = true : null,
        onPanUpdate: widget.editable
            ? (details) {
                final nextX =
                    ((_local.x * widget.canvasWidth) + details.delta.dx) /
                        widget.canvasWidth;
                final nextY =
                    ((_local.y * widget.canvasHeight) + details.delta.dy) /
                        widget.canvasHeight;
                setState(() {
                  _local = _local.copyWith(
                    x: nextX.clamp(0.0, 0.85).toDouble(),
                    y: nextY.clamp(0.0, 0.85).toDouble(),
                  );
                });
              }
            : null,
        onPanEnd: widget.editable
            ? (_) {
                _dragging = false;
                widget.onMove(_local);
              }
            : null,
        child: DecoratedBox(
          decoration: widget.selected
              ? BoxDecoration(
                  border: Border.all(color: AppColors.cardinalRed, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                )
              : const BoxDecoration(),
          child: Transform.rotate(
            angle: _local.rotation,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PageGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.softBlush.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
