import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'main_navigation_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Find Parking in Addis Ababa',
      'description': 'Real-time availability maps guide you to open spots in Bole, Kazanchis, Piassa, and Meskel Square.',
      'imageUrl': 'assets/logo.png',
      'badgeType': 'logo',
    },
    {
      'title': 'Book with Telebirr & CBE Birr',
      'description': 'Secure your spot instantly using Telebirr or CBE Birr with frictionless digital payments.',
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCS41aC77JaAV_jRQpYiYPLcz1WkSF4F6QAgQxIlViViqY3z8O5D8bmkcppXtswkU66kn-C_E7vX9JZcoHl8LqpTXBXK1lTQIULrSAheD0-eRsIxYupenIojtx_JTP0fXojgleSaJRjFPh_vPQsfAWcazEeaWV-9bV6FsuMdAamPGEY1eza7fzY_LpcY0rkn2u6U1MnaurM2XW14NI6CBtNbj0Se9OLajM-N5oz-6U76zTF--_oXk8',
      'badgeType': 'reserved',
    },
    {
      'title': 'Scan & Park in Addis',
      'description': 'Breeze through gate barriers across Addis Ababa using your secure digital QR pass. No tickets needed.',
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCOOlIO7QUkKm8uhj2Mty8ZNro61SGNuCG4twLNUk1ruMAK5NmxnVpQgWoUGC6POwekvEYB23ILeX63rssyWPas2ZnWekPYpc0i8m8zcBtDk05X-DzQAlTlpKsmOiVNh2gShxb1ZS6E2vNOuhL2nePm4bbA2rZsn0ClxYropQwvSPNgWsAi_YERmIBo14pC2s50PGdbBWO_KEC8IKCpFoh8jG-ARjJLG0n6EQh9lTupjEmHA0RMMQ4',
      'badgeType': 'qr',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with ParkEase Logo & Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/logo.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 32,
                            height: 32,
                            color: AppColors.primary,
                            child: const Icon(Icons.local_parking, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ParkEase ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text('🇪🇹', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
                      );
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Carousel Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  final isAsset = slide['imageUrl']!.startsWith('assets/');
                  return Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: isAsset
                                      ? Image.asset(
                                          slide['imageUrl']!,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          slide['imageUrl']!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: AppColors.primaryContainer,
                                            child: const Icon(Icons.local_parking, size: 80, color: AppColors.primary),
                                          ),
                                        ),
                                ),
                              ),

                              if (slide['badgeType'] == 'logo')
                                Positioned(
                                  bottom: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.location_on, color: AppColors.primary, size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          'Addis Ababa Smart Map',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              if (slide['badgeType'] == 'reserved')
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.check_circle, color: AppColors.available, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Bole Spot Reserved',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              if (slide['badgeType'] == 'qr')
                                Positioned(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 40),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Text(
                            slide['title']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            slide['description']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Navigation Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_currentPage == _slides.length - 1 ? 'Get Started' : 'Next'),
                      const SizedBox(width: 8),
                      Icon(
                        _currentPage == _slides.length - 1 ? Icons.rocket_launch : Icons.arrow_forward,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
