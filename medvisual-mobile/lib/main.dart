import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/api_client.dart';
import 'core/config.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/documents/data/documents_repository.dart';
import 'features/quiz/data/quizzes_repository.dart';
import 'features/sets/data/sets_repository.dart';
import 'features/study/data/study_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  runApp(const MedVisualApp());
}

class MedVisualApp extends StatefulWidget {
  const MedVisualApp({super.key});

  @override
  State<MedVisualApp> createState() => _MedVisualAppState();
}

class _MedVisualAppState extends State<MedVisualApp> {
  late final Dio _dio = buildApiClient();
  late final _router = createRouter();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => DocumentsRepository(_dio)),
        RepositoryProvider(create: (_) => SetsRepository(_dio)),
        RepositoryProvider(create: (_) => StudyRepository(_dio)),
        RepositoryProvider(create: (_) => QuizzesRepository(_dio)),
      ],
      child: BlocProvider(
        create: (_) => AuthCubit(Supabase.instance.client),
        child: MaterialApp.router(
          title: 'MedVisual',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          routerConfig: _router,
        ),
      ),
    );
  }
}
