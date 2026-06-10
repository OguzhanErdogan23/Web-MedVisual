import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../data/profile_repository.dart';
import 'settings_cubit.dart';
import 'theme_cubit.dart';

/// Ayarlar: profil, gorunum (tema), hesap (sifre/cikis) + turu tekrar gor.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsCubit(
        context.read<ProfileRepository>(),
        Supabase.instance.client,
      )..load(),
      child: const _SettingsBody(),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listenWhen: (p, c) => p.notice != c.notice,
        listener: (context, state) {
          if (state.notice != null) showSnack(context, state.notice!);
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: const [
              _ProfileSection(),
              _AppearanceSection(),
              _AccountSection(),
              _HelpSection(),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.indigo,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}

class _ProfileSection extends StatefulWidget {
  const _ProfileSection();

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  final _displayName = TextEditingController();
  String? _loadedFor;

  @override
  void dispose() {
    _displayName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state.status == ViewStatus.loading ||
            state.status == ViewStatus.initial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == ViewStatus.failure) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: ErrorView(
              message: state.error ?? 'Profil yuklenemedi.',
              onRetry: () => context.read<SettingsCubit>().load(),
            ),
          );
        }
        final profile = state.profile;
        // Profil ilk yuklendiginde alani doldur (tekrar doldurma).
        if (profile != null && _loadedFor != profile.id) {
          _loadedFor = profile.id;
          _displayName.text = profile.displayName ?? '';
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader('Profil'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                child: Text(profile?.email ?? '-'),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _displayName,
                decoration: const InputDecoration(
                  labelText: 'Gorunen ad',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: state.saving
                      ? null
                      : () => context
                          .read<SettingsCubit>()
                          .saveDisplayName(_displayName.text.trim()),
                  icon: state.saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Kaydet'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader('Gorunum'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Acik'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Koyu'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Sistem'),
                    icon: Icon(Icons.settings_suggest_outlined),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (s) =>
                    context.read<ThemeCubit>().setMode(s.first),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection();

  Future<void> _changePassword(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    final pw = TextEditingController();
    final pw2 = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sifre Degistir'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: pw,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Yeni sifre'),
                validator: (v) => (v == null || v.length < 6)
                    ? 'En az 6 karakter olmali'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: pw2,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Yeni sifre (tekrar)'),
                validator: (v) =>
                    v != pw.text ? 'Sifreler eslesmiyor' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgec'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Degistir'),
          ),
        ],
      ),
    );
    if (ok == true) cubit.changePassword(pw.text);
  }

  Future<void> _signOut(BuildContext context) async {
    final auth = context.read<AuthCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cikis yapilsin mi?'),
        content: const Text('Hesabinizdan cikis yapacaksiniz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgec'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cikis Yap'),
          ),
        ],
      ),
    );
    if (ok == true) auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Hesap'),
        ListTile(
          leading: const Icon(Icons.password_outlined),
          title: const Text('Sifre Degistir'),
          onTap: () => _changePassword(context),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.danger),
          title: const Text('Cikis Yap',
              style: TextStyle(color: AppColors.danger)),
          onTap: () => _signOut(context),
        ),
      ],
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Yardim'),
        ListTile(
          leading: const Icon(Icons.replay_outlined),
          title: const Text('Turu tekrar gor'),
          onTap: () => context.push('/onboarding'),
        ),
      ],
    );
  }
}
