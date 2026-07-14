import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../screens/billing/billing_screen.dart';

class GatedSection extends StatelessWidget {
  final bool isLocked;
  final String planName;
  final Widget child;

  const GatedSection({
    super.key,
    required this.isLocked,
    this.planName = 'Growth',
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLocked) {
      return child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Blurred Content
        AbsorbPointer(
          absorbing: true,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: child,
          ),
        ),

        // Semi-transparent overlay to help readability
        Positioned.fill(
          child: Container(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.1),
          ),
        ),

        // Upgrade Lock Card
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1C1A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF332F2D) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lock Icon Badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262322) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.lock,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                '$planName Feature',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                'Upgrade your plan to unlock this advanced analytics report.',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  fontSize: 12,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const BillingScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFFFF8C00) : const Color(0xFFEA580C), // Warm orange
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Upgrade to $planName',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
