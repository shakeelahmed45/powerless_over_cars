import 'package:flutter/material.dart';

/// A playful car icon loader with bouncing car and spinning wheels.
class CarLoader extends StatefulWidget {
  const CarLoader({super.key});

  @override
  State<CarLoader> createState() => _CarLoaderState();
}

class _CarLoaderState extends State<CarLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _spin;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _spin = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.linear));
    _bounce = Tween<double>(begin: -6, end: 6).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(0, _bounce.value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_car_filled, size: 56),
              const SizedBox(height: 8),
              // Two "wheels" that spin
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RotationTransition(turns: _spin, child: const Icon(Icons.circle, size: 12)),
                  const SizedBox(width: 24),
                  RotationTransition(turns: _spin, child: const Icon(Icons.circle, size: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
