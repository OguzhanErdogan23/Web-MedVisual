import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import 'auth_cubit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().signUp(_email.text.trim(), _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayit Ol')),
      body: BlocListener<AuthCubit, AuthState>(
        listenWhen: (prev, curr) =>
            prev.error != curr.error || prev.info != curr.info,
        listener: (context, state) {
          if (state.error != null) {
            showSnack(context, state.error!, error: true);
          } else if (state.info != null) {
            showSnack(context, state.info!);
            context.go('/giris');
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.person_add_alt_1_outlined,
                        size: 48, color: AppColors.teal),
                    const SizedBox(height: 16),
                    Text(
                      'MedVisual hesabi olustur',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Gecerli bir e-posta girin'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Sifre',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Sifre en az 6 karakter olmali'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password2,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Sifre (tekrar)',
                        prefixIcon: Icon(Icons.lock_reset_outlined),
                      ),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) =>
                          v != _password.text ? 'Sifreler eslesmiyor' : null,
                    ),
                    const SizedBox(height: 22),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) => FilledButton(
                        onPressed: state.busy ? null : _submit,
                        child: state.busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Kayit Ol'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => context.go('/giris'),
                      child: const Text('Zaten hesabin var mi? Giris yap'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
