import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import 'study_home_cubit.dart';

/// Calis: deste secici (veya tum vadesi gelen kartlar).
class StudyHomeScreen extends StatelessWidget {
  const StudyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calis')),
      body: BlocBuilder<StudyHomeCubit, StudyHomeState>(
        builder: (context, state) {
          if (state.status == ViewStatus.loading ||
              state.status == ViewStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == ViewStatus.failure) {
            return ErrorView(
              message: state.error ?? 'Calisma verileri yuklenemedi.',
              onRetry: () => context.read<StudyHomeCubit>().load(),
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<StudyHomeCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8EAF6),
                      child: Icon(Icons.all_inclusive,
                          color: AppColors.indigo),
                    ),
                    title: const Text('Tum desteler',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${state.totalDue} kart vadesi geldi • ${state.newCount} yeni'),
                    trailing: const Icon(Icons.play_arrow_rounded,
                        color: AppColors.teal, size: 32),
                    onTap: state.totalDue > 0
                        ? () async {
                            await context.push('/calis/oturum');
                            if (context.mounted) {
                              context.read<StudyHomeCubit>().load();
                            }
                          }
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text('Desteye gore calis',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (state.sets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: EmptyView(
                      icon: Icons.school_outlined,
                      title: 'Calisilacak deste yok',
                      subtitle:
                          'Once panelden bir dokumandan kart destesi uretin.',
                    ),
                  )
                else
                  ...state.sets.map(
                    (s) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE0F2F1),
                          child: Icon(Icons.style, color: AppColors.teal),
                        ),
                        title: Text(s.title,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${s.cardCount} kart'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await context.push('/calis/oturum?setId=${s.id}');
                          if (context.mounted) {
                            context.read<StudyHomeCubit>().load();
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
