import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../data/tour_prefs.dart';

/// Ilk acilista (veya Ayarlar'dan) gosterilen 5 adimlik tanitim turu.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _steps = <_TourStep>[
    _TourStep(
      icon: Icons.picture_as_pdf_outlined,
      title: 'PDF yukleyin',
      body:
          'Panelden kendi PDF dosyanizi yukleyin ya da kutuphaneden hazir bir '
          'tip kitabi secin. Dokuman islendikten sonra hazir olur.',
    ),
    _TourStep(
      icon: Icons.auto_awesome,
      title: 'Kart ve quiz uretin',
      body:
          'Hazir bir dokuman secip sayfa araligi ve adet belirleyin. Gemini '
          'destegi ile daha tutarli, klinik odakli icerikler uretilir.',
    ),
    _TourStep(
      icon: Icons.image_search,
      title: 'Gorsel ekleyin',
      body:
          'Kartlara DIP motoru ile sayfalardan otomatik gorsel bulun veya '
          'toplu olarak tum desteye gorsel ekleyin.',
    ),
    _TourStep(
      icon: Icons.school_outlined,
      title: 'Aralikli tekrar ile calisin',
      body:
          'SM-2 algoritmasi vadesi gelen kartlari size getirir. Her gun '
          'duzenli calisarak kalici ogrenme saglayin.',
    ),
    _TourStep(
      icon: Icons.ios_share,
      title: 'Disa aktarin ve paylasin',
      body:
          'Destelerinizi Anki, CSV, PDF ve daha fazlasi olarak disa aktarip '
          'paylasabilirsiniz. Iyi calismalar!',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await TourPrefs.markDone();
    if (mounted) context.go('/panel');
  }

  void _next() {
    if (_page < _steps.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _steps.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Atla'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _steps.length,
                itemBuilder: (context, i) => _StepView(step: _steps[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _steps.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? AppColors.indigo
                          : Colors.blueGrey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(isLast ? 'Basla' : 'Devam'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});

  final _TourStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.indigo.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, size: 56, color: AppColors.indigo),
          ),
          const SizedBox(height: 32),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }
}

class _TourStep {
  const _TourStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
