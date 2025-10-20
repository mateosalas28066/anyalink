// lib/presentation/widgets/skeletons.dart
// Comentario (ES): Skeleton simple para estado de carga.

import 'package:flutter/material.dart';

class GridSkeleton extends StatelessWidget {
  final int count;
  const GridSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (_, idx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEAECEF),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
