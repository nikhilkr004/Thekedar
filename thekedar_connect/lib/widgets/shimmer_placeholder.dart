import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A simple shimmering placeholder used during async loading.
class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
     .shimmer(
       duration: const Duration(milliseconds: 1500),
       color: Colors.white.withOpacity(0.5),
     );
  }
}

/// Premium skeleton loader layout resembling project feed cards
class ProjectListSkeleton extends StatelessWidget {
  const ProjectListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerPlaceholder(width: 40, height: 40, borderRadius: BorderRadius.circular(12)),
                  ShimmerPlaceholder(width: 70, height: 24, borderRadius: BorderRadius.circular(10)),
                ],
              ),
              const SizedBox(height: 16),
              ShimmerPlaceholder(width: 180, height: 20, borderRadius: BorderRadius.circular(6)),
              const SizedBox(height: 8),
              ShimmerPlaceholder(width: 100, height: 14, borderRadius: BorderRadius.circular(6)),
              const SizedBox(height: 20),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerPlaceholder(width: 50, height: 10, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 6),
                      ShimmerPlaceholder(width: 90, height: 14, borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ShimmerPlaceholder(width: 50, height: 10, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 6),
                      ShimmerPlaceholder(width: 80, height: 14, borderRadius: BorderRadius.circular(4)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
