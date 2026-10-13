import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'role_select_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _slides = [
    {
      'icon': Icons.local_drink_rounded,
      'color': MilkColors.primaryGreen,
      'titleKey': 'onboard_1_title',
      'descKey': 'onboard_1_desc',
    },
    {
      'icon': Icons.calendar_month_rounded,
      'color': MilkColors.dairyBlue,
      'titleKey': 'onboard_2_title',
      'descKey': 'onboard_2_desc',
    },
    {
      'icon': Icons.handshake_rounded,
      'color': const Color(0xFFD97706),
      'titleKey': 'onboard_3_title',
      'descKey': 'onboard_3_desc',
    },
  ];

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MilkColors.milkWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          const LangMenu(),
          TextButton(
            onPressed: _finish,
            child: Text(
              t(context, 'skip'),
              style: const TextStyle(fontWeight: FontWeight.w700, color: MilkColors.charcoalLight),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: (s['color'] as Color).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            s['icon'] as IconData,
                            size: 72,
                            color: s['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          t(context, s['titleKey'] as String),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: MilkColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t(context, s['descKey'] as String),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: MilkColors.charcoalLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? MilkColors.primaryGreen : MilkColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: _currentPage == _slides.length - 1
                        ? t(context, 'get_started')
                        : t(context, 'continue'),
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finish();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
