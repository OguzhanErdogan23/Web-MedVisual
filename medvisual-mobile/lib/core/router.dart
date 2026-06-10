import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/documents/data/documents_repository.dart';
import '../features/documents/domain/document.dart';
import '../features/documents/presentation/documents_bloc.dart';
import '../features/documents/presentation/documents_screen.dart';
import '../features/documents/presentation/generate_wizard_screen.dart';
import '../features/quiz/data/quizzes_repository.dart';
import '../features/quiz/presentation/quiz_player_screen.dart';
import '../features/quiz/presentation/quizzes_cubit.dart';
import '../features/quiz/presentation/quizzes_screen.dart';
import '../features/sets/data/sets_repository.dart';
import '../features/sets/presentation/set_detail_screen.dart';
import '../features/sets/presentation/sets_bloc.dart';
import '../features/sets/presentation/sets_screen.dart';
import '../features/study/data/study_repository.dart';
import '../features/study/presentation/study_home_cubit.dart';
import '../features/study/presentation/study_home_screen.dart';
import '../features/study/presentation/study_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Supabase oturum degisikliklerini GoRouter'a bildirir.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createRouter({bool tourDone = true}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: tourDone ? '/panel' : '/onboarding',
    refreshListenable: _AuthRefreshNotifier(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final loggedIn = Supabase.instance.client.auth.currentSession != null;
      // Onboarding turu kimlik dogrulamasindan bagimsiz gosterilir.
      if (state.matchedLocation == '/onboarding') return null;
      final onAuthPage = state.matchedLocation == '/giris' ||
          state.matchedLocation == '/kayit';
      if (!loggedIn) return onAuthPage ? null : '/giris';
      if (onAuthPage) return '/panel';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/giris', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/kayit', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/ayarlar',
        builder: (context, state) => const SettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeBlocProviders(
          child: HomeShell(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/panel',
              builder: (context, state) => const DocumentsScreen(),
              routes: [
                GoRoute(
                  path: 'uret/:docId',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => GenerateWizardScreen(
                    documentId: state.pathParameters['docId']!,
                    document: state.extra as Document?,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/desteler',
              builder: (context, state) => const SetsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) =>
                      SetDetailScreen(setId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/quizler',
              builder: (context, state) => const QuizzesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) =>
                      QuizPlayerScreen(quizId: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/calis',
              builder: (context, state) => const StudyHomeScreen(),
              routes: [
                GoRoute(
                  path: 'oturum',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) =>
                      StudyScreen(setId: state.uri.queryParameters['setId']),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
}

/// Alt gezinme cubugu kabugu. Sekme bloclari burada saglanir ki sekmeler
/// arasi gecislerde durum korunur; sekmeye donuste liste tazelenir.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
    // Sekmeye donuste veriyi tazele (IndexedStack ekranlari canli tutar).
    switch (index) {
      case 0:
        context.read<DocumentsBloc>().add(const DocumentsRefreshed());
      case 1:
        context.read<SetsBloc>().add(const SetsRefreshed());
      case 2:
        context.read<QuizzesCubit>().load(silent: true);
      case 3:
        context.read<StudyHomeCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => _onDestinationSelected(context, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Panel',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Desteler',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Quizler',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Calis',
          ),
        ],
      ),
    );
  }
}

/// Sekme bloclarini saglayan sarmalayici (kabuk rotasinin ustunde kullanilir).
class HomeBlocProviders extends StatelessWidget {
  const HomeBlocProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DocumentsBloc(
            context.read<DocumentsRepository>(),
            context.read<StudyRepository>(),
          )..add(const DocumentsStarted()),
        ),
        BlocProvider(
          create: (context) =>
              SetsBloc(context.read<SetsRepository>())..add(const SetsStarted()),
        ),
        BlocProvider(
          create: (context) =>
              QuizzesCubit(context.read<QuizzesRepository>())..load(),
        ),
        BlocProvider(
          create: (context) => StudyHomeCubit(
            context.read<SetsRepository>(),
            context.read<StudyRepository>(),
          )..load(),
        ),
      ],
      child: child,
    );
  }
}
