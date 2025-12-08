import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/preferences.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Mark your land easily',
      subtitle: 'Tap on the map to set boundary points',
      illustration: const SlideOneIllustration(),
    ),
    OnboardingSlide(
      title: 'Get precise area instantly',
      subtitle: 'Calculate area in various units immediately',
      illustration: const SlideTwoIllustration(),
    ),
    OnboardingSlide(
      title: 'All measurement units supported',
      subtitle: 'Choose your preferred unit for accurate conversions',
      illustration: const SlideThreeIllustration(),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await ref.read(onboardingCompletedProvider.notifier).complete();
    if (mounted) {
      // Check if user is already logged in (edge case)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    }
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skip() {
    _finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: const Text(
                  'Skip',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _slides[index];
                },
              ),
            ),

            // Pagination Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 32 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF2E7D32)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Next/Get Started Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == _slides.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingSlide extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget illustration;

  const OnboardingSlide({
    super.key,
    required this.title,
    required this.subtitle,
    required this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration - Make flexible to prevent overflow
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: illustration,
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide 1: Tap to mark illustration
class SlideOneIllustration extends StatelessWidget {
  const SlideOneIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(300, 300), painter: SlideOnePainter());
  }
}

class SlideOnePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background map grid
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw grid
    for (int i = 0; i < 8; i++) {
      double x = size.width * (i / 8);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      double y = size.height * (i / 8);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Red pins
    final pins = [
      Offset(size.width * 0.3, size.height * 0.4),
      Offset(size.width * 0.7, size.height * 0.35),
      Offset(size.width * 0.75, size.height * 0.7),
    ];

    for (final pin in pins) {
      // Pin shadow
      canvas.drawCircle(
        pin,
        13,
        Paint()
          ..color = const Color(0xFFFF3B30).withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Pin
      canvas.drawCircle(pin, 12, Paint()..color = const Color(0xFFFF3B30));

      canvas.drawCircle(
        pin,
        12,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Hand pointer
    final textPainter = TextPainter(
      text: const TextSpan(text: '👆', style: TextStyle(fontSize: 48)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.65, size.height * 0.55));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Slide 2: Area calculation illustration
class SlideTwoIllustration extends StatelessWidget {
  const SlideTwoIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(300, 300), painter: SlideTwoPainter());
  }
}

class SlideTwoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Polygon
    final polygonPaint = Paint()
      ..color = const Color(0xFF66BB6A).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final polygonStroke = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    final points = [
      Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.35),
      Offset(size.width * 0.75, size.height * 0.7),
      Offset(size.width * 0.25, size.height * 0.7),
      Offset(size.width * 0.2, size.height * 0.35),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    canvas.drawPath(path, polygonPaint);
    canvas.drawPath(path, polygonStroke);

    // Pins
    for (final point in points) {
      canvas.drawCircle(point, 8, Paint()..color = const Color(0xFFFF3B30));
      canvas.drawCircle(
        point,
        8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Measurement labels
    _drawLabel(
      canvas,
      '230 sq ft',
      Offset(size.width * 0.75, size.height * 0.25),
    );
    _drawLabel(
      canvas,
      '0.005 acre',
      Offset(size.width * 0.2, size.height * 0.8),
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset position) {
    final labelPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        position.dx - 4,
        position.dy - 4,
        textPainter.width + 8,
        textPainter.height + 8,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(rect, labelPaint);
    canvas.drawRRect(rect, borderPaint);
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Slide 3: Units grid illustration
class SlideThreeIllustration extends StatelessWidget {
  const SlideThreeIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final units = [
      {'name': 'Sq Feet', 'icon': '📏'},
      {'name': 'Sq Meters', 'icon': '📐'},
      {'name': 'Acre', 'icon': '🌾'},
      {'name': 'Hectare', 'icon': '🗺️'},
      {'name': 'Sq Yards', 'icon': '📍'},
      {'name': 'Custom', 'icon': '✨'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: units.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(units[index]['icon']!, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                units[index]['name']!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
