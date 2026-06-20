import 'dart:math';
import 'package:flutter/material.dart';

class ThreeDCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final double height;
  final double width;

  const ThreeDCard({
    super.key,
    required this.front,
    required this.back,
    this.height = 360.0,
    this.width = 240.0,
  });

  @override
  State<ThreeDCard> createState() => _ThreeDCardState();
}

class _ThreeDCardState extends State<ThreeDCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _rotationY = 0.0;
  Offset _dragStart = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_controller.isAnimating) return;
    
    final double target = _rotationY >= pi ? 0.0 : pi;
    final double current = _rotationY;
    
    final animation = Tween<double>(begin: current, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    animation.addListener(() {
      setState(() {
        _rotationY = animation.value;
      });
    });

    _controller.forward(from: 0.0);
  }

  bool get _showBack => _rotationY > pi / 2 && _rotationY < 3 * pi / 2;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _flipCard,
      onHorizontalDragStart: (details) {
        _dragStart = details.globalPosition;
      },
      onHorizontalDragUpdate: (details) {
        final deltaX = details.globalPosition.dx - _dragStart.dx;
        _dragStart = details.globalPosition;
        setState(() {
          // Adjust rotation speed and keep within [0, 2*pi]
          _rotationY = (_rotationY + (deltaX / 100)) % (2 * pi);
        });
      },
      onHorizontalDragEnd: (details) {
        // Snap to nearest side (front = 0 or 2*pi, back = pi)
        double target = 0.0;
        if (_rotationY > pi / 2 && _rotationY < 3 * pi / 2) {
          target = pi;
        } else if (_rotationY >= 3 * pi / 2) {
          target = 2 * pi;
        }
        
        final double current = _rotationY;
        final snapAnimation = Tween<double>(begin: current, end: target).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );

        snapAnimation.addListener(() {
          setState(() {
            _rotationY = snapAnimation.value;
          });
        });

        _controller.forward(from: 0.0).then((_) {
          if (_rotationY >= 2 * pi) {
            _rotationY = 0.0;
          }
        });
      },
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform(
              alignment: FractionalOffset.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective
                ..rotateY(_rotationY),
              child: Container(
                height: widget.height,
                width: widget.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _showBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi), // correct mirrored back image
                        child: widget.back,
                      )
                    : widget.front,
              ),
            );
          },
        ),
      ),
    );
  }
}
