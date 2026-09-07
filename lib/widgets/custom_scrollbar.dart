import 'package:flutter/material.dart';

class CustomHorizontalScrollbar extends StatefulWidget {
  final ScrollController controller;
  final Widget child;
  final double height;
  final double minThumbWidth;

  const CustomHorizontalScrollbar({
    super.key,
    required this.controller,
    required this.child,
    this.height = 6,
    this.minThumbWidth = 30,
  });

  @override
  State<CustomHorizontalScrollbar> createState() =>
      _CustomHorizontalScrollbarState();
}

class _CustomHorizontalScrollbarState extends State<CustomHorizontalScrollbar> {
  double thumbLeft = 0;
  double thumbWidth = 40;
  double viewportWidth = 0;

  bool isDragging = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateThumb);
  }

  void _updateThumb() {
    final position = widget.controller.position;

    if (!position.hasPixels || !position.hasContentDimensions) return;

    final maxScroll = position.maxScrollExtent;
    final viewport = position.viewportDimension;
    final contentWidth = maxScroll + viewport;

    viewportWidth = viewport;

    if (maxScroll <= 0) {
      setState(() {
        thumbWidth = viewport;
        thumbLeft = 0;
      });
      return;
    }

    final visibleFraction = viewport / contentWidth;
    final calculatedThumbWidth = (viewport * visibleFraction).clamp(
      widget.minThumbWidth,
      viewport,
    );

    final scrollFraction = position.pixels / maxScroll;

    final calculatedLeft = scrollFraction * (viewport - calculatedThumbWidth);

    setState(() {
      thumbWidth = calculatedThumbWidth;
      thumbLeft = calculatedLeft.clamp(0, viewport - thumbWidth);
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final position = widget.controller.position;
    print(position);
    final maxScroll = position.maxScrollExtent;
    final viewport = position.viewportDimension;

    if (maxScroll <= 0) return;

    final delta = details.delta.dx;

    final scrollDelta = (delta / viewport) * maxScroll;

    final newOffset = (widget.controller.offset + scrollDelta).clamp(
      0,
      maxScroll,
    );

    widget.controller.jumpTo(newOffset.toDouble());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateThumb);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.child,

        const SizedBox(height: 8),

        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: widget.height,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: [
                  // Track
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  // Thumb (draggable)
                  Positioned(
                    left: thumbLeft,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragStart: (_) {
                        isDragging = true;
                      },
                      onHorizontalDragUpdate: _onDragUpdate,
                      onHorizontalDragEnd: (_) {
                        isDragging = false;
                      },
                      child: Container(
                        width: thumbWidth,
                        height: widget.height,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
